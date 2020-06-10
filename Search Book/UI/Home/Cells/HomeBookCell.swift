//
//  HomeBookCell.swift
//  Search Book
//
//  Created by Petrus on 6/9/20.
//  Copyright © 2020 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit
import Kingfisher

protocol HomeBookCellDelegate: AnyObject {
  func homeBookCell(_ cell: HomeBookCell, didToggleFavorite book: HomeBook)
}

class HomeBookCell: UITableViewCell {
  @IBOutlet weak var imageThumbnail: UIImageView!
  @IBOutlet weak var labelTitle: UILabel!
  @IBOutlet weak var labelSubtitle: UILabel!
  @IBOutlet weak var imageFav: UIImageView!

  weak var delegate: HomeBookCellDelegate?
  private var book: HomeBook?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.selectionStyle = .none

    self.imageFav.letIt {
      $0.tintColor = Colors.tintColor
      $0.isUserInteractionEnabled = true
      $0.addGestureRecognizer(
        UITapGestureRecognizer(
          target: self,
          action: #selector(tappedImageFav)
        )
      )
    }

  }

  @objc private func tappedImageFav() {
    if let book = self.book {
      self.delegate?.homeBookCell(self, didToggleFavorite: book)
    }
  }

  func bind(_ book: HomeBook, _ row: Int) {
    self.book = book

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

    let newImage = book.isFavorited.flatMap { isFavorited -> UIImage? in
      isFavorited
        ? UIImage(named: "baseline_favorite_white_36pt")
        : UIImage(named: "baseline_favorite_border_white_36pt")
    }
    UIView.transition(
      with: self.imageFav,
      duration: 0.4,
      options: .transitionCrossDissolve,
      animations: { self.imageFav.image = newImage }
    )
  }
}
