//
// Created by Petrus Nguyễn Thái Học on 9/3/19.
// Copyright (c) 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

class BookRepositoryImpl: BookRepository {
  private static let timeoutInSeconds: TimeInterval = 60 * 5 // 5 minutes

  private let bookApi: BookApi
  private var cached = [String: (book: Book, date: Date)]()

  init(bookApi: BookApi) {
    self.bookApi = bookApi
  }

  // MARK: - Implements BookRepository

  func searchBook(by query: String, and startIndex: Int) -> Single<DomainResult<[Book]>> {
    self.bookApi
      .searchBook(by: query, and: startIndex)
      .map { apiResult in
        apiResult.bimap(
          onSuccess: { response in response.books.map { $0.toDomainBook } },
          onFailure: { $0.toDomainError }
        )
      }
      .catchErrorResult()
  }

  func getBook(by id: String, with cachePolicy: CachePolicy) -> Observable<DomainResult<Book>> {
    Single
      .deferred { [weak self] () -> Single<(shouldFetch: Bool, localBook: Book?)> in
        switch cachePolicy {
        case .networkOnly:
          return .just((true, self?.cached[id]?.book))
        case .localFirst:
          guard let (book, date) = self?.cached[id] else {
            return .just((true, nil))
          }

          if Date().timeIntervalSince1970 - date.timeIntervalSince1970 >= Self.timeoutInSeconds {
            return .just((true, book))
          }

          return .just((false, book))
        }
      }
      .subscribeOn(ConcurrentMainScheduler.instance)
      .asObservable()
      .flatMap { [weak self] tuple -> Observable<DomainResult<Book>> in
        let (shouldFetch, localBook) = tuple

        if let self = self, shouldFetch {
          return self.getBookNetwork(id)
            .asObservable()
            .startWithOptional(localBook.map { .success($0) })
        }

        return Observable
          .justOptional(localBook)
          .map { .success($0) }
    }
  }

  // MARK: - Private helpers

  private func getBookNetwork(_ id: String) -> Single<DomainResult<Book>> {
    self.bookApi
      .getBookDetail(by: id)
      .map { apiResult in
        apiResult.bimap(
          onSuccess: { $0.toDomainBook },
          onFailure: { $0.toDomainError }
        )
      }
      .observeOn(MainScheduler.instance)
      .do(onSuccess: { [weak self] in
        if case .success(let book) = $0 {
          self?.cached[id] = (book, Date())
        }
      })
      .catchErrorResult()
  }
}

private extension Observable {
  static func justOptional(_ value: Element?) -> Observable<Element> {
    if let value = value { return .just(value) }
    return .empty()
  }

  func startWithOptional(_ value: Element?) -> Observable<Element> {
    if let value = value { return startWith(value) }
    return self
  }
}
