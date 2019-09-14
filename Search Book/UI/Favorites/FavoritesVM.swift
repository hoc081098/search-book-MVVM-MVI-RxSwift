//
//  FavoritesVM.swift
//  Search Book
//
//  Created by Petrus on 9/14/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

import Foundation
import RxSwift
import RxCocoa

class FavoritesVM: MviViewModelType {
    static let initialState = FavoritesViewState(
        books: []
    )

    private let intentS = PublishRelay<FavoritesIntent>()
    private let singleEventS = PublishRelay<FavoritesSingleEvent>()
    private let viewStateS = BehaviorRelay<FavoritesViewState>(value: initialState)

    private let detailInteractor: FavoritesInteractor
    private let disposeBag = DisposeBag()

    let state$: Driver<FavoritesViewState>
    let singleEvent$: Signal<FavoritesSingleEvent>

    func process(intent$: Observable<FavoritesIntent>) -> Disposable {
        return intent$.bind(to: intentS)
    }

    init(detailInteractor: FavoritesInteractor) {
        self.detailInteractor = detailInteractor
        self.singleEvent$ = singleEventS.asSignal()
        self.state$ = viewStateS.asDriver()

        let booksChange$ = self.detailInteractor
            .favoritedIds()
            .flatMapLatest { ids in
                self.detailInteractor.getBooksBy(ids: ids)
        }

        let refreshChange$ = self.intentS
            .filter { intent in
                if case .refresh = intent { return true }
                else { return false }
            }
            .withLatestFrom(self.detailInteractor.favoritedIds())
            .flatMapFirst { ids in
                self.detailInteractor.refresh(ids: ids)
        }

        Observable.merge([booksChange$, refreshChange$])
            .scan(FavoritesVM.initialState, accumulator: FavoritesVM.reducer)
            .distinctUntilChanged()
            .bind(to: self.viewStateS)
            .disposed(by: self.disposeBag)
    }

    static func reducer(vs: FavoritesViewState, change: FavoritesPartialChange) -> FavoritesViewState {
        switch change {
        case .bookLoaded(let book):
            return vs.copyWith(books: replace(items: vs.books, by: book))
        case .bookError(let error):
            return vs.copyWith(books: replace(items: vs.books, by: error))
        case .refreshSuccess(let books):
            <#code#>
        case .refreshError(let error):
            <#code#>
        @unknown default:
            <#code#>
        }
    }

    static func replace(items: [FavoritesItem], by newItem: FavoritesBook) -> [FavoritesItem]{
        return items.map { item in
            if item.book?.id == newItem.id {
                return item.copyWith(isLoading: false, error: nil, book: newItem)
            } else {
                return item
            }
        }
    }
}

