//
//  HomeVM.swift
//  Search Book
//
//  Created by Petrus on 7/8/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt

class HomeVM: MviViewModelType {
    static let initialState = HomeViewState(
        searchTerm: "",
        items: [],
        books: [],
        favCount: 0
    )

    private let intentS = PublishRelay<HomeIntent>()
    private let singleEventS = PublishRelay<HomeSingleEvent>()
    private let viewStateS = BehaviorRelay<HomeViewState>(value: initialState)

    private let homeInteractor: HomeInteractor
    private let disposeBag = DisposeBag()

    let state$: Driver<HomeViewState>
    let singleEvent$: Signal<HomeSingleEvent>

    func process(intent$: Observable<HomeIntent>) -> Disposable {
        return intent$.bind(to: intentS)
    }

    init(homeInteractor: HomeInteractor) {
        self.homeInteractor = homeInteractor
        self.singleEvent$ = singleEventS.asSignal()
        self.state$ = viewStateS.asDriver()

        let searchString$: Observable<String> = intentS
            .filterMap { (intent: HomeIntent) -> FilterMap<String> in
                if case .search(let searchTerm) = intent {
                    return .map(searchTerm)
                } else {
                    return .ignore
                }
            }
            .debounce(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let shouldLoadNextPage = { (state: HomeViewState) -> Bool in
            return !state.books.isEmpty && state.items.allSatisfy { item in
                if case .book = item {
                    return true
                } else {
                    return false
                }
            }
        }

        let loadNextPage$ = intentS
            .filter { (intent: HomeIntent) -> Bool in
                if case .loadNextPage = intent {
                    return true
                } else {
                    return false
                }
            }
            .withLatestFrom(viewStateS)
            .filterMap { (state: HomeViewState) -> FilterMap<Int> in
                if shouldLoadNextPage(state) {
                    return .map(state.books.count)
                } else {
                    return .ignore
                }
            }
            .withLatestFrom(searchString$) { ($0, $1) }

        let shouldRetryFirstPage = { (state: HomeViewState) -> Bool in
            return state.books.isEmpty && state.items.contains(where: { item in
                if case .error(_, true) = item {
                    return true
                } else {
                    return false
                }
            })
        }

        let retryFirstPage$ = intentS
            .withLatestFrom(viewStateS, resultSelector: { ($0, $1) })
            .filter { (tuple) -> Bool in
                if case .retryLoadFirstPage = tuple.0 {
                    return shouldRetryFirstPage(tuple.1)
                } else {
                    return false
                }
            }
            .withLatestFrom(searchString$)

        let shouldRetryNextPage = { (state: HomeViewState) -> Bool in
            return !state.books.isEmpty && state.items.contains(where: { item in
                if case .error(_, false) = item {
                    return true
                } else {
                    return false
                }
            })
        }

        let retryNextPage$ = intentS
            .filter { (intent: HomeIntent) -> Bool in
                if case .retryLoadNextPage = intent {
                    return true
                } else {
                    return false
                }
            }
            .withLatestFrom(viewStateS)
            .filterMap { (state: HomeViewState) -> FilterMap<Int> in
                if shouldRetryNextPage(state) {
                    return .map(state.books.count)
                } else {
                    return .ignore
                }
            }
            .withLatestFrom(searchString$) { ($0, $1) }

        let changes = [
            Observable.merge([loadNextPage$, retryNextPage$]).flatMapFirst { tuple in
                homeInteractor
                    .loadNextPage(
                        query: tuple.1,
                        startIndex: tuple.0
                    )
                    .observeOn(MainScheduler.instance)
                    .do(onNext: { change in
                        if case .loadNextPageError(let error, _) = change {
                            self.singleEventS.accept(.loadError(error))
                        }
                    })
            },
            Observable.merge([searchString$, retryFirstPage$]).flatMapLatest { searchTerm in
                homeInteractor
                    .searchBook(query: searchTerm)
                    .observeOn(MainScheduler.instance)
                    .do(onNext: { change in
                        if case .loadFirstPageError(let error, _) = change {
                            self.singleEventS.accept(.loadError(error))
                        }
                    })
            }
        ]

        Observable.combineLatest(
            Observable.merge(changes)
                .startWith(.initial)
                .observeOn(MainScheduler.asyncInstance)
                .scan(HomeVM.initialState, accumulator: HomeVM.reducer)
                .distinctUntilChanged(),
            homeInteractor.favoritedIds()) { state, ids in
            var books = [HomeBook]()
            let items = state.items.map { (item: HomeItem) -> HomeItem in
                switch item {
                case .book(let book):
                    let copied = book.withFavorited(ids.contains(book.id))
                    books.append(copied)
                    return .book(copied)
                case .error, .loading:
                    return item
                }
            }
            return state.copyWith(
                items: items,
                books: books,
                favCount: ids.count
            )
        }
            .distinctUntilChanged()
            .bind(to: viewStateS)
            .disposed(by: disposeBag)

        intentS
            .filterMap { (intent: HomeIntent) -> FilterMap<HomeBook> in
                if case .toggleFavorite(let book) = intent {
                    return .map(book)
                } else {
                    return .ignore
                }
            }
            .groupBy { $0.id }
            .map { $0.throttle(0.5, scheduler: MainScheduler.instance) }
            .flatMap { $0 }
            .concatMap { homeInteractor.toggleFavorited(book: $0) }
            .subscribe(onNext: { self.singleEventS.accept($0) })
            .disposed(by: disposeBag)
    }

    static func reducer(vs: HomeViewState, change: HomePartialChange) -> HomeViewState {
        print("Reducer: \(change.name) \(Thread.current)")

        switch change {
        case .loadingFirstPage:
            return vs.copyWith(
                items: [.loading] + vs.books.map { .book($0) }
            )
        case .loadFirstPageError(let error, let searchTerm):
            return vs.copyWith(
                searchTerm: searchTerm,
                items: [.error(error, true)]
            )
        case .firstPageLoaded(let books, let searchTerm):
            return vs.copyWith(
                searchTerm: searchTerm,
                items: books.map { .book($0) },
                books: books
            )
        case .loadingNextPage:
            return vs.copyWith(
                items: vs.books.map { .book($0) }
                    + [.loading]
            )
        case .nextPageLoaded(let books, let searchTerm):
            let newBooks = vs.books + books
            return vs.copyWith(
                searchTerm: searchTerm,
                items: newBooks.map { .book($0) },
                books: newBooks
            )
        case .loadNextPageError(let error, let searchTerm):
            return vs.copyWith(
                searchTerm: searchTerm,
                items: vs.books.map { .book($0) }
                    + [.error(error, false)]
            )
        case .initial:
            return vs
        }
    }
}
