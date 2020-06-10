//
//  FavoritesContract.swift
//  Search Book
//
//  Created by Petrus on 9/12/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift
import RxDataSources

// MARK: - Intent
enum FavoritesIntent: Equatable {
  case refresh
  case removeFavorite(FavoritesItem)
}

// MARK: - View state
struct FavoritesViewState: Equatable {
  let books: [FavoritesItem]?
  let isRefreshing: Bool

  func copyWith(
    books: [FavoritesItem],
    isRefreshing: Bool? = nil
  ) -> FavoritesViewState {
      .init(
        books: books,
        isRefreshing: isRefreshing ?? self.isRefreshing
      )
  }
}

struct FavoritesItem: Equatable {
  let isLoading: Bool
  let error: AppError?

  let id: String
  let title: String?
  let subtitle: String?
  let thumbnail: String?

  func copyWith(
    isLoading: Bool? = nil,
    error: AppError? = nil,
    title: String? = nil,
    subtitle: String? = nil,
    thumbnail: String? = nil
  ) -> FavoritesItem {
      .init(
        isLoading: isLoading ?? self.isLoading,
        error: error,
        id: self.id,
        title: title ?? self.title,
        subtitle: subtitle ?? self.subtitle,
        thumbnail: thumbnail ?? self.thumbnail
      )
  }
}

extension FavoritesItem: IdentifiableType {
  var identity: String { self.id }
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
    Book(
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

// MARK: - Partial change
enum FavoritesPartialChange {
  case ids([String])

  case bookLoaded(FavoritesItem)
  case bookError(AppError, String)

  case refreshing
  case refreshSuccess([FavoritesItem])
  case refreshError(AppError)
}

extension FavoritesPartialChange: CustomStringConvertible {
  var description: String {
    switch self {
    case .ids:
      return "ids"
    case .bookLoaded:
      return "bookLoaded"
    case .bookError:
      return "bookError"
    case .refreshing:
      return "refreshing"
    case .refreshSuccess:
      return "refreshSuccess"
    case .refreshError:
      return "refreshError"
    }
  }
}

extension FavoritesPartialChange {
  func reduce(state vs: FavoritesViewState) -> FavoritesViewState {
    print("FavoritesPartialChange::reduce change=\(self)")

    switch self {
    case .bookLoaded(let book):
      return vs.copyWith(books: Self.replace(items: vs.books ?? [], by: book))
    case .bookError(let error, let id):
      let books = vs.books!.map { book -> FavoritesItem in
        if book.id == id {
          if book.isLoading {
            return book.copyWith(
              isLoading: false,
              error: error
            )
          } else {
            return book
          }
        } else {
          return book
        }
      }
      return vs.copyWith(books: books)
    case .refreshSuccess(let books):
      return vs.copyWith(books: books, isRefreshing: false)
    case .refreshError(_):
      return vs.copyWith(books: vs.books ?? [], isRefreshing: false)
    case .ids(let ids):
      let books = Dictionary.init(uniqueKeysWithValues: vs.books?.map { ($0.id, $0) } ?? [])

      return vs.copyWith(books:
        ids.map { id in
          books[id] ?? FavoritesItem.init(
            isLoading: true,
            error: nil,
            id: id,
            title: nil,
            subtitle: nil,
            thumbnail: nil)
      })
    case .refreshing:
      return vs.copyWith(books: vs.books ?? [], isRefreshing: true)
    }
  }


  private static func replace(items: [FavoritesItem], by newItem: FavoritesItem) -> [FavoritesItem] {
    return items.map { item in
      if item.id == newItem.id {
        return item.copyWith(
          isLoading: false,
          error: nil,
          title: newItem.title,
          subtitle: newItem.subtitle,
          thumbnail: newItem.thumbnail
        )
      } else {
        return item
      }
    }
  }
}

// MARK: - Single event
enum FavoritesSingleEvent {
  case removedFromFavorites(FavoritesItem)
  case removeFromFavoritesError(FavoritesItem)
}

// MARK: - Interactor
protocol FavoritesInteractor {
  func favoritedIds() -> Observable<[String]>

  func getBooksBy(ids: [String]) -> Observable<FavoritesPartialChange>

  func refresh(ids: [String]) -> Observable<FavoritesPartialChange>

  func removeFavorite(item: FavoritesItem) -> Single<FavoritesSingleEvent>
}
