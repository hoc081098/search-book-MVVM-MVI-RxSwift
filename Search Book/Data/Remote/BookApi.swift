//
//  BookApi.swift
//  Search Book
//
//  Created by Petrus on 7/10/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxAlamofire
import RxSwift

class BookApi {
    func searchBook(query: String, startIndex: Int) -> Observable {
//        http://www.ccheptea.com/2019-03-25-handling-rest-errors-with-rxswift/
        return RxAlamofire.requestJSON(
            .get,
            "",
            parameters: ["": ""]
        )
    }
}
