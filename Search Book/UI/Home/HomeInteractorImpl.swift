//
//  HomeInteractorImpl.swift
//  Search Book
//
//  Created by Petrus Nguyễn Thái Học on 9/3/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

class HomeInteractorImpl: HomeInteractor {

  private let favoritedBooksRepository: FavoritedBooksRepository
  private let bookRepository: BookRepository

  init(bookRepository: BookRepository, favoritedBooksRepository: FavoritedBooksRepository) {
    self.bookRepository = bookRepository
    self.favoritedBooksRepository = favoritedBooksRepository
  }

  func searchBook(query: String) -> Observable<HomePartialChange> {
    self
      .bookRepository
      .searchBook(by: query, and: 0)
      .asObservable()
      .map { result -> HomePartialChange in
        result.fold(
          onSuccess: { domainBooks in
            let books = domainBooks.map(HomeBook.init(fromDomain:))
            return .firstPageLoaded(books: books, searchTerm: query)
          },
          onFailure: { .loadFirstPageError(error: $0, searchTerm: query) }
        )
      }
      .startWith(.loadingFirstPage)
  }

  func loadNextPage(query: String, startIndex: Int) -> Observable<HomePartialChange> {
    self.bookRepository
      .searchBook(by: query, and: startIndex)
      .asObservable()
      .map { result -> HomePartialChange in
        result.fold(
          onSuccess: { domainBooks in
            let books = domainBooks.map(HomeBook.init(fromDomain:))
            return .nextPageLoaded(books: books, searchTerm: query)
          },
          onFailure: { .loadNextPageError(error: $0, searchTerm: query) }
        )
      }
      .startWith(.loadingNextPage)
  }

  func toggleFavorited(book: HomeBook) -> Single<HomeSingleEvent> {
    self
      .favoritedBooksRepository
      .toggleFavorited(book: book.toDomain())
      .map { result -> HomeSingleEvent in
        result.fold(
          onSuccess: { toggleResult in
            toggleResult.added
              ? .addedToFavorited(book)
              : .removedFromFavorited(book)
          },
          onFailure: { .toggleFavoritedError($0, book) }
        )
    }
  }

  func favoritedIds() -> Observable<Set<String>> {
    self.favoritedBooksRepository.favoritedIds()
  }

  deinit {
    print("\(self)::deinit")
  }
}
