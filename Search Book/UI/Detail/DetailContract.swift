//
//  DetailContract.swift
//  Search Book
//
//  Created by Petrus on 9/10/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Intent
enum DetailIntent: Equatable {
  case initial(InitialBookDetail)
  case refresh
  case toggleFavorite
}

// MARK: - ViewState
struct DetailViewState: Equatable {
  let isLoading: Bool
  let isRefreshing: Bool
  let error: AppError?
  let detail: BookDetail?

  func copyWith(
    isLoading: Bool? = nil,
    isRefreshing: Bool? = nil,
    error: AppError? = nil,
    detail: BookDetail? = nil
  ) -> DetailViewState {
      .init(
        isLoading: isLoading ?? self.isLoading,
        isRefreshing: isRefreshing ?? self.isRefreshing,
        error: error,
        detail: detail ?? self.detail
      )
  }

  func copyWith(favoritedIds ids: Set<String>) -> DetailViewState {
    if let detail = self.detail {
      return self.copyWith(detail: detail.withFavorited(ids.contains(detail.id)))
    }
    return self
  }
}

struct InitialBookDetail: Equatable {
  let id: String
  let title: String?
  let subtitle: String?
  let thumbnail: String?
  let isFavorited: Bool?
}

extension InitialBookDetail {
  init(fromHomeBook b: HomeBook) {
    self.id = b.id
    self.title = b.title
    self.subtitle = b.subtitle
    self.thumbnail = b.thumbnail
    self.isFavorited = b.isFavorited
  }

  init(fromFavoritesItem item: FavoritesItem) {
    self.id = item.id
    self.title = item.title
    self.subtitle = item.subtitle
    self.thumbnail = item.thumbnail
    self.isFavorited = true
  }
}

struct BookDetail: Equatable {
  let id: String
  let title: String?
  let subtitle: String?
  let authors: [String]?
  let thumbnail: String?
  let largeImage: String?
  let description: String?
  let publishedDate: String?
  let isFavorited: Bool?
}

extension BookDetail {
  init(fromDomain b: Book) {
    self.id = b.id
    self.title = b.title
    self.subtitle = b.subtitle
    self.authors = b.authors
    self.thumbnail = b.thumbnail
    self.largeImage = b.largeImage
    self.description = b.description
    self.publishedDate = b.publishedDate
    self.isFavorited = nil
  }

  init(fromInitial b: InitialBookDetail) {
    self.id = b.id
    self.title = b.title
    self.subtitle = b.subtitle
    self.authors = nil
    self.thumbnail = b.thumbnail
    self.largeImage = nil
    self.description = nil
    self.publishedDate = nil
    self.isFavorited = nil
  }

  func withFavorited(_ isFavorited: Bool) -> BookDetail {
    BookDetail.init(
      id: id,
      title: title,
      subtitle: subtitle,
      authors: authors,
      thumbnail: thumbnail,
      largeImage: largeImage,
      description: description,
      publishedDate: publishedDate,
      isFavorited: isFavorited
    )
  }

  func toDomain() -> Book {
    Book(
      id: id,
      title: title,
      subtitle: subtitle,
      authors: authors,
      thumbnail: thumbnail,
      largeImage: largeImage,
      description: description,
      publishedDate: publishedDate
    )
  }
}

// MARK: - Event
enum DetailSingleEvent {
  case addedToFavorited(BookDetail)
  case removedFromFavorited(BookDetail)
  case toggleFavoritedError(AppError, BookDetail)

  case refreshSuccess
  case refreshError(AppError)

  case getDetailError(AppError)
}

// MARK: - Partial Change
enum DetailPartialChange {

  case refreshing
  case refreshError(AppError)
  case refreshSuccess(BookDetail)

  case initialLoaded(InitialBookDetail)
  case loading
  case detailLoaded(BookDetail)
  case detailError(AppError)
}

extension DetailPartialChange: CustomStringConvertible {
  var description: String {
    switch self {
    case .refreshing:
      return "refreshing"
    case .refreshError:
      return "refreshError"
    case .initialLoaded:
      return "initialLoaded"
    case .detailLoaded:
      return "detailLoaded"
    case .loading:
      return "loading"
    case .detailError:
      return "detailError"
    case .refreshSuccess:
      return "refreshSuccess"
    }
  }
}

extension DetailPartialChange {
  func reduce(state vs: DetailViewState) -> DetailViewState {
    print("DetailPartialChange::reduce change=\(self)")

    switch self {
    case .refreshing:
      return vs.copyWith(isRefreshing: true)
    case .refreshError:
      return vs.copyWith(isRefreshing: false)
    case .initialLoaded(let initial):
      return vs.copyWith(
        isLoading: false,
        error: nil,
        detail: vs.detail ?? .init(fromInitial: initial)
      )
    case .detailLoaded(let detail):
      return vs.copyWith(
        isLoading: false,
        error: nil,
        detail: detail
      )
    case .loading:
      return vs.copyWith(isLoading: true)
    case .detailError(let error):
      return vs.copyWith(
        isLoading: false,
        error: error
      )
    case .refreshSuccess(let detail):
      return vs.copyWith(
        isRefreshing: false,
        detail: detail
      )
    }
  }
}

// MARK: - Interactor
protocol DetailInteractor {
  func refresh(id: String) -> Observable<DetailPartialChange>

  func getDetailBy(id: String) -> Observable<DetailPartialChange>

  func favoritedIds() -> Observable<Set<String>>

  func toggleFavorited(detail: BookDetail) -> Single<DetailSingleEvent>
}
