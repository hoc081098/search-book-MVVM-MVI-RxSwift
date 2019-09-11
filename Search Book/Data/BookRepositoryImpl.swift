//
// Created by HOANG TAN DUY on 9/3/19.
// Copyright (c) 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift
import RxSwiftExt

class BookRepositoryImpl: BookRepository {
    private let bookApi: BookApi

    init(bookApi: BookApi) {
        self.bookApi = bookApi
    }

    func searchBook(query: String, startIndex: Int) -> Single<[Book]> {
        return bookApi
            .searchBook(query: query, startIndex: startIndex)
            .flatMap { apiResult in
                switch apiResult {
                case .success(let value):
                    return .just(value.books.map(toBookDomain(from:)))
                case .failure(let error):
                    return .error(AppError.serverResponseError(error.code, error.message))
                }
            }
            .catchError { (error: Error) -> Single<[Book]> in
                if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    return .error(AppError.networkError(error))
                } else {
                    return .error(error)
                }
        }
    }

    private var cached = [String: (Book, Date)]()
    private static let timeoutInSeconds: TimeInterval = 30

    private func getBookByIdWithNetworkPolicy(id: String) -> Single<Book> {
        return bookApi
            .getBookDetailBy(id: id)
            .flatMap { apiResult in
                switch apiResult {
                case .success(let value):
                    return .just(toBookDomain(from: value))
                case .failure(let error):
                    return .error(AppError.serverResponseError(error.code, error.message))
                }
            }
            .catchError { (error: Error) -> Single<Book> in
                if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    return .error(AppError.networkError(error))
                } else {
                    return .error(error)
                }
        }
    }

    private func getBookByIdWithNetworkPolicyAndSaveToCache(id: String) -> Single<Book> {
        return self
            .getBookByIdWithNetworkPolicy(id: id)
            .do(onSuccess: { self.cached[id] = ($0, Date()) })
    }

    func getBookBy(id: String, with cachePolicy: CachePolicy) -> Observable<Book> {
        let tuple$ = Observable.just((id, cachePolicy))

        return Observable.merge([
            tuple$
                .filter { $0.1 == .localFirst }
                .filter { tuple in
                    if let cachedTuple = self.cached[tuple.0] {
                        // in cached but timeout
                        return Date().timeIntervalSince1970 -
                            cachedTuple.1.timeIntervalSince1970 >= BookRepositoryImpl.timeoutInSeconds
                    } else {
                        // not in cached
                        return true
                    }
            },
            tuple$.filter { $0.1 == .networkOnly }
            ])
            .map { $0.0 }
            .flatMap { self.getBookByIdWithNetworkPolicyAndSaveToCache(id: $0) }
            .startWithOptional(self.cached[id]?.0)
    }
}

private extension Observable {
    func startWithOptional(_ value: Element?) -> Observable<Element> {
        if let value = value {
            return startWith(value)
        } else {
            return self
        }
    }
}
