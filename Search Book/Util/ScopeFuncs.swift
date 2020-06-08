//
//  ScopeFuncs.swift
//  Search Book
//
//  Created by HOANG TAN DUY on 9/9/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

protocol ScopeFunc { }

extension ScopeFunc {
  @inline(__always) func apply(block: (Self) -> ()) -> Self {
    block(self)
    return self
  }

  @inline(__always) func letIt<R>(block: (Self) -> R) -> R {
    return block(self)
  }
}

extension NSObject: ScopeFunc { }
