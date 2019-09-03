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
        books: [],
        isFirstPageLoading: false,
        firstPageError: nil,
        isNextPageLoading: false,
        nextPageError: nil
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
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }


        searchString$
            .flatMapLatest { searchTerm in
                homeInteractor.searchBook(query: searchTerm)
            }
            .scan(HomeVM.initialState, accumulator: { (vs: HomeViewState, change: PartialChange) -> HomeViewState in
                switch change {
                case .loadingFirstPage:
                    return vs.copyWith(isFirstPageLoading: true)
                case .loadFirstPageError(let error, let searchTerm):
                    return vs.copyWith(
                        searchTerm: searchTerm,
                        isFirstPageLoading: false,
                        firstPageError: error
                    )
                case .firstPageLoaded(let books, let searchTerm):
                    return vs.copyWith(
                        searchTerm: searchTerm,
                        books: books,
                        isFirstPageLoading: false
                    )
                case .loadingNextPage:
                    return vs
                case .nextPageLoaded(let books, let searchTerm):
                    return vs
                case .loadNextPageError(let error, let searchTerm):
                    return vs
                }
            })
            .bind(to: viewStateS)
    }
}
