//
//  DetailVC.swift
//  Search Book
//
//  Created by HOANG TAN DUY on 9/9/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DetailVC: UIViewController {
    var detailVM: DetailVM!
    var initialDetail: InitialBookDetail!

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.bindVM()
    }

    private func bindVM() {
        self.detailVM
            .state$
            .drive(onNext: { state in
                print("State=\(state)")
            })
            .disposed(by: self.disposeBag)

        self.detailVM
            .process(intent$: .just(.initial(initialDetail)))
            .disposed(by: disposeBag)
    }
}
