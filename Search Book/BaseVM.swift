//
//  BaseVM.swift
//  Search Book
//
//  Created by Petrus on 7/8/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

open class BaseVM<Intent, ViewState, SingleEvent> {
    private let _intentSubject = PublishSubject<Intent>()
    private let _stateSubject: BehaviorSubject<ViewState>
    private let _singleEventSubject = PublishSubject<SingleEvent>()
    
    internal var intent$: Observable<Intent> { return _intentSubject.asObservable() }
    internal let disposeBag = DisposeBag()
    
    // MARK: - Output stream
    let initialState: ViewState
    var state$: Observable<ViewState> { return _stateSubject }
    var event$: Observable<SingleEvent> { return _singleEventSubject }
    
    public init(initialState: ViewState) {
        self.initialState = initialState
        self._stateSubject = BehaviorSubject<ViewState>(value: initialState)
    }
    
    public func processIntent(_ intent$: Observable<Intent>) -> Disposable {
        return intent$.bind(to: self._intentSubject)
    }
    
    // MARK: - Methods
    internal func setNewState(_ viewState: ViewState) {
        _stateSubject.onNext(viewState)
    }
    
    internal func sendEvent(_ event: SingleEvent) {
        _singleEventSubject.onNext(event)
    }
    
    deinit {
        print("\(self) deinit")
    }
}
