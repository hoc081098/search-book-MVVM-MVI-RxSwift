//
//  BaseVM.swift
//  Search Book
//
//  Created by Petrus on 7/8/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

open class BaseVM<Intent, ViewState, SingleEvent> {
    private let _stateSubject: BehaviorSubject<ViewState>
    private let _singleEventSubject = PublishSubject<SingleEvent>()
    
    let initialState: ViewState
    var state$: Observable<ViewState> { return _stateSubject }
    var event$: Observable<SingleEvent> { return _singleEventSubject }
    
    init(initialState: ViewState) {
        self.initialState = initialState
        self._stateSubject = BehaviorSubject<ViewState>(value: initialState)
    }
    
    internal func setNewState(viewState: ViewState) {
        _stateSubject.onNext(viewState)
    }
    
    internal func sendEven(event: SingleEvent) {
        _singleEventSubject.onNext(event)
    }
    
}
