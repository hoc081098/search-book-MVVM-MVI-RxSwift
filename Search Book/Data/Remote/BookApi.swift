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
    func searchBook(query: String, startIndex: Int) -> Single<ApiResult<ApiErrorMessage, BooksResponse>> {
        return RxAlamofire
            .requestData(
                    .get,
                "https://www.googleapis.com/books/v1/volumes",
                parameters: [
                    "q": query,
                    "startIndex": startIndex
                ]
            )
            .expectingObject(ofType: BooksResponse.self)
            .asSingle();
    }
}

struct ApiErrorMessage: Decodable {
    let code: Int
    let message: String

    init(code: Int, message: String) {
        self.code = code
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try! decoder.container(keyedBy: ApiErrorMessageKeys.self)
            .nestedContainer(keyedBy: ErrorMessageKeys.self, forKey: .error)
        self.code = try! container.decode(Int.self, forKey: .code)
        self.message = try! container.decode(String.self, forKey: .message)
    }

    enum ApiErrorMessageKeys: String, CodingKey {
        case error
    }

    enum ErrorMessageKeys: String, CodingKey {
        case code
        case message
    }
}

enum ApiResult<Error, Value> {
    case success(Value)
    case failure(Error)

    init(value: Value) {
        self = .success(value)
    }

    init(error: Error) {
        self = .failure(error)
    }
}

extension Observable where Element == (HTTPURLResponse, Data) {
    fileprivate func expectingObject<T: Decodable>(ofType type: T.Type) -> Observable<ApiResult<ApiErrorMessage, T>> {
        return self.map { (httpURLResponse, data) -> ApiResult<ApiErrorMessage, T> in
            switch httpURLResponse.statusCode {
            case 200...299:
                // is status code is successful we can safely decode to our expected type T
                let object = try JSONDecoder().decode(type, from: data)
                return .success(object)
            default:
                // otherwise try
                let apiErrorMessage: ApiErrorMessage
                do {
                    // to decode an expected error
                    apiErrorMessage = try JSONDecoder().decode(ApiErrorMessage.self, from: data)
                } catch _ {
                    // or not. (this occurs if the API failed or doesn't return a handled exception)
                    apiErrorMessage = ApiErrorMessage(code: -1, message: "Server error")
                }
                return .failure(apiErrorMessage)
            }
        }
    }
}
