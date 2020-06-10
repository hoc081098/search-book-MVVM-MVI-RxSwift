//
//  Observable+CatchError.swift
//  Search Book
//
//  Created by Petrus on 6/9/20.
//  Copyright © 2020 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType {
  func catchErrorResult<T>() -> Observable<DomainResult<T>> where Element == DomainResult<T> {
    self.catchError { .just($0.toDomainResult()) }
  }
}

extension PrimitiveSequence where Trait == SingleTrait {
  func catchErrorResult<T>() -> Single<DomainResult<T>> where Element == DomainResult<T> {
    self.catchError { .just($0.toDomainResult()) }
  }
}
