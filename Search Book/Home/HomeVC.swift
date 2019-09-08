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
import Kingfisher

let api = BookApi()
let bookRepo = BookRepositoryImpl(bookApi: api)
let homeInteractor = HomeInteractorImpl(bookRepository: bookRepo)

class HomeCell: UITableViewCell {
    @IBOutlet weak var imageThumbnail: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubtitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func bind(_ item: HomeBookItem) {
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

        self.labelTitle.text = item.title
        self.labelSubtitle.text = item.subtitle ?? "No subtitle"
    }
}

class HomeVC: UIViewController {
    private let homeVM = HomeVM(homeInteractor: homeInteractor)
    private var disposeBag = DisposeBag()

    @IBOutlet weak var tableView: UITableView!

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.placeholder = "Search book"
        searchBar.sizeToFit()
        return searchBar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.titleView = searchBar
    }

    override func viewWillAppear(_ animated: Bool) {
        homeVM
            .state$
            .map { $0.books }
            .drive(self.tableView.rx.items(cellIdentifier: "home_cell", cellType: HomeCell.self)) { row, item, cell in
                cell.bind(item)
            }
            .disposed(by: disposeBag)

        homeVM
            .process(intent$: searchBar.rx.text.asObservable().map {
                    HomeIntent.search(searchTerm: $0 ?? "")
                })
            .disposed(by: disposeBag)
    }

    override func viewDidDisappear(_ animated: Bool) {
        disposeBag = DisposeBag()
    }
}

