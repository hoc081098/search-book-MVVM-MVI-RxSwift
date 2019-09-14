//
//  FavoritesContract.swift
//  Search Book
//
//  Created by Petrus on 9/12/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Intent
enum FavoritesIntent {
    case initial
    case refresh
    case removeFavorite
}

// MARK: - View state
struct FavoritesViewState : Equatable{
    let books: [FavoritesBook]
}

struct FavoritesBook : Equatable {
    let id: String
    let title: String
    let subtitle: String
    let thumbnail: String
    
    let isLoading: Bool
    let error: FavoritesError?
}

enum FavoritesError: Equatable {
    case networkError
    case serverResponseError(Int, String)
    case unexpectedError
}


// MARK: - Partial change

// MARK: - Single event

// MARK: - Interactor

