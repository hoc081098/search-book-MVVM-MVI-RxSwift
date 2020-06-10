//
//  FavoritedBooksRepository.swift
//  Search Book
//
//  Created by Petrus Nguyễn Thái Học on 9/9/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

struct ToggleFavoritedResult {
  let added: Bool
  let book: Book
}

protocol FavoritedBooksRepository {
  func toggleFavorited(book: Book) -> Single<DomainResult<ToggleFavoritedResult>>

  func favoritedIds() -> Observable<Set<String>>
}
