//
//  String+Extension.swift
//  Search Book
//
//  Created by Petrus on 9/12/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation
import UIKit

extension String {
  var htmlToAttributedString: NSAttributedString? {
    guard let data = data(using: .utf8) else { return NSAttributedString() }
    do {
      return try NSAttributedString(
        data: data,
        options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ],
        documentAttributes: nil
      )
    } catch {
      return NSAttributedString()
    }
  }
  var htmlToString: String {
    htmlToAttributedString?.string ?? ""
  }
}


extension NSMutableAttributedString {

  func with(font: UIFont) -> NSAttributedString {
    self.enumerateAttribute(NSAttributedString.Key.font, in: NSMakeRange(0, self.length), options: .longestEffectiveRangeNotRequired, using: { (value, range, stop) in
      let originalFont = value as! UIFont
      if let newFont = applyTraitsFromFont(originalFont, to: font) {
        self.addAttribute(NSAttributedString.Key.font, value: newFont, range: range)
      }
    })
    return self
  }

  func applyTraitsFromFont(_ f1: UIFont, to f2: UIFont) -> UIFont? {
    let originalTrait = f1.fontDescriptor.symbolicTraits

    if originalTrait.contains(.traitBold) {
      var traits = f2.fontDescriptor.symbolicTraits
      traits.insert(.traitBold)
      if let fd = f2.fontDescriptor.withSymbolicTraits(traits) {
        return UIFont.init(descriptor: fd, size: 0)
      }
    }
    return f2
  }
}
