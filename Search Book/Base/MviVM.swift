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

protocol MviViewModelType {
  associatedtype ViewState
  associatedtype ViewIntent
  associatedtype SingleEvent

  var state$: Driver<ViewState> { get }

  var singleEvent$: Signal<SingleEvent> { get }

  func process(intent$: Observable<ViewIntent>) -> Disposable
}
