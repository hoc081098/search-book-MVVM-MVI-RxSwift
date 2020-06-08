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
enum HomeIntent {
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
    return HomeViewState(
      searchTerm: searchTerm ?? self.searchTerm,
      items: items ?? self.items,
      books: books ?? self.books,
      favCount: favCount ?? self.favCount
    )
  }
}

enum HomeError: Equatable {
  case networkError
  case serverResponseError(Int, String)
  case unexpectedError

  var message: String {
    switch self {
    case .networkError:
      return "Network error"
    case .serverResponseError(_, let message):
      return "Server response error: \(message)"
    case .unexpectedError:
      return "An unexpected error"
    }
  }
}

extension HomeError {
  init(from error: Error) {
    if let appError = error as? AppError {
      switch appError {
      case .networkError:
        self = .networkError
      case .serverResponseError(let code, let message):
        self = .serverResponseError(code, message)
      case .unexpectedError:
        self = .unexpectedError
      }
    } else {
      self = .unexpectedError
    }
  }
}

enum HomeItem: Equatable {
  case loading
  case error(HomeError, Bool)
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
    return Book(
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
    return HomeBook(
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
  case toggleFavoritedError(HomeError, HomeBook)
  case loadError(HomeError)
}

// MARK: - Partial Change
enum HomePartialChange {
  case initial

  case loadingFirstPage
  case loadFirstPageError(error: HomeError, searchTerm: String)
  case firstPageLoaded(books: [HomeBook], searchTerm: String)

  case loadingNextPage
  case nextPageLoaded(books: [HomeBook], searchTerm: String)
  case loadNextPageError(error: HomeError, searchTerm: String)

  var name: String {
    get {
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
}

// MARK: - Interactor
protocol HomeInteractor {
  func searchBook(query: String) -> Observable<HomePartialChange>
  func loadNextPage(query: String, startIndex: Int) -> Observable<HomePartialChange>
  func toggleFavorited(book: HomeBook) -> Single<HomeSingleEvent>
  func favoritedIds() -> Observable<Set<String>>
}
