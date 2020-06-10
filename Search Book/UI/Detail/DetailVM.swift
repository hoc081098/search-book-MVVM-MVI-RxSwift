//
//  DetailVM.swift
//  Search Book
//
//  Created by Petrus on 9/10/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

import Foundation
import RxSwift
import RxCocoa

class DetailVM: MviViewModelType {
  private let intentS = PublishRelay<DetailIntent>()
  private let singleEventS = PublishRelay<DetailSingleEvent>()
  private let viewStateS: BehaviorRelay<DetailViewState>

  private let detailInteractor: DetailInteractor
  private let disposeBag = DisposeBag()

  // MARK: - Implements `MviViewModelType`

  var state$: Driver<DetailViewState> { self.viewStateS.asDriver() }

  var singleEvent$: Signal<DetailSingleEvent> { self.singleEventS.asSignal() }

  func process(intent$: Observable<DetailIntent>) -> Disposable { intent$.bind(to: intentS) }

  // MARK: - Initializer

  init(detailInteractor: DetailInteractor) {
    self.detailInteractor = detailInteractor

    let initialState = DetailViewState(
      isLoading: true,
      isRefreshing: false,
      error: nil,
      detail: nil
    )
    self.viewStateS = .init(value: initialState)

    let initialChange$ = self.intentS
      .compactMap {
        if case .initial(let initialDetail) = $0 { return initialDetail }
        return nil
      }
      .take(1)
      .do(onNext: { _ in print("Initial intent") })
      .flatMap { [detailInteractor, singleEventS] in
        detailInteractor
          .getDetailBy(id: $0.id)
          .startWith(.initialLoaded($0))
          .do(onNext: { change in
            if case .detailError(let error) = change {
              singleEventS.accept(.getDetailError(error))
            }
          })
    }


    let refreshChange$ = self.intentS
      .filter { $0 == .refresh }
      .withLatestFrom(self.viewStateS)
      .compactMap { $0.detail?.id }
      .do(onNext: { _ in print("Refresh intent") })
      .flatMapFirst { [detailInteractor, singleEventS] in
        detailInteractor
          .refresh(id: $0)
          .do(
            onNext: { change in
              switch change {
              case .refreshError(let error):
                singleEventS.accept(.refreshError(error))
              case .refreshSuccess(_):
                singleEventS.accept(.refreshSuccess)
              default: ()
              }
            }
          )
    }


    Observable
      .combineLatest(
        Observable
          .merge([refreshChange$, initialChange$])
          .scan(initialState) { $1.reduce(state: $0) }
          .distinctUntilChanged(),
        self
          .detailInteractor
          .favoritedIds()
          .distinctUntilChanged()
      ) { $0.copyWith(favoritedIds: $1) }
      .observeOn(MainScheduler.asyncInstance)
      .distinctUntilChanged()
      .bind(to: self.viewStateS)
      .disposed(by: self.disposeBag)

    self
      .intentS
      .filter { $0 == .toggleFavorite }
      .withLatestFrom(self.viewStateS)
      .compactMap { $0.detail }
      .groupBy { $0.id }
      .flatMap { $0.throttle(.milliseconds(500), scheduler: MainScheduler.instance) }
      .concatMap { [detailInteractor] in detailInteractor.toggleFavorited(detail: $0) }
      .subscribe(onNext: { [singleEventS] in singleEventS.accept($0) })
      .disposed(by: self.disposeBag)
  }

  deinit {
    print("DetailVM::deinit")
  }
}
