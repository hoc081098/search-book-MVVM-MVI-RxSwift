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
import RxSwiftExt

class DetailVM: MviViewModelType {
    static let initialState = DetailViewState(
        isLoading: true,
        isRefreshing: false,
        error: nil,
        detail: nil
    )

    private let intentS = PublishRelay<DetailIntent>()
    private let singleEventS = PublishRelay<DetailSingleEvent>()
    private let viewStateS = BehaviorRelay<DetailViewState>(value: initialState)

    private let detailInteractor: DetailInteractor
    private let disposeBag = DisposeBag()

    let state$: Driver<DetailViewState>
    let singleEvent$: Signal<DetailSingleEvent>

    func process(intent$: Observable<DetailIntent>) -> Disposable {
        return intent$.bind(to: intentS)
    }

    init(detailInteractor: DetailInteractor) {
        self.detailInteractor = detailInteractor
        self.singleEvent$ = singleEventS.asSignal()
        self.state$ = viewStateS.asDriver()

        let initialChange$ = self.intentS
            .filterMap { (intent) -> FilterMap<InitialBookDetail> in
                if case .initial(let initialDetail) = intent {
                    return .map(initialDetail)
                } else {
                    return .ignore
                }
            }
            .take(1)
            .flatMap {
                detailInteractor.getDetailBy(id: $0.id)
                    .startWith(.initialLoaded($0))
        }

        let refreshChange$ = self.intentS
            .filter { intent in
                if case .refresh = intent {
                    return true
                } else {
                    return false
                }
            }
            .withLatestFrom(self.viewStateS)
            .filterMap { (state) -> FilterMap<String> in
                if let id = state.detail?.id {
                    return .map(id)
                } else {
                    return .ignore
                }
            }
            .flatMapFirst {
                detailInteractor.refresh(id: $0)
        }

        Observable.merge([refreshChange$, initialChange$])
            .scan(DetailVM.initialState, accumulator: DetailVM.reducer)
            .distinctUntilChanged()
            .bind(to: self.viewStateS)
            .disposed(by: self.disposeBag)
    }

    static func reducer(vs: DetailViewState, change: DetailPartialChange) -> DetailViewState {
        switch change {
        case .refreshing:
            return vs.copyWith(isRefreshing: true)
        case .refreshError:
            return vs.copyWith(isRefreshing: false)
        case .initialLoaded(let initial):
            return vs.copyWith(
                isLoading: false,
                error: nil,
                detail: .init(fromInitial: initial)
            )
        case .detailLoaded(let detail):
            return vs.copyWith(
                isLoading: false,
                error: nil,
                detail: detail
            )
        case .loading:
            return vs.copyWith(isLoading: true)
        case .detailError(let error):
            return vs.copyWith(
                isLoading: false,
                error: error
            )
        }
    }
}
