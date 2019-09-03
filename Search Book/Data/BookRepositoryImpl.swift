//
// Created by HOANG TAN DUY on 9/3/19.
// Copyright (c) 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

class BookRepositoryImpl: BookRepository {
    private let bookApi: BookApi

    init(bookApi: BookApi) {
        self.bookApi = bookApi
    }

    func searchBook(query: String, startIndex: Int) -> Single<[Book]> {
        return bookApi.searchBook(query: query, startIndex: startIndex)
            .map { apiResult in
                switch apiResult {
                case .success(let value):
                    return value.books.map(toBookDomain(from:))
                case .failure(let error):
                    return []
                }
            }
    }

    func getBookBy(id: String, with: CachePolicy) -> Observable<Book> {
        fatalError("getBookBy(id:with:) has not been implemented")
    }
}