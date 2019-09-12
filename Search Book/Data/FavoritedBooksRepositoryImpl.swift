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
        let ids = userDefaults.stringArray(forKey: FavoritedBooksRepositoryImpl.favIdsKey) ?? []
        let bookId = book.id

        if ids.contains(bookId) {
            userDefaults.set(
                ids.filter { $0 != book.id },
                forKey: FavoritedBooksRepositoryImpl.favIdsKey
            )

            return ToggleFavoritedResult(
                added: false,
                book: book
            )
        } else {
            userDefaults.set(
                ids + [book.id],
                forKey: FavoritedBooksRepositoryImpl.favIdsKey
            )

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
            .share(replay: 1, scope: .whileConnected)
    }
}
