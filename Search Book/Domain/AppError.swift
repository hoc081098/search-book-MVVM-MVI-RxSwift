//
//  Error.swift
//  Search Book
//
//  Created by HOANG TAN DUY on 9/8/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

enum AppError : Error {
    case networkError(Error?)
    case serverResponseError(Int, String)
    case unexpectedError(Error?)
}
