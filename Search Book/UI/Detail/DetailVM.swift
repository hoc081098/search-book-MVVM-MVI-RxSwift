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
    static let initialState = DetailViewState(isLoading: true, error: nil, detail: .initial(id: ""))

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
    }

    static func reducer(vs: DetailViewState, change: DetailPartialChange) -> DetailViewState {
        fatalError()
    }
}
