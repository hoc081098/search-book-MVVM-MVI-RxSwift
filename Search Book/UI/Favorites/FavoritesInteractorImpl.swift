//
//  FavoritesInteractorImpl.swift
//  Search Book
//
//  Created by Petrus on 9/14/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

class FavoritesInteractorImpl: FavoritesInteractor {
    private let favBooksRepo: FavoritedBooksRepository
    private let booksRepo: BookRepository

    init(favBooksRepo: FavoritedBooksRepository, booksRepo: BookRepository) {
        self.favBooksRepo = favBooksRepo
        self.booksRepo = booksRepo
    }

    func favoritedIds() -> Observable<Set<String>> {
        return self.favBooksRepo.favoritedIds()
    }

    func getBooksBy(ids: Set<String>) -> Observable<FavoritesPartialChange> {
        let id$ = Observable.from(ids)
        
        return id$.flatMap { (id: String) -> Observable<FavoritesPartialChange> in
            self.booksRepo
                .getBookBy(id: id, with: .localFirst)
                .map { FavoritesBook.init(fromDomain: $0) }
                .map { .bookLoaded($0) }
                .startWith(.bookLoading(id))
                .catchError { (error) -> Observable<FavoritesPartialChange> in .just(.bookError(.init(from: error)))
                }
            }
    }
    
    func refresh(ids: Set<String>) -> Observable<FavoritesPartialChange> {
        let book$s = ids.map { id in
            self.booksRepo
                .getBookBy(id: id, with: .networkOnly)
                .map { FavoritesBook.init(fromDomain: $0) }
                .takeLast(1)
        }
        return Observable
            .combineLatest(book$s) { books in FavoritesPartialChange.refreshSuccess(books) }
            .catchError{ error -> Observable<FavoritesPartialChange> in
                .just(.refreshError(.init(from: error)))
            }
    }
}
