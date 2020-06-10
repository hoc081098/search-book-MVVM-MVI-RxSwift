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
  private let intentS = PublishRelay<FavoritesIntent>()
  private let singleEventS = PublishRelay<FavoritesSingleEvent>()
  private let viewStateS: BehaviorRelay<FavoritesViewState>

  private let detailInteractor: FavoritesInteractor
  private let disposeBag = DisposeBag()

  // MARK: - Implements `MviViewModelType`

  var state$: Driver<FavoritesViewState> { self.viewStateS.asDriver() }

  var singleEvent$: Signal<FavoritesSingleEvent> { self.singleEventS.asSignal() }

  func process(intent$: Observable<FavoritesIntent>) -> Disposable { intent$.bind(to: intentS) }

  // MARK: - Initializer

  init(detailInteractor: FavoritesInteractor) {
    self.detailInteractor = detailInteractor

    let initialState = FavoritesViewState(
      books: nil,
      isRefreshing: false
    )
    self.viewStateS = .init(value: initialState)

    let booksChange$ = self.detailInteractor
      .favoritedIds()
      .flatMapLatest { [detailInteractor] in detailInteractor.getBooksBy(ids: $0) }

    let refreshChange$ = self.intentS
      .filter { $0 == .refresh }
      .withLatestFrom(self.detailInteractor.favoritedIds())
      .flatMapFirst { [detailInteractor] in detailInteractor.refresh(ids: $0) }

    Observable.merge([booksChange$, refreshChange$])
      .scan(initialState) { $1.reduce(state: $0) }
      .distinctUntilChanged()
      .bind(to: self.viewStateS)
      .disposed(by: self.disposeBag)

    self.intentS
      .compactMap {
        if case .removeFavorite(let item) = $0 { return item }
        return nil
      }
      .concatMap { [detailInteractor] in detailInteractor.removeFavorite(item: $0) }
      .subscribe(onNext: { [singleEventS] in singleEventS.accept($0) })
      .disposed(by: self.disposeBag)
  }

  deinit {
    print("FavoritesVM::deinit")
  }
}

