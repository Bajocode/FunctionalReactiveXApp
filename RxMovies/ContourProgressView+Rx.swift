//
//  ContourProgressView+Rx.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 05/07/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import ContourProgressView
import RxSwift
import RxCocoa

extension Reactive where Base: ContourProgressView {

    // Bindable sink for `progress` property
    public var progress: UIBindingObserver<Base, CGFloat> {
        return UIBindingObserver(UIElement: self.base) { progressView, progress in
            progressView.progress = progress
        }
    }

}
