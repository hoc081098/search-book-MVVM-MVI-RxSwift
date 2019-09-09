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

    func searchBook(query: String) -> Observable<PartialChange> {
        print("Search \(query)")
        return self.bookRepository
            .searchBook(query: query, startIndex: 0)
            .do(onSuccess: { _ in print("Search \(Thread.current)") })
            .asObservable()
            .map { books in books.map { book in HomeBook(fromDomain: book) } }
            .map { books in .firstPageLoaded(books: books, searchTerm: query) }
            .startWith(.loadingFirstPage)
            .catchError { (error: Error) -> Observable<PartialChange> in
                    .just(.loadFirstPageError(error: .init(from: error), searchTerm: query))
        }
    }

    func loadNextPage(query: String, startIndex: Int) -> Observable<PartialChange> {
        print("Load next page \(query), \(startIndex)")
        return self.bookRepository
            .searchBook(query: query, startIndex: startIndex)
            .do(onSuccess: { _ in print("Search \(Thread.current)") })
            .asObservable()
            .map { books in books.map { book in HomeBook(fromDomain: book) } }
            .map { books in .nextPageLoaded(books: books, searchTerm: query) }
            .startWith(.loadingNextPage)
            .catchError { (error: Error) -> Observable<PartialChange> in
                    .just(.loadNextPageError(error: .init(from: error), searchTerm: query))

        }
    }

    func toggleFavorited(book: HomeBook) -> Single<HomeSingleEvent> {
        return Single
            .deferred {
                let result = self.favoritedBooksRepository.toggleFavorited(book: book.toDomain())
                return .just(result)
            }
            .map { (result: ToggleFavoritedResult) -> HomeSingleEvent in
                let added = result.added
                let book = HomeBook(fromDomain: result.book)

                if added {
                    return .addedToFavorited(book)
                } else {
                    return .removedFromFavorited(book)
                }
        }
    }

    func favoritedIds() -> Observable<Set<String>> {
        return favoritedBooksRepository.favoritedIds()
    }
}