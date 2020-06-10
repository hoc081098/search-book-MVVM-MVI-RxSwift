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

// MARK: - BookApi
class BookApi {
  private static let baseUrl = "https://www.googleapis.com/books/v1/volumes"

  func searchBook(by query: String, and startIndex: Int) -> Single<Result<BooksResponse, ApiErrorMessage>> {
    RxAlamofire
      .requestData(
          .get,
        Self.baseUrl,
        parameters: [
          "q": query,
          "startIndex": startIndex
        ]
      )
      .do(onSubscribe: { print("BookApi::searchBook query=\(query), startIndex=\(startIndex)") })
      .expectingObject(ofType: BooksResponse.self)
      .asSingle()
  }

  func getBookDetail(by id: String) -> Single<Result<BookResponse, ApiErrorMessage>> {
    RxAlamofire
      .requestData(.get, Self.baseUrl + "/" + id)
      .do(onSubscribe: { print("BookApi::getBookDetailBy \(id)") })
      .expectingObject(ofType: BookResponse.self)
      .asSingle()
  }
}

// MARK: - ApiErrorMessage + Extensions

struct ApiErrorMessage: Decodable, Error {
  let code: Int
  let message: String
  let cause: Error?

  init(code: Int, message: String, cause: Error? = nil) {
    self.code = code
    self.message = message
    self.cause = cause
  }

  init(from decoder: Decoder) throws {
    let container = try! decoder
      .container(keyedBy: ApiErrorMessageKeys.self)
      .nestedContainer(keyedBy: ErrorMessageKeys.self, forKey: .error)

    self.code = try! container.decode(Int.self, forKey: .code)
    self.message = try! container.decode(String.self, forKey: .message)
    self.cause = nil
  }

  enum ApiErrorMessageKeys: String, CodingKey {
    case error
  }

  enum ErrorMessageKeys: String, CodingKey {
    case code
    case message
  }
}

private extension Observable where Element == (HTTPURLResponse, Data) {
  func expectingObject<T: Decodable>(ofType type: T.Type) -> Observable<Result<T, ApiErrorMessage>> {
    self.map { (httpURLResponse, data) in

      if 200..<300 ~= httpURLResponse.statusCode {
        let object = try JSONDecoder().decode(type, from: data)
        return .success(object)
      }

      let apiErrorMessage: ApiErrorMessage
      do {
        apiErrorMessage = try JSONDecoder().decode(ApiErrorMessage.self, from: data)
      } catch {
        apiErrorMessage = ApiErrorMessage(code: -1, message: "Server error", cause: error)
      }
      return .failure(apiErrorMessage)
    }
  }
}
