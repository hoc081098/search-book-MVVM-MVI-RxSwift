//
//  DetailContract.swift
//  Search Book
//
//  Created by Petrus on 9/10/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Intent
enum DetailIntent {
    case initial
    case refresh
    case toggleFavorite(BookDetail)
}

// MARK: - ViewState
struct DetailViewState: Equatable {
    let isLoading: Bool
    let error: DetailError?
    let detail: BookDetail

    func copyWith(
        isLoading: Bool? = nil,
        error: DetailError? = nil,
        detail: BookDetail? = nil
    ) -> DetailViewState {
        return DetailViewState(
            isLoading: isLoading ?? self.isLoading,
            error: error,
            detail: detail ?? self.detail
        )
    }
}

protocol BookDetailType {
    var id: String { get }
}

enum BookDetail: BookDetailType, Equatable {
    var id: String {
        switch self {
        case .initial(let id):
            return id
        case .loaded(let id):
            return id
        }
    }

    case initial(
        id: String
    )
    case loaded(
        id: String
    )
}

enum DetailError: Equatable {
    case networkError
    case serverResponseError(Int, String)
    case unexpectedError
}

extension DetailError {
    init(from error: Error) {
        if let appError = error as? AppError {
            switch appError {
            case .networkError:
                self = .networkError
            case .serverResponseError(let code, let message):
                self = .serverResponseError(code, message)
            case .unexpectedError:
                self = .unexpectedError
            }
        } else {
            self = .unexpectedError
        }
    }
}


// MARK: - Event
enum DetailSingleEvent {

}

// MARK: - Partial Change
enum DetailPartialChange {

}

// MARK: - Interactor
protocol DetailInteractor {

}
