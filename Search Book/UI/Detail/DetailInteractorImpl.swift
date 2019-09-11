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

    init(bookRepository: BookRepository) {
        self.bookRepository = bookRepository
    }

    func refresh(id: String) -> Observable<DetailPartialChange> {
        return bookRepository
            .getBookBy(id: id, with: .localFirst)
            .map(BookDetail.init(fromDomain:))
            .map { .detailLoaded($0) }
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
}
