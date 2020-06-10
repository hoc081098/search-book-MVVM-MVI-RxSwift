//
//  Result+Fold+Bimap.swift
//  Search Book
//
//  Created by Petrus on 6/9/20.
//  Copyright © 2020 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

// MARK: - Result + fold
extension Swift.Result {
  func fold<R>(onSuccess: (Success) -> R, onFailure: (Failure) -> R) -> R {
    switch self {
    case .success(let value):
      return onSuccess(value)
    case .failure(let error):
      return onFailure(error)
    }
  }
}


// MARK: - Result + bimap
extension Swift.Result {
  func bimap<NewSuccess, NewFailure>(
    onSuccess: (Success) -> NewSuccess,
    onFailure: (Failure) -> NewFailure
  ) -> Result<NewSuccess, NewFailure> {
    map(onSuccess).mapError(onFailure)
  }
}
