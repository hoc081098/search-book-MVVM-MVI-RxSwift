//
//  HomeErrorCell.swift
//  Search Book
//
//  Created by Petrus on 6/9/20.
//  Copyright © 2020 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit

protocol HomeErrorCellDelegate: AnyObject {
  func homeErrorCell(_ cell: HomeErrorCell, didTapRetry isFirstPage: Bool)
}

class HomeErrorCell: UITableViewCell {
  @IBOutlet weak var lableError: UILabel!
  @IBAction func tappedRetry(_ sender: Any) {
    if let isFirstPage = self.isFirstPage {
      self.delegate?.homeErrorCell(self, didTapRetry: isFirstPage)
    }
  }

  weak var delegate: HomeErrorCellDelegate?
  private var isFirstPage: Bool?

  func bind(_ error: AppError, _ isFirstPage: Bool) {
    self.isFirstPage = isFirstPage
    self.lableError.text = error.message
  }
}
