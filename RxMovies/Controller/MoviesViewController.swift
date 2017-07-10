//
//  MoviesViewController.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 26/06/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class MoviesViewController: UIViewController {
    
    
    // MARK: - Properties
    
    // UI
    @IBOutlet private var slider: UISlider!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var yearLabel: UILabel!
    @IBOutlet var movieCountLabel: UILabel!
    fileprivate let cellID = "MovieCell"
    // Rx
    let movies = Variable<[Movie]>([])
    fileprivate let filteredMovies = Variable<[Movie]>([])
    private let disposeBag = DisposeBag()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        // Slider stream
        let sliderInput = slider.rx.controlEvent(.valueChanged).asObservable()
            .map { Int(self.slider.value) }
            .startWith(2017)
        Observable.combineLatest(sliderInput, movies.asObservable()) { (year, movies) -> [Movie] in
            return movies.filter {
                $0.year >= year }.sorted { $0.title < $1.title }
            }
            .bindTo(filteredMovies)
            .addDisposableTo(disposeBag)
        sliderInput
            .asDriver(onErrorJustReturn: 2017)
            .map { "\($0)" }
            .drive(yearLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        // Update collectionView
        filteredMovies.asObservable()
            .bindTo(collectionView.rx.items(cellIdentifier: cellID, cellType: MovieCollectionViewCell.self)) { item, movie, cell in
                cell.configure(with: movie.posterURL)
            }
            .addDisposableTo(disposeBag)
    }
    
    
    // MARK: - Methods
    
    func configureUI() {
        slider.tintColor = Colors.primary
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        collectionView.collectionViewLayout = UICollectionViewFlowLayout(bounds: view.bounds)
    }
}
