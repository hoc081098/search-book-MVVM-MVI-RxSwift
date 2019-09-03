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
    func searchBook(query: String, startIndex: Int) -> Single<[Book]>

    func getBookBy(id: String, with: CachePolicy) -> Observable<Book>
}
