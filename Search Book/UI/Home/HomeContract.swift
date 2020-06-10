//
//  HomeContract.swift
//  Search Book
//
//  Created by Petrus on 7/9/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Intent
enum HomeIntent: Equatable {
  case search(searchTerm: String)
  case retryLoadFirstPage
  case loadNextPage
  case retryLoadNextPage
  case toggleFavorite(book: HomeBook)
}

// MARK: - ViewState
struct HomeViewState: Equatable {
  let searchTerm: String
  let items: [HomeItem]
  let books: [HomeBook]
  let favCount: Int

  func copyWith(
    searchTerm: String? = nil,
    items: [HomeItem]? = nil,
    books: [HomeBook]? = nil,
    favCount: Int? = nil
  ) -> HomeViewState {
      .init(
        searchTerm: searchTerm ?? self.searchTerm,
        items: items ?? self.items,
        books: books ?? self.books,
        favCount: favCount ?? self.favCount
      )
  }

  func copyWith(favoritedIds ids: Set<String>) -> HomeViewState {
    var books = [HomeBook]()

    let items = self.items.map { item -> HomeItem in
      switch item {
      case .book(let book):
        let copied = book.withFavorited(ids.contains(book.id))
        books.append(copied)
        return .book(copied)
      case .error, .loading:
        return item
      }
    }

    return self.copyWith(
      items: items,
      books: books,
      favCount: ids.count
    )
  }
}

extension HomeViewState {
  var shouldLoadNextPage: Bool {
    !self.books.isEmpty && self.items.allSatisfy { item in
      if case .book = item { return true }
      return false
    }
  }

  var shouldRetryFirstPage: Bool {
    self.books.isEmpty && self.items.contains(where: { item in
      if case .error(_, true) = item { return true }
      return false
    })
  }

  var shouldRetryNextPage: Bool {
    !self.books.isEmpty && self.items.contains(where: { item in
      if case .error(_, false) = item { return true }
      return false
    })
  }
}

enum HomeItem: Equatable {
  case loading
  case error(AppError, firstPage: Bool)
  case book(HomeBook)
}

struct HomeBook: Equatable {
  let id: String
  let title: String?
  let subtitle: String?
  let thumbnail: String?
  let isFavorited: Bool?
}

extension HomeBook {
  init(fromDomain domain: Book) {
    id = domain.id
    title = domain.title
    subtitle = domain.subtitle
    thumbnail = domain.thumbnail
    isFavorited = nil
  }

  func toDomain() -> Book {
      .init(
        id: id,
        title: title,
        subtitle: subtitle,
        authors: nil,
        thumbnail: thumbnail,
        largeImage: nil,
        description: nil,
        publishedDate: nil
      )
  }

  func withFavorited(_ favorited: Bool) -> HomeBook {
      .init(
        id: self.id,
        title: self.title,
        subtitle: self.subtitle,
        thumbnail: self.thumbnail,
        isFavorited: favorited
      )
  }
}

// MARK: - Event
enum HomeSingleEvent {
  case addedToFavorited(HomeBook)
  case removedFromFavorited(HomeBook)
  case toggleFavoritedError(AppError, HomeBook)
  case loadError(AppError)
}

// MARK: - Partial Change
enum HomePartialChange {
  case initial

  case loadingFirstPage
  case loadFirstPageError(error: AppError, searchTerm: String)
  case firstPageLoaded(books: [HomeBook], searchTerm: String)

  case loadingNextPage
  case nextPageLoaded(books: [HomeBook], searchTerm: String)
  case loadNextPageError(error: AppError, searchTerm: String)
}

extension HomePartialChange: CustomStringConvertible {
  var description: String {
    switch self {
    case .loadingFirstPage:
      return "loadingFirstPage"
    case .loadFirstPageError:
      return "loadFirstPageError"
    case .firstPageLoaded:
      return "firstPageLoaded"
    case .loadingNextPage:
      return "loadingNextPage"
    case .nextPageLoaded:
      return "nextPageLoaded"
    case .loadNextPageError:
      return "loadNextPageError"
    case .initial:
      return "initial"
    }
  }
}

extension HomePartialChange {
  func reduce(state vs: HomeViewState) -> HomeViewState {
    print("HomePartialChange::reduce change=\(self)")

    switch self {
    case .loadingFirstPage:
      return vs.copyWith(
        items: CollectionOfOne(.loading) + vs.books.map { .book($0) }
      )
    case .loadFirstPageError(let error, let searchTerm):
      return vs.copyWith(
        searchTerm: searchTerm,
        items: [.error(error, firstPage: true)]
      )
    case .firstPageLoaded(let books, let searchTerm):
      return vs.copyWith(
        searchTerm: searchTerm,
        items: books.map { .book($0) },
        books: books
      )
    case .loadingNextPage:
      return vs.copyWith(
        items: vs.books.map { .book($0) } + CollectionOfOne(.loading)
      )
    case .nextPageLoaded(let books, let searchTerm):
      let newBooks = vs.books + books
      return vs.copyWith(
        searchTerm: searchTerm,
        items: newBooks.map { .book($0) },
        books: newBooks
      )
    case .loadNextPageError(let error, let searchTerm):
      return vs.copyWith(
        searchTerm: searchTerm,
        items: vs.books.map { .book($0) } + CollectionOfOne(.error(error, firstPage: false))
      )
    case .initial:
      return vs
    }
  }
}

// MARK: - Interactor
protocol HomeInteractor {
  func searchBook(query: String) -> Observable<HomePartialChange>

  func loadNextPage(query: String, startIndex: Int) -> Observable<HomePartialChange>

  func toggleFavorited(book: HomeBook) -> Single<HomeSingleEvent>

  func favoritedIds() -> Observable<Set<String>>
}
