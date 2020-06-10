//
//  FavoritesCell.swift
//  Search Book
//
//  Created by Petrus on 6/10/20.
//  Copyright © 2020 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit
import Kingfisher

class FavoritesCell: UITableViewCell {
  @IBOutlet weak var labelSubtitle: UILabel!
  @IBOutlet weak var labelTitle: UILabel!
  @IBOutlet weak var imageThumbnail: UIImageView!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.selectionStyle = .none
  }

  func bind(_ item: FavoritesItem) {
    self.labelTitle.text = {
      if item.isLoading {
        return "Loading..."
      }
      if let error = item.error {
        return "Error: \(error.message)"
      }
      return item.title ?? "N/A"
    }()

    self.labelSubtitle.text = {
      if item.isLoading {
        return "Loading..."
      }
      if let error = item.error {
        return "Error: \(error.message)"
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
