//
//  FavoritesInteractorImpl.swift
//  Search Book
//
//  Created by Petrus on 9/14/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

class FavoritesInteractorImpl: FavoritesInteractor {
  private let favBooksRepo: FavoritedBooksRepository
  private let booksRepo: BookRepository

  init(favBooksRepo: FavoritedBooksRepository, booksRepo: BookRepository) {
    self.favBooksRepo = favBooksRepo
    self.booksRepo = booksRepo
  }

  func favoritedIds() -> Observable<[String]> {
    self.favBooksRepo.favoritedIds().map { $0.sorted() }
  }

  func getBooksBy(ids: [String]) -> Observable<FavoritesPartialChange> {
    Observable.from(ids)
      .flatMap { [booksRepo] id -> Observable<FavoritesPartialChange> in
        booksRepo
          .getBook(by: id, with: .localFirst)
          .map { result in
            result.fold(
              onSuccess: { .bookLoaded(.init(fromDomain: $0)) },
              onFailure: { .bookError($0, id) }
            )
        }
      }
      .startWith(.ids(Array(ids)))
  }

  func refresh(ids: [String]) -> Observable<FavoritesPartialChange> {
    let books$: [Observable<FavoritesItem>] = ids.map { [booksRepo] id in
      booksRepo
        .getBook(by: id, with: .networkOnly)
        .map { FavoritesItem.init(fromDomain: try $0.get()) }
        .takeLast(1)
    }
    return Observable
      .zip(books$) { books in FavoritesPartialChange.refreshSuccess(books) }
      .startWith(.refreshing)
      .catchError { .just(.refreshError($0.toDomainError)) }
  }

  func removeFavorite(item: FavoritesItem) -> Single<FavoritesSingleEvent> {
    self.favBooksRepo
      .toggleFavorited(book: item.toDomain())
      .map { result -> FavoritesSingleEvent in
        result.fold(
          onSuccess: {
            $0.added
              ? .removeFromFavoritesError(item)
              : .removedFromFavorites(item)
          },
          onFailure: { _ in .removeFromFavoritesError(item) }
        )
    }
  }

  deinit {
    print("\(self)::deinit")
  }
}
