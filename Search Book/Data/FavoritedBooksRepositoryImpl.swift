//
//  FavoritedBooksRepositoryImpl.swift
//  Search Book
//
//  Created by HOANG TAN DUY on 9/9/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class FavoritedBooksRepositoryImpl: FavoritedBooksRepository {
    private let userDefaults: UserDefaults
    private static let favIdsKey = "fav_ids"

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func toggleFavorited(book: Book) -> ToggleFavoritedResult {
        var ids = Set(userDefaults.stringArray(forKey: FavoritedBooksRepositoryImpl.favIdsKey) ?? [])
        let bookId = book.id

        if ids.contains(bookId) {
            ids.remove(bookId)
            userDefaults.set(Array(ids), forKey: FavoritedBooksRepositoryImpl.favIdsKey)

            return ToggleFavoritedResult(
                added: false,
                book: book
            )
        } else {
            ids.insert(bookId)
            userDefaults.set(Array(ids), forKey: FavoritedBooksRepositoryImpl.favIdsKey)

            return ToggleFavoritedResult(
                added: true,
                book: book
            )
        }
    }

    func favoritedIds() -> Observable<Set<String>> {
        return userDefaults.rx
            .observe([String].self, FavoritedBooksRepositoryImpl.favIdsKey)
            .distinctUntilChanged()
            .map { ids in Set(ids ?? []) }
    }
}
