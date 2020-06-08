//
//  FavoritesContract.swift
//  Search Book
//
//  Created by Petrus on 9/12/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Intent
enum FavoritesIntent {
  case refresh
  case removeFavorite(FavoritesItem)
}

// MARK: - View state
struct FavoritesViewState: Equatable {
  let books: [FavoritesItem]?
  let isRefreshing: Bool

  func copyWith(books: [FavoritesItem], isRefreshing: Bool? = nil) -> FavoritesViewState {
    return .init(books: books, isRefreshing: isRefreshing ?? self.isRefreshing)
  }
}

struct FavoritesItem: Equatable {
  let isLoading: Bool
  let error: FavoritesError?

  let id: String
  let title: String?
  let subtitle: String?
  let thumbnail: String?

  func copyWith(
    isLoading: Bool? = nil,
    error: FavoritesError? = nil,
    title: String? = nil,
    subtitle: String? = nil,
    thumbnail: String? = nil
  ) -> FavoritesItem {
    return .init(
      isLoading: isLoading ?? self.isLoading,
      error: error,
      id: self.id,
      title: title ?? self.title,
      subtitle: subtitle ?? self.subtitle,
      thumbnail: thumbnail ?? self.thumbnail
    )
  }
}

extension FavoritesItem {
  init(fromDomain b: Book) {
    self.id = b.id
    self.title = b.title
    self.subtitle = b.subtitle
    self.thumbnail = b.thumbnail

    self.isLoading = false
    self.error = nil
  }

  func toDomain() -> Book {
    return Book(
      id: self.id,
      title: self.title,
      subtitle: self.subtitle,
      authors: nil,
      thumbnail: self.thumbnail,
      largeImage: nil,
      description: nil,
      publishedDate: nil
    )
  }
}

enum FavoritesError: Equatable {
  case networkError
  case serverResponseError(Int, String)
  case unexpectedError
}

extension FavoritesError {
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


// MARK: - Partial change
enum FavoritesPartialChange {
  case ids([String])

  case bookLoaded(FavoritesItem)
  case bookError(FavoritesError, String)

  case refreshing
  case refreshSuccess([FavoritesItem])
  case refreshError(FavoritesError)
}

// MARK: - Single event
enum FavoritesSingleEvent {
  case removedFromFavorites(FavoritesItem)
  case removeFromFavoritesError(FavoritesItem)
}

// MARK: - Interactor
protocol FavoritesInteractor {
  func favoritedIds() -> Observable<Set<String>>

  func getBooksBy(ids: Set<String>) -> Observable<FavoritesPartialChange>

  func refresh(ids: Set<String>) -> Observable<FavoritesPartialChange>

  func removeFavorite(item: FavoritesItem) -> Single<FavoritesSingleEvent>
}
