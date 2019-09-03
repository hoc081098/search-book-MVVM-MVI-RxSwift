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
}

// MARK: - ViewState
struct HomeViewState: Equatable {
    let searchTerm: String
    let books: [HomeBookItem]

    let isFirstPageLoading: Bool
    let firstPageError: HomeError?

    let isNextPageLoading: Bool
    let nextPageError: HomeError?

    func copyWith(
        searchTerm: String? = nil,
        books: [HomeBookItem]? = nil,
        isFirstPageLoading: Bool? = nil,
        firstPageError: HomeError? = nil,
        isNextPageLoading: Bool? = nil,
        nextPageError: HomeError? = nil
    ) -> HomeViewState {
        return HomeViewState(
            searchTerm: searchTerm ?? self.searchTerm,
            books: books ?? self.books,
            isFirstPageLoading: isFirstPageLoading ?? self.isFirstPageLoading,
            firstPageError: firstPageError,
            isNextPageLoading: isNextPageLoading ?? self.isNextPageLoading,
            nextPageError: nextPageError
        )
    }
}

enum HomeError: Equatable {
    case networkError
    case serverResponseError
}

struct HomeBookItem: Equatable {
    let id: String
    let title: String?
    let subtitle: String?
    let thumbnail: String?
    let isFavorited: Bool?
}

extension HomeBookItem {
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
}

// MARK: - Event
enum HomeSingleEvent {

}

// MARK: - Partial Change
enum PartialChange {
    case loadingFirstPage
    case loadFirstPageError(error: HomeError, searchTerm: String)
    case firstPageLoaded(books: [HomeBookItem], searchTerm: String)

    case loadingNextPage
    case nextPageLoaded(books: [HomeBookItem], searchTerm: String)
    case loadNextPageError(error: HomeError, searchTerm: String)
}

protocol HomeInteractor {
    func searchBook(query: String) -> Observable<PartialChange>
}
