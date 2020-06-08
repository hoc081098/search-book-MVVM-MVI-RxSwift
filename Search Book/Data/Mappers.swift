//
// Created by HOANG TAN DUY on 9/3/19.
// Copyright (c) 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

func toBookDomain(from response: BookResponse) -> Book {
  return Book(
    id: response.id,
    title: response.title,
    subtitle: response.subtitle,
    authors: response.authors,
    thumbnail: response.thumbnail,
    largeImage: response.largeImage,
    description: response.description,
    publishedDate: response.publishedDate
  )
}
