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
        books: nil
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
            .flatMapLatest { [detailInteractor] ids in
                detailInteractor.getBooksBy(ids: ids)
            }

        let refreshChange$ = self.intentS
            .filter { intent in
                if case .refresh = intent { return true }
                else { return false }
            }
            .withLatestFrom(self.detailInteractor.favoritedIds())
            .flatMapFirst { [detailInteractor] ids in
                detailInteractor.refresh(ids: ids)
            }

        Observable.merge([booksChange$, refreshChange$])
            .scan(FavoritesVM.initialState, accumulator: FavoritesVM.reducer)
            .distinctUntilChanged()
            .bind(to: self.viewStateS)
            .disposed(by: self.disposeBag)
    }

    deinit {
        print("FavoritesVM::deinit")
    }
    
    static func reducer(vs: FavoritesViewState, change: FavoritesPartialChange) -> FavoritesViewState {
        print(change)
        switch change {
        case .bookLoaded(let book):
            return vs.copyWith(books: replace(items: vs.books!, by: book))
        case .bookError(let error, let id):
            let books = vs.books!.map { book -> FavoritesItem in
                if book.id == id {
                    if book.isLoading {
                        return book.copyWith(
                            isLoading: false,
                            error: error
                        )
                    } else {
                        return book
                    }
                } else {
                    return book
                }
            }
            return vs.copyWith(books: books)
        case .refreshSuccess(let books):
            return vs.copyWith(books: books)
        case .refreshError(let error):
            return vs
        case .ids(let ids):
            return vs.copyWith(books: vs.books ??
                ids.map { id in
                    FavoritesItem.init(
                        isLoading: true,
                        error: nil,
                        id: id,
                        title: nil,
                        subtitle: nil,
                        thumbnail: nil)
                })
        }
    }

    static func replace(items: [FavoritesItem], by newItem: FavoritesItem) -> [FavoritesItem] {
        return items.map { item in
            if item.id == newItem.id {
                return item.copyWith(
                    isLoading: false,
                    error: nil,
                    title: newItem.title,
                    subtitle: newItem.subtitle,
                    thumbnail: newItem.thumbnail
                )
            } else {
                return item
            }
        }
    }
}

