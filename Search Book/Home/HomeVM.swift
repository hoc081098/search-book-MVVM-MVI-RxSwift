//
//  HomeVM.swift
//  Search Book
//
//  Created by Petrus on 7/8/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt

class HomeVM: MviViewModelType {
    private let intentS = PublishRelay<HomeIntent>()
    private let singleEventS = PublishRelay<HomeSingleEvent>()
    private let bookRepository: BookRepository
    private let disposeBag = DisposeBag()

    let state$: Driver<HomeViewState>
    let singleEvent$: Signal<HomeSingleEvent>

    func process(intent$: Observable<HomeIntent>) -> Disposable {
        return intent$.bind(to: intentS)
    }

    init(bookRepository: BookRepository) {
        self.bookRepository = bookRepository
        singleEvent$ = singleEventS.asSignal()

        intentS
            .filterMap { (intent: HomeIntent) -> FilterMap<String> in
                if case .search(let searchTerm) = intent {
                    return .map(searchTerm)
                } else {
                    return .ignore
                }
            }.flatMapLatest { searchTerm in }
    }
}
