//
//  Colors.swift
//  Search Book
//
//  Created by Petrus Nguyễn Thái Học on 9/9/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit

struct Colors {
  static let tintColor = UIColor(red: 0.94235390419999998, green: 0.4128730893, blue: 0.3355879188, alpha: 1)
  static let primaryColor = UIColor(red: 0.94235390419999998, green: 0.22753895094384929, blue: 0.16387807691504297, alpha: 1)
}

extension UIColor {
  convenience init(red: Int, green: Int, blue: Int) {
    assert(red >= 0 && red <= 255, "Invalid red component")
    assert(green >= 0 && green <= 255, "Invalid green component")
    assert(blue >= 0 && blue <= 255, "Invalid blue component")

    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
  }

  convenience init(rgb: Int) {
    self.init(
      red: (rgb >> 16) & 0xFF,
      green: (rgb >> 8) & 0xFF,
      blue: rgb & 0xFF
    )
  }
}
