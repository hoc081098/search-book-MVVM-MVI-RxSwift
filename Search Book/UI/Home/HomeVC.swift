//
//  ViewController.swift
//  Search Book
//
//  Created by Petrus on 7/8/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import MaterialComponents.MaterialSnackbar
import SwinjectStoryboard
import Swinject
import MaterialComponents.MaterialButtons

// MARK: - HomeVC

class HomeVC: UIViewController {

  var homeVM: HomeVM!
  private let disposeBag = DisposeBag()
  private let intentS = PublishRelay<HomeIntent>()

  // MARK: - Views

  @IBOutlet weak var tableView: UITableView!
  private weak var fab: MDCFloatingButton?
  private weak var labelFavCount: UILabel?
  private weak var searchBar: UISearchBar!
  private var fabY: CGFloat?

  private var cellHeights = [IndexPath: CGFloat]()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    let searchBar = UISearchBar(frame: .zero).apply {
      $0.placeholder = "Search book"
      $0.sizeToFit()
    }
    self.navigationItem.titleView = searchBar
    self.searchBar = searchBar

    self.tableView.rx
      .willDisplayCell
      .subscribe(onNext: { [weak self] in
        self?.cellHeights[$0.indexPath] = $0.cell.frame.size.height
      })
      .disposed(by: self.disposeBag)
    self.tableView.rx
      .setDelegate(self)
      .disposed(by: self.disposeBag)

    bindVM()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.addFab()
  }

  deinit {
    print("HomeVC::deinit")
  }
}

// MARK: - Bind VM
private extension HomeVC {
  func bindVM() {
    // create rx datasource
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, HomeItem>>(
      configureCell: { [weak self] dataSource, tableView, indexPath, item in
        switch item {
        case .book(let book):
          return (tableView.dequeueReusableCell(withIdentifier: "HomeBookCell", for: indexPath) as! HomeBookCell)
            .apply {
              $0.bind(book, indexPath.row)
              $0.delegate = self
          }
        case .loading:
          return (tableView.dequeueReusableCell(withIdentifier: "HomeLoadingCell", for: indexPath) as! HomeLoadingCell)
            .apply { $0.bind() }
        case .error(let error, let isFirstPage):
          return (tableView.dequeueReusableCell(withIdentifier: "HomeErrorCell", for: indexPath) as! HomeErrorCell)
            .apply {
              $0.delegate = self
              $0.bind(error, isFirstPage)
          }
        }
      },
      titleForHeaderInSection: { dataSource, sectionIndex in
        dataSource.sectionModels[sectionIndex].model
      }
    )

    // item selected event
    self.tableView
      .rx
      .modelSelected(HomeItem.self)
      .compactMap { item -> HomeBook? in
        if case .book(let book) = item { return book }
        return nil
      }
      .subscribe(onNext: { [weak self] book in self?.toDetailVC(with: book) })
      .disposed(by: disposeBag)

    // bind list to table view
    homeVM
      .state$
      .map { state in
        [
            .init(
              model: "Search for '\(state.searchTerm)', have \(state.books.count) books",
              items: state.items
            )
        ]
      }
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)

    // bind fav count to bagde
    homeVM
      .state$
      .map { String($0.favCount) }
      .distinctUntilChanged()
      .startWith("0")
      .drive(onNext: { [weak self] count in self?.updateBadge(with: count) })
      .disposed(by: disposeBag)

    // observe single event
    homeVM
      .singleEvent$
      .emit(onNext: { [weak self] event in self?.showSnackbar(event: event) })
      .disposed(by: disposeBag)

