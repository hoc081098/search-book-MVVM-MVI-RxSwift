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

class HomeVM: MviViewModelType {
  private let intentS = PublishRelay<HomeIntent>()
  private let singleEventS = PublishRelay<HomeSingleEvent>()
  private let viewStateS: BehaviorRelay<HomeViewState>

  private let homeInteractor: HomeInteractor
  private let disposeBag = DisposeBag()

  // MARK: - Implements `MviViewModelType`

  var state$: Driver<HomeViewState> { self.viewStateS.asDriver() }

  var singleEvent$: Signal<HomeSingleEvent> { self.singleEventS.asSignal() }

  func process(intent$: Observable<HomeIntent>) -> Disposable { intent$.bind(to: intentS) }

  // MARK: - Initializer

  init(homeInteractor: HomeInteractor) {
    self.homeInteractor = homeInteractor

    let initialState = HomeViewState(
      searchTerm: "",
      items: [],
      books: [],
      favCount: 0
    )
    self.viewStateS = .init(value: initialState)

    let searchString$ = intentS
      .compactMap { intent -> String? in
        if case .search(let searchTerm) = intent { return searchTerm }
        return nil
      }
      .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
      .distinctUntilChanged()
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .share()

    let retryFirstPage$ = intentS
      .withLatestFrom(viewStateS) { (intent: $0, state: $1) }
      .filter { $0.intent == .retryLoadFirstPage && $0.state.shouldRetryFirstPage }
      .withLatestFrom(searchString$)

    let loadNextPage$ = intentS
      .filter { $0 == .loadNextPage }
      .withLatestFrom(viewStateS)
      .compactMap { $0.shouldLoadNextPage ? $0.books.count: nil }
      .withLatestFrom(searchString$) { (startIndex: $0, query: $1) }

    let retryNextPage$ = intentS
      .filter { $0 == .retryLoadNextPage }
      .withLatestFrom(viewStateS)
      .compactMap { $0.shouldRetryNextPage ? $0.books.count: nil }
      .withLatestFrom(searchString$) { (startIndex: $0, query: $1) }

    let changes = [
      Observable
        .merge([loadNextPage$, retryNextPage$])
        .flatMapFirst { [homeInteractor, singleEventS] tuple in
          homeInteractor
            .loadNextPage(
              query: tuple.query,
              startIndex: tuple.startIndex
            )
            .observeOn(MainScheduler.instance)
            .do(onNext: { change in
              if case .loadNextPageError(let error, _) = change {
                singleEventS.accept(.loadError(error))
              }
            })
      },
      Observable
        .merge([searchString$, retryFirstPage$])
        .flatMapLatest { [homeInteractor, singleEventS] searchTerm in
          homeInteractor
            .searchBook(query: searchTerm)
            .observeOn(MainScheduler.instance)
            .do(onNext: { change in
              if case .loadFirstPageError(let error, _) = change {
                singleEventS.accept(.loadError(error))
              }
            })
      }
    ]

    Observable.combineLatest(
      Observable
        .merge(changes)
        .startWith(.initial)
        .observeOn(MainScheduler.asyncInstance)
        .scan(initialState) { $1.reduce(state: $0) }
        .distinctUntilChanged(),
      self
        .homeInteractor
        .favoritedIds()
        .distinctUntilChanged()
    ) { $0.copyWith(favoritedIds: $1) }
      .bind(to: self.viewStateS)
      .disposed(by: self.disposeBag)

    intentS
      .compactMap { intent -> HomeBook? in
        if case .toggleFavorite(let book) = intent { return book }
        return nil
      }
      .groupBy { $0.id }
      .flatMap { $0.throttle(.milliseconds(500), scheduler: MainScheduler.instance) }
      .concatMap { [homeInteractor] in homeInteractor.toggleFavorited(book: $0) }
      .subscribe(onNext: { [singleEventS] in singleEventS.accept($0) })
      .disposed(by: self.disposeBag)
  }

  deinit {
    print("HomeVM::deinit")
  }
}
