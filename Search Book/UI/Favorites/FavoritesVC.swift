//
//  FavoritesVC.swift
//  Search Book
//
//  Created by Petrus on 9/12/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import MaterialComponents.MaterialSnackbar
import SwinjectStoryboard
import RxDataSources

class FavoritesVC: UIViewController {
  var favoritesVM: FavoritesVM!
  private let disposeBag = DisposeBag.init()

  // MARK: - Views

  @IBOutlet weak var tableView: UITableView!
  private weak var refreshControl: UIRefreshControl!

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupUI()
    self.bindVM()
  }

  deinit {
    print("FavoritesVC::deinit")
  }
}

// MARK: - Bind VM
private extension FavoritesVC {
  func bindVM() {
    // table view data source
    let dataSource = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, FavoritesItem>>(
      configureCell: {
        dataSource, tableView, indexPath, item -> UITableViewCell in
        (tableView.dequeueReusableCell(withIdentifier: "FavoritesCell", for: indexPath) as! FavoritesCell)
          .apply { $0.bind(item) }
      },
      canEditRowAtIndexPath: { _, _ in true }
    )


    self.favoritesVM
      .state$
      .map { $0.books ?? [] }
      .distinctUntilChanged()
      .map { [AnimatableSectionModel.init(model: "", items: $0)] }
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: self.disposeBag)

    // table view item selected
    self.tableView
      .rx
      .modelSelected(FavoritesItem.self)
      .subscribe(onNext: { [weak self] item in self?.toDetailVC(with: item) })
      .disposed(by: self.disposeBag)

    // hide refreshControl when refresh done
    self.favoritesVM
      .state$
      .map { $0.isRefreshing }
      .filter { !$0 }
      .drive(onNext: { [weak refreshControl]_ in refreshControl?.endRefreshing() })
      .disposed(by: self.disposeBag)

    // observe single event
    self.favoritesVM
      .singleEvent$
      .emit(onNext: FavoritesVC.showSnackbar)
      .disposed(by: self.disposeBag)

    // process intents
    self.favoritesVM
      .process(
        intent$: .merge(
          [
            self.tableView
              .rx
              .modelDeleted(FavoritesItem.self)
              .map { .removeFavorite($0) },
            self.refreshControl
              .rx
              .controlEvent(.valueChanged)
              .map { .refresh },
          ]
        )
      )
      .disposed(by: self.disposeBag)
  }

  static func showSnackbar(event: FavoritesSingleEvent) {
    let snackbarMessage = MDCSnackbarMessage.init()

    switch event {
    case .removedFromFavorites(let item):
      snackbarMessage.text = "Removed '\(item.title ?? "N/A")' from favorites"
    case .removeFromFavoritesError(let item):
      snackbarMessage.text = "Error when remove '\(item.title ?? "N/A")' from favorites"
    }

    MDCSnackbarManager.show(snackbarMessage)
  }

  func toDetailVC(with item: FavoritesItem) {
    guard let navController = navigationController else { return }

    let storyboard = SwinjectStoryboard.create(name: "Main", bundle: nil)
    let detailVC = (storyboard.instantiateViewController(withIdentifier: "DetailVC") as! DetailVC)
      .apply { $0.initialDetail = .init(fromFavoritesItem: item) }
    navController.pushViewController(detailVC, animated: true)
  }
}

// MARK: - Setup UI
private extension FavoritesVC {
  func setupUI() {
    self.title = "Favorite"
    let refreshControl = UIRefreshControl.init().apply {
      let attributes = [
        NSAttributedString.Key.font: UIFont.init(name: "Thonburi", size: 15)!,
        NSAttributedString.Key.foregroundColor: UIColor.black
      ]
      $0.attributedTitle = NSAttributedString.init(
        string: "Refreshing...",
        attributes: attributes
      )
    }
    self.tableView.refreshControl = refreshControl
    self.refreshControl = refreshControl
  }
}
