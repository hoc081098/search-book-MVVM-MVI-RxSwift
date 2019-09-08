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
        books: []
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
            .filterMap { (intent: HomeIntent) -> FilterMap<Void> in
                if case .loadNextPage = intent {
                    return .map(())
                } else {
                    return .ignore
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
            .filterMap { (tuple) -> FilterMap<Void> in
                if case .retryLoadFirstPage = tuple.0 {
                    return shouldRetryFirstPage(tuple.1) ? .map(()) : .ignore
                } else {
                    return .ignore
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
            .filterMap { (intent: HomeIntent) -> FilterMap<Void> in
                if case .retryLoadNextPage = intent {
                    return .map(())
                } else {
                    return .ignore
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
                homeInteractor.loadNextPage(
                    query: tuple.1,
                    startIndex: tuple.0
                )
            },
            Observable.merge([searchString$, retryFirstPage$]).flatMapLatest { searchTerm in
                homeInteractor.searchBook(query: searchTerm)
            }
        ]

        Observable.merge(changes)
            .observeOn(MainScheduler.asyncInstance)
            .scan(HomeVM.initialState, accumulator: HomeVM.reducer)
            .distinctUntilChanged()
            .bind(to: viewStateS)
            .disposed(by: disposeBag)
    }

    static func reducer(vs: HomeViewState, change: PartialChange) -> HomeViewState {
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
        }
    }
}
