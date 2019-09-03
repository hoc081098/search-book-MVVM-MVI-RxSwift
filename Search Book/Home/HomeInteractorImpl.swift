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
    private let bookRepository: BookRepository

    init(bookRepository: BookRepository) {
        self.bookRepository = bookRepository
    }

    func searchBook(query: String) -> Observable<PartialChange> {
        return self.bookRepository
            .searchBook(query: query, startIndex: 0)
            .asObservable()
            .map { books in books.map { book in HomeBookItem(fromDomain: book) } }
            .map { books in .firstPageLoaded(books: books, searchTerm: query) }
            .startWith(.loadingFirstPage)
            .catchError { (error: Error) -> Observable<PartialChange> in
                .just(.loadFirstPageError(error: .networkError, searchTerm: query))
            }
        }
    }
