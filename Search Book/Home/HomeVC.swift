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

let api = BookApi()
let bookRepo = BookRepositoryImpl(bookApi: api)
let homeInteractor = HomeInteractorImpl(bookRepository: bookRepo)

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
        .asObservable()
            .bind(to: self.tableView.rx.items("home_cell", dataSource: <#T##DataSource##DataSource#>)) { (_, result, cell) in
                cell.textLabel?.text = "\(result)"
            }

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

