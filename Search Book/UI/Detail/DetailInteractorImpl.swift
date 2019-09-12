//
//  DetailInteractorImpl.swift
//  Search Book
//
//  Created by Petrus on 9/11/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

class DetailInteractorImpl: DetailInteractor {
    private let bookRepository: BookRepository
    private let favBookRepo: FavoritedBooksRepository

    init(bookRepository: BookRepository, favBookRepo: FavoritedBooksRepository) {
        self.bookRepository = bookRepository
        self.favBookRepo = favBookRepo
    }

    func refresh(id: String) -> Observable<DetailPartialChange> {
        return bookRepository
            .getBookBy(id: id, with: .localFirst)
            .delay(2, scheduler: MainScheduler.instance)
            .map(BookDetail.init(fromDomain:))
            .map { .refreshSuccess($0) }
            .startWith(.refreshing)
            .catchError { (error) -> Observable<DetailPartialChange> in .just(.refreshError(.init(from: error))) }
    }

    func getDetailBy(id: String) -> Observable<DetailPartialChange> {
        return bookRepository
            .getBookBy(id: id, with: .networkOnly)
            .map(BookDetail.init(fromDomain:))
            .map { .detailLoaded($0) }
            .startWith(.loading)
            .catchError { (error) -> Observable<DetailPartialChange> in .just(.detailError(.init(from: error))) }
    }
    
    func favoritedIds() -> Observable<Set<String>> {
        return self.favBookRepo.favoritedIds()
    }
    
    func toggleFavorited(detail: BookDetail) -> Single<DetailSingleEvent> {
        return Single
            .deferred {
                let result = self.favBookRepo.toggleFavorited(book: detail.toDomain())
                return .just(result)
            }
            .map { (result: ToggleFavoritedResult) -> DetailSingleEvent in
                let added = result.added
                let detail = BookDetail.init(fromDomain: result.book)
                
                if added {
                    return .addedToFavorited(detail)
                } else {
                    return .removedFromFavorited(detail)
                }
        }
    }
}
