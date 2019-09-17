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
        self.labelTitle.text = "\(row + 1). \(title)"


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

class FavoritesVC: UIViewController {
    var favoritesVM: FavoritesVM!
    private let disposeBag = DisposeBag.init()

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let items$ = self.favoritesVM
            .state$
            .map { $0.books ?? [] }
            .distinctUntilChanged()


        items$
            .drive(self.tableView.rx.items(cellIdentifier: "favorites_cell", cellType: FavoritesCell.self)) { row, item, cell in
                cell.bind(item, at: row)
            }
            .disposed(by: self.disposeBag)



        self.favoritesVM
            .process(intent$: .merge([
                    self.tableView
                        .rx
                        .itemDeleted
                        .withLatestFrom(items$) { indexPath, items in
                            items[indexPath.row]
                        }
                        .map { .removeFavorite($0) }
                    ]))
            .disposed(by: self.disposeBag)
    }

    deinit {
        print("FavoritesVC::deinit")
    }
}
