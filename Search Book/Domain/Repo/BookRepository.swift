//
//  BookRepository.swift
//  Search Book
//
//  Created by Petrus on 7/10/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

protocol BookRepository {
  func searchBook(by query: String, and startIndex: Int) -> Single<DomainResult<[Book]>>

  func getBook(by id: String, with cachePolicy: CachePolicy) -> Observable<DomainResult<Book>>
}
