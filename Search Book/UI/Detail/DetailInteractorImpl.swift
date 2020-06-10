//
//  DetailInteractorImpl.swift
//  Search Book
//
//  Created by Petrus on 9/11/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

class DetailInteractorImpl: DetailInteractor {
  private let bookRepository: BookRepository
  private let favBookRepo: FavoritedBooksRepository

  init(bookRepository: BookRepository, favBookRepo: FavoritedBooksRepository) {
    self.bookRepository = bookRepository
    self.favBookRepo = favBookRepo
  }

  func refresh(id: String) -> Observable<DetailPartialChange> {
    bookRepository
      .getBook(by: id, with: .localFirst)
      .delay(.milliseconds(1_500), scheduler: MainScheduler.instance)
      .map { result in
        result.fold(
          onSuccess: { .refreshSuccess(.init(fromDomain: $0)) },
          onFailure: { .refreshError($0) }
        )
      }
      .startWith(.refreshing)
  }

  func getDetailBy(id: String) -> Observable<DetailPartialChange> {
    bookRepository
      .getBook(by: id, with: .networkOnly)
      .map { result in
        result.fold(
          onSuccess: { .detailLoaded(.init(fromDomain: $0)) },
          onFailure: { .detailError($0) }
        )
      }
      .startWith(.loading)

  }

  func favoritedIds() -> Observable<Set<String>> {
    self.favBookRepo.favoritedIds()
  }

  func toggleFavorited(detail: BookDetail) -> Single<DetailSingleEvent> {
    let book = detail.toDomain()

    return self.favBookRepo
      .toggleFavorited(book: book)
      .map { result -> DetailSingleEvent in
        result.fold(
          onSuccess: {
            $0.added
              ? .addedToFavorited(detail)
              : .removedFromFavorited(detail)
          },
          onFailure: { .toggleFavoritedError($0, detail) }
        )
    }
  }

  deinit {
    print("\(self)::deinit")
  }
}
