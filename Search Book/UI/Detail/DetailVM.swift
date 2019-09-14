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
            .do(onNext: { _ in print("Initial intent") })
            .flatMap {
                detailInteractor.getDetailBy(id: $0.id)
                    .startWith(.initialLoaded($0))
                    .do(onNext: { change in
                        if case .detailError(let error) = change {
                            self.singleEventS.accept(.getDetailError(error))
                        }
                    })
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
            .do(onNext: { _ in print("Refresh intent") })
            .flatMapFirst {
                detailInteractor
                    .refresh(id: $0)
                    .do(onNext: { change in
                        switch change {
                        case .refreshError(let error):
                            self.singleEventS.accept(.refreshError(error))
                        case .refreshSuccess(_):
                            self.singleEventS.accept(.refreshSuccess)
                        default: ()
                        }
                    })
        }

        let scannedState$ = Observable.merge([refreshChange$, initialChange$])
            .scan(DetailVM.initialState, accumulator: DetailVM.reducer)
            .distinctUntilChanged()

        Observable
            .combineLatest(
                scannedState$,
                self.detailInteractor.favoritedIds()) { state, ids -> DetailViewState in
                if let detail = state.detail {
                    return state.copyWith(detail: detail.withFavorited(ids.contains(detail.id)))
                } else {
                    return state
                }
            }
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .bind(to: self.viewStateS)
            .disposed(by: self.disposeBag)

        self
            .intentS
            .filter { (intent: DetailIntent) -> Bool in
                if case .toggleFavorite = intent {
                    return true
                } else {
                    return false
                }
            }
            .withLatestFrom(self.viewStateS)
            .filterMap { (state: DetailViewState) -> FilterMap<BookDetail> in
                if let detail = state.detail {
                    return .map(detail)
                } else {
                    return .ignore
                }
            }
            .groupBy { $0.id }
            .map { $0.throttle(.milliseconds(500), scheduler: MainScheduler.instance) }
            .flatMap { $0 }
            .concatMap { self.detailInteractor.toggleFavorited(detail: $0) }
            .subscribe(onNext: { self.singleEventS.accept($0) })
            .disposed(by: disposeBag)
    }

    static func reducer(vs: DetailViewState, change: DetailPartialChange) -> DetailViewState {
        print("Change=\(change.name)")

        switch change {
        case .refreshing:
            return vs.copyWith(isRefreshing: true)
        case .refreshError:
            return vs.copyWith(isRefreshing: false)
        case .initialLoaded(let initial):
            return vs.copyWith(
                isLoading: false,
                error: nil,
                detail: vs.detail ?? .init(fromInitial: initial)
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
        case .refreshSuccess(let detail):
            return vs.copyWith(
                isRefreshing: false,
                detail: detail
            )
        }
    }
}
