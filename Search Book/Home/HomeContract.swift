//
//  HomeContract.swift
//  Search Book
//
//  Created by Petrus on 7/9/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

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

    init() {
        searchTerm = ""
        books = []
        isFirstPageLoading = true
        firstPageError = nil
        isNextPageLoading = false
        nextPageError = nil
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
