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
enum DetailIntent {
    case initial(InitialBookDetail)
    case refresh
    case toggleFavorite
}

// MARK: - ViewState
struct DetailViewState: Equatable {
    let isLoading: Bool
    let isRefreshing: Bool
    let error: DetailError?
    let detail: BookDetail?

    func copyWith(
        isLoading: Bool? = nil,
        isRefreshing: Bool? = nil,
        error: DetailError? = nil,
        detail: BookDetail? = nil
    ) -> DetailViewState {
        return DetailViewState(
            isLoading: isLoading ?? self.isLoading,
            isRefreshing: isRefreshing ?? self.isRefreshing,
            error: error,
            detail: detail ?? self.detail
        )
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
        return BookDetail.init(id: id,
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
        return Book(
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

enum DetailError: Equatable {
    case networkError
    case serverResponseError(Int, String)
    case unexpectedError
}

extension DetailError {
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


// MARK: - Event
enum DetailSingleEvent {
    case addedToFavorited(BookDetail)
    case removedFromFavorited(BookDetail)
    
    case refreshSuccess
    case refreshError(DetailError)
    
    case getDetailError(DetailError)
}

// MARK: - Partial Change
enum DetailPartialChange {

    case refreshing
    case refreshError(DetailError)
    case refreshSuccess(BookDetail)

    case initialLoaded(InitialBookDetail)
    case loading
    case detailLoaded(BookDetail)
    case detailError(DetailError)

    var name: String {
        switch self {

        case .refreshing:
            return "refreshing"
        case .refreshError(_):
            return "refreshError"
        case .initialLoaded(_):
            return "initialLoaded"
        case .detailLoaded(_):
            return "detailLoaded"
        case .loading:
            return "loading"
        case .detailError(_):
            return "detailError"
        case .refreshSuccess:
            return "refreshSuccess"
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
