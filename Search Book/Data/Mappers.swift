//
// Created by Petrus Nguyễn Thái Học on 9/3/19.
// Copyright (c) 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

extension BookResponse {
  var toDomainBook: Book {
      .init(
        id: self.id,
        title: self.title,
        subtitle: self.subtitle,
        authors: self.authors,
        thumbnail: self.thumbnail,
        largeImage: self.largeImage,
        description: self.description,
        publishedDate: self.publishedDate
      )
  }
}


extension Error {
  var toDomainError: AppError {
    if let appError = self as? AppError {
      return appError
    }

    if (self as NSError).code == NSURLErrorNotConnectedToInternet {
      return .networkError(self)
    }

    if let apiError = self as? ApiErrorMessage {
      return .serverResponseError(
        status: apiError.code,
        message: apiError.message
      )
    }

    return .unexpectedError(self)
  }

  func toDomainResult<T>() -> DomainResult<T> { .failure(self.toDomainError) }
}
