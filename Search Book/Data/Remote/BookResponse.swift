//
//  BookResponse.swift
//  Search Book
//
//  Created by Petrus on 7/10/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

struct BooksResponse: Decodable {
  let books: [BookResponse]

  init(from decoder: Decoder) throws {
    let container = try! decoder.container(keyedBy: BooksResponseKeys.self)
    self.books = try! container.decode([BookResponse].self, forKey: .items)
  }

  enum BooksResponseKeys: String, CodingKey {
    case items
  }
}

struct BookResponse: Decodable {
  let id: String
  let title: String?
  let subtitle: String?
  let authors: [String]?
  let thumbnail: String?
  let largeImage: String?
  let description: String?
  let publishedDate: String?

  init(from decoder: Decoder) throws {
    let container = try! decoder.container(keyedBy: BookKeys.self)
    self.id = try! container.decode(String.self, forKey: .id)

    let volumeInfoContainer = try! container.nestedContainer(
      keyedBy: VolumeInfoKeys.self,
      forKey: .volumeInfo
    )

    self.title = try? volumeInfoContainer.decode(String?.self, forKey: .title)
    self.subtitle = try? volumeInfoContainer.decode(String?.self, forKey: .subtitle)
    self.description = try? volumeInfoContainer.decode(String?.self, forKey: .description)
    self.publishedDate = try? volumeInfoContainer.decode(String?.self, forKey: .publishedDate)
    self.authors = try? volumeInfoContainer.decode([String]?.self, forKey: .authors)

    let imageLinksContainer = try? volumeInfoContainer.nestedContainer(keyedBy: ImageLinksKeys.self, forKey: .imageLinks)
    self.thumbnail = try? imageLinksContainer?.decode(String?.self, forKey: .thumbnail)
    self.largeImage = try? imageLinksContainer?.decode(String?.self, forKey: .smallThumbnail)
  }

  enum BookKeys: String, CodingKey {
    case id
    case volumeInfo
  }

  enum VolumeInfoKeys: String, CodingKey {
    case authors
    case imageLinks
    case title
    case subtitle
    case description
    case publishedDate
  }

  enum ImageLinksKeys: String, CodingKey {
    case thumbnail
    case smallThumbnail
  }
}
