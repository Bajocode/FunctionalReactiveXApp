//
//  MoviesViewController.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 26/06/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class MoviesViewController: UIViewController {
    
    
    // MARK: - Properties
    
    let movies = Variable<[Movie]>([])
    fileprivate let filteredMovies = Variable<[Movie]>([])
    private let year = Variable<Int>(2017)
    fileprivate let cellID = "MovieCell"
    private let disposeBag = DisposeBag()
    @IBOutlet private var slider: UISlider!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var yearLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TableView
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        collectionView.dataSource = self
        
        // Rx stream
        subscribeUIRefreshToNewData()
        bindYearFilter()
    }
    
    
    // MARK: - Methods
    
    private func subscribeUIRefreshToNewData() {
        // Update tableView everytime movies gets a new value
        filteredMovies.asObservable()
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    private func bindYearFilter() {
        // Filter with minimum movie year treshHold
        Observable.combineLatest(year.asObservable(), movies.asObservable()) { (year, movies) -> [Movie] in
            return movies.filter {
                $0.year >= year }.sorted { $0.title < $1.title }
            }
            .bindTo(filteredMovies)
            .addDisposableTo(disposeBag)
    }
    
    
    // MARK: - Actions
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        year.value = Int(sender.value)
        yearLabel.text = "\(year.value)"
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

extension MoviesViewController
