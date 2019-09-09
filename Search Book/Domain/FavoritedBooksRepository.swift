//
//  FavoritedBooksRepository.swift
//  Search Book
//
//  Created by HOANG TAN DUY on 9/9/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

struct ToggleFavoritedResult {
    let added: Bool
    let book: Book
}

protocol FavoritedBooksRepository {
    func toggleFavorited(book: Book) -> ToggleFavoritedResult

    func favoritedIds() -> Observable<Set<String>>
}