    // process intent
    homeVM
      .process(
        intent$: Observable.merge(
          [
            searchBar.rx
              .text
              .map { HomeIntent.search(searchTerm: $0 ?? "")
            },
            tableView.rx
              .contentOffset
              .throttle(.milliseconds(400), scheduler: MainScheduler.instance)
              .filter { [weak tableView] _ in
                tableView?.isNearBottomEdge(edgeOffset: 30) ?? false
              }
              .map { _ in HomeIntent.loadNextPage },
            intentS.asObservable(),
          ]
        )
      )
      .disposed(by: disposeBag)
  }

  func toDetailVC(with book: HomeBook) {
    guard let navController = self.navigationController else { return }

    let storyboard = SwinjectStoryboard.create(name: "Main", bundle: nil)
    let detailVC = (storyboard.instantiateViewController(withIdentifier: "DetailVC") as! DetailVC)
      .apply { $0.initialDetail = .init(fromHomeBook: book) }
    navController.pushViewController(detailVC, animated: true)
  }

  func updateBadge(with count: String) {
    self.labelFavCount?.letIt {
      $0.layer.removeAnimation(forKey: "pulse")
      $0.text = count
      let animation = CAKeyframeAnimation(keyPath: "transform.scale").apply {
        $0.values = [1.0, 1.2, 0.9, 1.0]
        $0.keyTimes = [0, 0.2, 0.4, 1]
        $0.duration = 0.8
        $0.repeatCount = 1
        $0.isRemovedOnCompletion = true
      }
      $0.layer.add(animation, forKey: "pulse")
    }
  }

  func showSnackbar(event: HomeSingleEvent) {
    print("Event=\(event)")

    let message = MDCSnackbarMessage().apply {
      $0.duration = 2
      switch event {
      case .addedToFavorited(let book):
        $0.text = "Added '\(book.title ?? "")' to favorited"
      case .removedFromFavorited(let book):
        $0.text = "Removed '\(book.title ?? "")' from favorited"
      case .loadError(let error):
        $0.text = "Loaded error: \(error.message)"
      case .toggleFavoritedError(let error, _):
        $0.text = "Toggle favorited error: \(error.message)"
      }

      $0.completionHandler = { [weak self] _ in
        if let fabY = self?.fabY, let fab = self?.fab {
          UIView.animate(withDuration: 0.3, animations: {
            fab.frame = CGRect.init(
              x: fab.frame.minX,
              y: fabY + 54,
              width: fab.frame.width,
              height: fab.frame.height)
          })
          self?.fabY = fabY + 54
        }
      }
    }

    if let fabY = self.fabY, let fab = self.fab {
      UIView.animate(withDuration: 0.3, animations: {
        fab.frame = CGRect.init(
          x: fab.frame.minX,
          y: fabY - 54,
          width: fab.frame.width,
          height: fab.frame.height)
      })
      self.fabY = fabY - 54
    }
    MDCSnackbarManager.show(message)
  }
}

// MARK: - Setup UI
private extension HomeVC {
  func addFab() {
    guard self.labelFavCount == nil else { return }

    let fabSize = CGFloat(64)
    let fabMarginBottom = CGFloat(24)
    let fabMarginRight = CGFloat(12)
    let fabY = self.view.frame.height - fabSize - self.view.safeAreaInsets.bottom - fabMarginBottom

    let frame = CGRect(
      x: self.view.frame.width - fabSize - fabMarginRight,
      y: fabY,
      width: fabSize,
      height: fabSize
    )

    let button = MDCFloatingButton.init(frame: frame).apply {
      $0.setElevation(ShadowElevation(rawValue: 8), for: .normal)
      $0.setElevation(ShadowElevation(rawValue: 12), for: .highlighted)
      $0.tintColor = .white
      $0.setImage(UIImage(named: "baseline_favorite_white_36pt"), for: .normal)
      $0.backgroundColor = Colors.tintColor
      $0.setShadowColor(UIColor.black.withAlphaComponent(0.87), for: .normal)
    }

    let labelFavCount = UILabel().apply {
      $0.frame = CGRect.init(
        x: frame.width - 32,
        y: -8,
        width: 32,
        height: 32
      )
      $0.text = "0"
      $0.textColor = .white
      $0.textAlignment = .center
      $0.font = UIFont.init(name: "Thonburi-Bold", size: 15)

      $0.clipsToBounds = true
      $0.layer.cornerRadius = 16
      $0.layer.shadowColor = UIColor.black.withAlphaComponent(0.24).cgColor
      $0.layer.shadowOpacity = 1
      $0.layer.shadowOffset = .init(width: 0, height: 10)
      $0.layer.shadowPath = UIBezierPath(rect: $0.bounds).cgPath

      $0.backgroundColor = .red
    }

    button.addSubview(labelFavCount)
    button.addTarget(self, action: #selector(tappedFabButton), for: .touchUpInside)

    self.view.addSubview(button)
    self.labelFavCount = labelFavCount
    self.fabY = fabY
    self.fab = button
  }

  @objc func tappedFabButton() {
    let storyboard = SwinjectStoryboard.create(name: "Main", bundle: nil)
    let favoritesVC = (storyboard.instantiateViewController(withIdentifier: "FavoritesVC") as! FavoritesVC)
    self.navigationController?.pushViewController(favoritesVC, animated: true)
  }
}

extension HomeVC: HomeBookCellDelegate {
  func homeBookCell(_ cell: HomeBookCell, didToggleFavorite book: HomeBook) {
    self.intentS.accept(.toggleFavorite(book: book))
  }
}

extension HomeVC: HomeErrorCellDelegate {
  func homeErrorCell(_ cell: HomeErrorCell, didTapRetry isFirstPage: Bool) {
    self.intentS.accept(
      isFirstPage
        ? .retryLoadFirstPage
        : .retryLoadNextPage
    )
  }
}

extension HomeVC: UITableViewDelegate {
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    self.cellHeights[indexPath] ?? UITableView.automaticDimension
  }
}

extension UIScrollView {
  func isNearBottomEdge(edgeOffset: CGFloat) -> Bool {
    self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
  }
}
