//
//  LoadingCell.swift
//  Search Book
//
//  Created by Petrus on 6/9/20.
//  Copyright © 2020 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit

class HomeLoadingCell: UITableViewCell {
  @IBOutlet weak var indicator: UIActivityIndicatorView!

  func bind() { indicator.startAnimating() }
}
