//
//  FavoritesVC.swift
//  Search Book
//
//  Created by Petrus on 9/12/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit
import RxCocoa

class FavoritesVC: UIViewController {
    var favoritesVM: FavoritesVM!

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.favoritesVM
            .state$
            .map { $0.books ?? [] }
            .distinctUntilChanged()
            .drive(self.tableView.rx.items(cellIdentifier: "favorites_cell", cellType: UITableViewCell.self)) { row, item, cell in
                cell.textLabel?.text = {
                    if item.isLoading {
                        return "Loading..."
                    }
                    if let error = item.error {
                        return "Error: \(error)"
                    }
                    return item.title ?? "N/A"
                }()
        }
    }
}
