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
import MaterialComponents.MaterialSnackbar
import SwinjectStoryboard
import Swinject
import MaterialComponents.MaterialButtons

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

        let newImage = book.isFavorited.flatMap { (fav: Bool) -> UIImage? in
            return fav ? UIImage(named: "baseline_favorite_white_36pt") : UIImage(named: "baseline_favorite_border_white_36pt")
        }
        UIView.transition(
            with: self.imageFav,
            duration: 0.4,
            options: .transitionCrossDissolve,
            animations: { self.imageFav.image = newImage })
    }
}

class HomeVC: UIViewController {
    var homeVM: HomeVM!


    private let disposeBag = DisposeBag()
    private let intentS = PublishRelay<HomeIntent>()

    @IBOutlet weak var tableView: UITableView!
    private var fabY: CGFloat?
    private weak var fab: MDCFloatingButton?
    private weak var labelFavCount: UILabel?

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.addFab()
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
            .compactMap { (item: HomeItem) -> HomeBook? in
                if case .book(let book) = item {
                    return book
                } else {
                    return nil
                }
            }
            .subscribe(onNext: { book in
                let storyboard = SwinjectStoryboard.create(name: "Main", bundle: nil)
                let detailVC = (storyboard.instantiateViewController(withIdentifier: "DetailVC") as! DetailVC)
                    .apply { $0.initialDetail = .init(fromHomeBook: book) }
                self.navigationController?.pushViewController(detailVC, animated: true)
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
            .state$
            .map { String($0.favCount) }
            .distinctUntilChanged()
            .startWith("0")
            .drive(onNext: { count in
                let animation = CAKeyframeAnimation(keyPath: "transform.scale").apply {
                    $0.values = [1.0, 1.2, 0.9, 1.0]
                    $0.keyTimes = [0, 0.2, 0.4, 1]
                    $0.duration = 0.8
                    $0.repeatCount = 1
                    $0.isRemovedOnCompletion = true
                }

                self.labelFavCount.map {
                    $0.layer.removeAnimation(forKey: "pulse")
                    $0.text = count
                    $0.layer.add(animation, forKey: "pulse")
                }
            })
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

                    $0.completionHandler = { _ in
                        if let fabY = self.fabY, let fab = self.fab {
                            UIView.animate(withDuration: 0.3, animations: {
                                fab.frame = CGRect.init(
                                    x: fab.frame.minX,
                                    y: fabY + 54,
                                    width: fab.frame.width,
                                    height: fab.frame.height)
                            })
                            self.fabY = fabY + 54
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
                        .throttle(.milliseconds(400), scheduler: MainScheduler.instance)
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

    @objc private func tappedFabButton() {
        let storyboard = SwinjectStoryboard.create(name: "Main", bundle: nil)
        let favoritesVC = (storyboard.instantiateViewController(withIdentifier: "FavoritesVC") as! FavoritesVC)
        self.navigationController?.pushViewController(favoritesVC, animated: true)
    }
}

extension UIScrollView {
    func isNearBottomEdge(edgeOffset: CGFloat) -> Bool {
        return self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
    }
}
