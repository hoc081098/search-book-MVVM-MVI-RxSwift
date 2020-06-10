//
//  Error.swift
//  Search Book
//
//  Created by Petrus Nguyễn Thái Học on 9/8/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

enum AppError: Error {
  case networkError(Error?)
  case serverResponseError(status: Int, message: String)
  case unexpectedError(Error?)

  var message: String {
    switch self {
    case .networkError:
      return "Network error"
    case .serverResponseError(_, let message):
      return "Response error: \(message)"
    case .unexpectedError(let cause):
      if let message = cause?.localizedDescription {
        return "Unexpected error: \(message)"
      }
      return "Unexpected error"
    }
  }
}

extension AppError: Equatable {
  static func == (lhs: AppError, rhs: AppError) -> Bool {
    if case .networkError(let error1 as NSError?) = lhs,
      case .networkError(let error2 as NSError?) = rhs {
      return error1 == error2
    }
    if case .serverResponseError(let status1, let message1) = lhs,
      case .serverResponseError(let status2, let message2) = rhs {
      return status1 == status2 && message1 == message2
    }
    if case .unexpectedError(let error1 as NSError?) = lhs,
      case .unexpectedError(let error2 as NSError?) = rhs {
      return error1 == error2
    }
    return false
  }
}

typealias DomainResult<T> = Swift.Result<T, AppError>
