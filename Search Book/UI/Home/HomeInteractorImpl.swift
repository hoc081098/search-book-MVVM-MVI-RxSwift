//
//  HomeInteractorImpl.swift
//  Search Book
//
//  Created by HOANG TAN DUY on 9/3/19.
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
    print("Search \(query)")
    return self.bookRepository
      .searchBook(query: query, startIndex: 0)
      .do(onSuccess: { _ in print("Search \(Thread.current)") })
      .asObservable()
      .map { books in books.map { book in HomeBook(fromDomain: book) } }
      .map { books in .firstPageLoaded(books: books, searchTerm: query) }
      .startWith(.loadingFirstPage)
      .catchError { (error: Error) -> Observable<HomePartialChange> in
          .just(.loadFirstPageError(error: .init(from: error), searchTerm: query))
    }
  }

  func loadNextPage(query: String, startIndex: Int) -> Observable<HomePartialChange> {
    print("Load next page \(query), \(startIndex)")
    return self.bookRepository
      .searchBook(query: query, startIndex: startIndex)
      .do(onSuccess: { _ in print("Search \(Thread.current)") })
      .asObservable()
      .map { books in books.map { book in HomeBook(fromDomain: book) } }
      .map { books in .nextPageLoaded(books: books, searchTerm: query) }
      .startWith(.loadingNextPage)
      .catchError { (error: Error) -> Observable<HomePartialChange> in
          .just(.loadNextPageError(error: .init(from: error), searchTerm: query))

    }
  }

  func toggleFavorited(book: HomeBook) -> Single<HomeSingleEvent> {
    return self
      .favoritedBooksRepository
      .toggleFavorited(book: book.toDomain())
      .map { result -> HomeSingleEvent in
        result.fold(
          onSuccess: { toggleResult in
            toggleResult.added
              ? .addedToFavorited(book)
              : .removedFromFavorited(book)
          },
          onFailure: { error in .toggleFavoritedError(.init(from: error), book) }
        )
    }
  }

  func favoritedIds() -> Observable<Set<String>> {
    return favoritedBooksRepository.favoritedIds()
  }
}
