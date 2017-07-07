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
        slider.tintColor = Colors.primary
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        collectionView.dataSource = self; collectionView.delegate = self
        
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
        
        subscribeUIRefreshToNewData()
    }
    
    
    // MARK: - Methods
    
    private func subscribeUIRefreshToNewData() {
        // Update tableView everytime movies gets a new value
        filteredMovies.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.movieCountLabel.text = "\(self?.filteredMovies.value.count ?? 0) Movies"
                self?.collectionView.reloadData()
            })
            .addDisposableTo(disposeBag)
    }
}


// MARK: - CollectionView Datasource

extension MoviesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredMovies.value.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! MovieCollectionViewCell
        cell.configure(with: filteredMovies.value[indexPath.row].posterURL)
        return cell
    }
}


// MARK: - CollectionView Layout

extension MoviesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.bounds.width - 10) / 4
        return CGSize(width: width, height: width*1.5)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
    }
}
