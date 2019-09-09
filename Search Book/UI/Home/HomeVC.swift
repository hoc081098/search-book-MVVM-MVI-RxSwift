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
import RxSwiftExt
import MaterialComponents.MaterialSnackbar

let api = BookApi()
let bookRepo = BookRepositoryImpl(bookApi: api)
let favoritedBooksRepo = FavoritedBooksRepositoryImpl(userDefaults: UserDefaults.standard)
let homeInteractor = HomeInteractorImpl(
    bookRepository: bookRepo,
    favoritedBooksRepository: favoritedBooksRepo
)

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
    @IBOutlet weak var imageFav: UIImageView!

    var tapImageFav: (() -> ())?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none

        self.imageFav.letIt {
            $0.tintColor = Colors.tintColor
            $0.isUserInteractionEnabled = true
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedImageFav)))
        }

    }

    @objc func tappedImageFav() {
        self.tapImageFav?()
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
        
        self.imageFav.image = book.isFavorited.flatMap { (fav: Bool) -> UIImage? in
            return fav ? UIImage(named: "baseline_favorite_white_36pt") : UIImage(named: "baseline_favorite_border_white_36pt")
        }
    }
}

class HomeVC: UIViewController {
    private let homeVM = HomeVM(homeInteractor: homeInteractor)
    private let disposeBag = DisposeBag()
    private let intentS = PublishRelay<HomeIntent>()

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
        self.tableView.estimatedRowHeight = 104
        self.tableView.rowHeight = UITableView.automaticDimension

        bindVM()
    }

    private func bindVM() {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, HomeItem>>(
            configureCell: { dataSource, tableView, indexPath, item in
                switch item {
                case .book(let book):
                    return (tableView.dequeueReusableCell(withIdentifier: "home_cell", for: indexPath) as! HomeCell).apply {
                        $0.bind(book, indexPath.row)
                        $0.tapImageFav = { [weak self] in
                            self?.intentS.accept(.toggleFavorite(book: book))
                        }
                    }
                case .loading:
                    return (tableView.dequeueReusableCell(withIdentifier: "loading_cell", for: indexPath) as! LoadingCell).apply {
                        $0.bind()
                    }
                case .error(let error, let isFirstPage):
                    return (tableView.dequeueReusableCell(withIdentifier: "error_cell", for: indexPath) as! ErrorCell).apply {
                        $0.tapped = { [weak self] in
                            self?.intentS.accept(
                                isFirstPage
                                    ? .retryLoadFirstPage
                                    : .retryLoadNextPage
                            )
                        }
                        $0.bind(error)
                    }
                }
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource.sectionModels[sectionIndex].model
            }
        )

        self.tableView.rx
            .itemSelected
            .map { (indexPath: IndexPath) -> HomeItem in
                let section = dataSource.sectionModels[indexPath.section]
                return section.items[indexPath.row]
            }
            .filterMap { (item: HomeItem) -> FilterMap<HomeBook> in
                if case .book(let book) = item {
                    return .map(book)
                } else {
                    return .ignore
                }
            }
            .subscribe(onNext: { book in
                if let detailVC = self.storyboard?.instantiateViewController(withIdentifier: "DetailVC") {
                    self.navigationController?.pushViewController(detailVC, animated: true)
                }
            })
            .disposed(by: disposeBag)


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
            .singleEvent$
            .emit(onNext: { event in
                print("Event=\(event)")
                
                let message = MDCSnackbarMessage().apply {
                    $0.duration = 2
                    switch event {
                    case .addedToFavorited(let book):
                        $0.text = "Added '\(book.title ?? "")' to favorited"
                    case .removedFromFavorited(let book):
                        $0.text = "Removed '\(book.title ?? "")' from favorited"
                    case .loadError(let error):
                        let errorMessage: String
                        
                        switch error {
                        case .networkError:
                            errorMessage = "Network error"
                        case .serverResponseError(_, let message):
                            errorMessage = "Server response error: \(message)"
                        case .unexpectedError:
                            errorMessage = "Unexpected error"
                        }
                        
                        $0.text = "Loaded error: \(errorMessage)"
                    }
                }
                MDCSnackbarManager.show(message)
            })
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
                            self.tableView.isNearBottomEdge(edgeOffset: 30)
                        }
                        .map { _ in HomeIntent.loadNextPage },
                    intentS.asObservable()
                    ]
                )
            )
            .disposed(by: disposeBag)
    }
}

extension UIScrollView {
    func isNearBottomEdge(edgeOffset: CGFloat) -> Bool {
        return self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
    }
}
