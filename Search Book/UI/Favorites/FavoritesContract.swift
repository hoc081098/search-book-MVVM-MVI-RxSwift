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
    case removeFavorite
}

// MARK: - View state
struct FavoritesViewState: Equatable {
    let books: [FavoritesItem]
    func copyWith(books: [FavoritesItem]? = nil) -> FavoritesViewState {
        return .init(books: books ?? self.books)
    }
}

struct FavoritesItem: Equatable {
    let isLoading: Bool
    let error: FavoritesError?
    let book: FavoritesBook?

    func copyWith(
        isLoading: Bool? = nil,
        error: FavoritesError? = nil,
        book: FavoritesBook? = nil
    ) -> FavoritesItem {
        return .init(
            isLoading: isLoading ?? self.isLoading,
            error: error,
            book: book ?? self.book
        )
    }
}

struct FavoritesBook: Equatable {
    let id: String
    let title: String?
    let subtitle: String?
    let thumbnail: String?
}

extension FavoritesBook {
    init(fromDomain b: Book) {
        self.id = b.id
        self.title = b.title
        self.subtitle = b.subtitle
        self.thumbnail = b.thumbnail
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
    case bookLoaded(FavoritesBook)
    case bookError(FavoritesError)

    case refreshSuccess([FavoritesBook])
    case refreshError(FavoritesError)
}

// MARK: - Single event
enum FavoritesSingleEvent {

}

// MARK: - Interactor
protocol FavoritesInteractor {
    func favoritedIds() -> Observable<Set<String>>
    func getBooksBy(ids: Set<String>) -> Observable<FavoritesPartialChange>
    func refresh(ids: Set<String>) -> Observable<FavoritesPartialChange>
}
