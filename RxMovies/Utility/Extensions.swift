//
//  Extensions.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 09/07/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import UIKit

extension UICollectionViewFlowLayout {
    convenience init(bounds: CGRect) {
        self.init()
        let width = (bounds.width - 10) / 4
        self.itemSize = CGSize(width: width, height: width*1.5)
        sectionInset = UIEdgeInsets(
            top: 0,
            left: 2,
            bottom: 0,
            right: 2
        )
        minimumInteritemSpacing = 2
        minimumLineSpacing = 2
    }
}
