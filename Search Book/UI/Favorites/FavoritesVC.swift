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
import Kingfisher
import MaterialComponents.MaterialSnackbar
import SwinjectStoryboard

// MARK: - FavoritesCell

private func getMessage(from error: FavoritesError) -> String {
  switch error {
  case .networkError:
    return "Network error"
  case .serverResponseError(_, let message):
    return "Response error: \(message)"
  case .unexpectedError:
    return "Unexpected error"
  }
}

class FavoritesCell: UITableViewCell {
  @IBOutlet weak var labelSubtitle: UILabel!
  @IBOutlet weak var labelTitle: UILabel!
  @IBOutlet weak var imageThumbnail: UIImageView!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.selectionStyle = .none
  }

  func bind(_ item: FavoritesItem, at row: Int) {
    let title: String = {
      if item.isLoading {
        return "Loading..."
      }
      if let error = item.error {
        return "Error: \(getMessage(from: error))"
      }
      return item.title ?? "N/A"
    }()
    self.labelTitle.text = "\(row + 1) - \(title)"


    self.labelSubtitle.text = {
      if item.isLoading {
        return "Loading..."
      }
      if let error = item.error {
        return "Error: \(getMessage(from: error))"
      }
      return item.subtitle ?? "N/A"
    }()


    let url = URL.init(string: item.thumbnail ?? "")

    let processor = DownsamplingImageProcessor(size: self.imageThumbnail.frame.size)
    >> RoundCornerImageProcessor(cornerRadius: 8)

    self.imageThumbnail.kf.indicatorType = .activity
    self.imageThumbnail.kf.setImage(
      with: url,
      placeholder: UIImage.init(named: "no_image.png"),
      options: [
          .processor(processor),
          .scaleFactor(UIScreen.main.scale),
          .transition(.fade(1)),
          .cacheOriginalImage
      ]
    )
  }
}

// MARK: - FavoritesVC

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
    let items$ = self.favoritesVM
      .state$
      .map { $0.books ?? [] }
      .distinctUntilChanged()

    // table view data source
    items$
      .drive(self.tableView.rx.items(cellIdentifier: "favorites_cell", cellType: FavoritesCell.self)) { row, item, cell in
        cell.bind(item, at: row)
      }
      .disposed(by: self.disposeBag)

    // table view item selected
    self.tableView
      .rx
      .itemSelected
      .withLatestFrom(items$) { indexPath, items in items[indexPath.row] }
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
        intent$: .merge([
          self.tableView
            .rx
            .itemDeleted
            .withLatestFrom(items$) { indexPath, items in
              items[indexPath.row]
            }
            .map { .removeFavorite($0) },
          self.refreshControl
            .rx
            .controlEvent(.valueChanged)
            .map { .refresh }
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
