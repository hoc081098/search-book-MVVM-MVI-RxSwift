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
import RxDataSources

let api = BookApi()
let bookRepo = BookRepositoryImpl(bookApi: api)
let homeInteractor = HomeInteractorImpl(bookRepository: bookRepo)

class LoadingCell: UITableViewCell {
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    func bind() {
        indicator.startAnimating()
    }
}

class ErrorCell: UITableViewCell {
    var tapped: (() -> Void)?

    @IBAction func tappedRetry(_ sender: Any) {
        tapped?()
    }
    @IBOutlet weak var lableError: UILabel!

    func bind(_ error: HomeError) {
        switch error {
        case .networkError:
            self.lableError.text = "Network error"
        case .serverResponseError(_, let message):
            self.lableError.text = "Server response error: \(message)"
        case .unexpectedError:
            self.lableError.text = "An unexpected error"
        }
    }
}

class HomeCell: UITableViewCell {
    @IBOutlet weak var imageThumbnail: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubtitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func bind(_ book: HomeBook, _ row: Int) {
        let url = URL.init(string: book.thumbnail ?? "")

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

        self.labelTitle.text = "\(row) - \(book.title ?? "No title")"
        self.labelSubtitle.text = book.subtitle ?? "No subtitle"
    }
}

class HomeVC: UIViewController {
    private let homeVM = HomeVM(homeInteractor: homeInteractor)
    private var disposeBag = DisposeBag()
    private let retryS = PublishRelay<HomeIntent>()

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

        bindVM()
    }

    private func bindVM() {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, HomeItem>>(
            configureCell: { dataSource, tableView, indexPath, item in
                switch item {
                case .book(let book):
                    let cell = tableView.dequeueReusableCell(withIdentifier: "home_cell", for: indexPath) as! HomeCell
                    cell.bind(book, indexPath.row)
                    return cell
                case .loading:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "loading_cell", for: indexPath) as! LoadingCell
                    cell.bind()
                    return cell
                case .error(let error, let isFirstPage):
                    let cell = tableView.dequeueReusableCell(withIdentifier: "error_cell", for: indexPath) as! ErrorCell
                    cell.tapped = { [weak self] in
                        self?.retryS.accept(
                            isFirstPage
                                ? .retryLoadFirstPage
                                : .retryLoadNextPage
                        )
                    }
                    cell.bind(error)
                    return cell
                }
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource.sectionModels[sectionIndex].model
            }
        )

        homeVM
            .state$
            .map { state in
                return [
                    SectionModel(
                        model: "Search for '\(state.searchTerm)', have \(state.books.count) books",
                        items: state.items
                    )
                ]
            }
            .drive(self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        homeVM
            .process(
                intent$: Observable.merge([
                    searchBar.rx
                        .text
                        .asObservable()
                        .map { HomeIntent.search(searchTerm: $0 ?? "")
                    },
                    tableView.rx
                        .contentOffset
                        .asObservable()
                        .throttle(0.4, scheduler: MainScheduler.instance)
                        .filter { _ in
                            self.tableView.isNearBottomEdge(edgeOffset: 50)
                        }
                        .map { _ in HomeIntent.loadNextPage },
                    retryS.asObservable()
                    ]
                )
            )
            .disposed(by: disposeBag)
    }

    deinit {
        disposeBag = DisposeBag()
    }
}

extension UIScrollView {
    func isNearBottomEdge(edgeOffset: CGFloat) -> Bool {
        return self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
    }
}
