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
    
}

// MARK: - ViewState
struct DetailViewState: Equatable {


    func copyWith(

    ) -> DetailViewState {
        return DetailViewState(

        )
    }
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
