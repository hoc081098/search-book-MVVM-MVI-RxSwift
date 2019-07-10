//
//  HomeVM.swift
//  Search Book
//
//  Created by Petrus on 7/8/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import Foundation

class HomeVM : BaseVM<HomeIntent, HomeViewState, HomeSingleEvent> {
    init() {
        super.init(initialState: HomeViewState())
    }
}
