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
import Kingfisher

class DetailVC: UIViewController {
    var detailVM: DetailVM!
    var initialDetail: InitialBookDetail!

    private let disposeBag = DisposeBag()

    @IBOutlet weak var imageLarge: UIImageView!
    @IBOutlet weak var bottomView: UIView!

    @IBOutlet weak var imageThumbnail: UIImageView!
    @IBOutlet weak var cardView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cardView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.cardView.layer.cornerRadius = 12
        self.cardView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.cardView.layer.shadowOpacity = 1
        self.cardView.layer.shadowOffset = .init(width: 0, height: 10)
        self.cardView.layer.shadowRadius = 10
        self.cardView.layer.shadowPath = UIBezierPath(rect: self.cardView.bounds).cgPath
        
        let color = self.view.backgroundColor!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let gradientLayer = CAGradientLayer().apply {
                $0.colors = [
                    color.withAlphaComponent(0),
                    color
                ].map { $0.cgColor }
                $0.startPoint = CGPoint(x: 0, y: 0)
                $0.endPoint = CGPoint(x: 0, y: 1)
                $0.locations = [0.1, 0.9]
                $0.frame = self.bottomView.bounds
                $0.repeatCount = 1
            }

            self.bottomView.layer.insertSublayer(gradientLayer, at: 0)
        }

        self.bindVM()
    }

    override func viewDidLayoutSubviews() {


    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }


    private func bindVM() {
        self.detailVM
            .state$
            .drive(onNext: self.render)
            .disposed(by: self.disposeBag)

        self.detailVM
            .process(intent$: .just(.initial(initialDetail)))
            .disposed(by: disposeBag)
    }

    fileprivate func loadLargeImage(_ vs: DetailViewState) {
        let url = URL.init(string: vs.detail?.largeImage ?? "")
        
        let processor = DownsamplingImageProcessor(size: self.imageLarge.frame.size)
        
        self.imageLarge.kf.indicatorType = .activity
        self.imageLarge.kf.setImage(
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
    
    fileprivate func loadThumbnailImage(_ vs: DetailViewState) {
        let url = URL.init(string: vs.detail?.thumbnail ?? "")
        
        let processor = DownsamplingImageProcessor(size: self.imageThumbnail.frame.size) >> RoundCornerImageProcessor(cornerRadius: 12)
        
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
    
    private func render(_ vs: DetailViewState) {
        loadLargeImage(vs)
        loadThumbnailImage(vs)
    }
}
