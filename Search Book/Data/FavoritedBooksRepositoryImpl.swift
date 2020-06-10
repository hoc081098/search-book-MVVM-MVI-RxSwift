//
//  FavoritedBooksRepositoryImpl.swift
//  Search Book
//
//  Created by Petrus Nguyễn Thái Học on 9/9/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

private extension String {
  static let favIdsKey = "fav_ids"
}

class FavoritedBooksRepositoryImpl: FavoritedBooksRepository {
  private let userDefaults: UserDefaults

  private lazy var favoritedIds$ = self.userDefaults.rx
    .observe([String].self, .favIdsKey)
    .distinctUntilChanged()
    .map { ids in Set(ids ?? []) }
    .share(replay: 1, scope: .whileConnected)

  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults
  }

  func toggleFavorited(book: Book) -> Single<DomainResult<ToggleFavoritedResult>> {
    Single
      .deferred {
        let ids = self.userDefaults.stringArray(forKey: .favIdsKey) ?? []
        let bookId = book.id
        let contains = ids.contains(bookId)

        self.userDefaults.set(
          contains
            ? ids.filter { $0 != bookId }
            : ids + CollectionOfOne(bookId),
          forKey: .favIdsKey
        )

        return .just(.success(.init(added: !contains, book: book)))
      }
      .subscribeOn(ConcurrentMainScheduler.instance)
  }

  func favoritedIds() -> Observable<Set<String>> { favoritedIds$ }
}
