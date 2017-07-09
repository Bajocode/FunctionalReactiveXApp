//
//  SearchViewController.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 09/07/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import UIKit
import RxSwift

var searchCache = [String: [Movie]]() {
    didSet {
        print(searchCache.keys)
    }
}
class SearchViewController: UICollectionViewController {
    
    
    // MARK: - Properties
    
    fileprivate let cellID = "MovieCell"
    let searchController = UISearchController(searchResultsController: nil)
    let bag = DisposeBag()
    var movies = [Movie]()
    let search = BehaviorSubject(value: "")
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        search
            .throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { query -> Observable<[Movie]> in
                return TmdbService.movies(forSearchText: query).catchErrorJustReturn([Movie]())
            }
            .cache(key: try! search.value() )
            .catchError { error in
                if let cachedResults = searchCache[try! self.search.value()] {
                    return Observable.just(cachedResults)
                } else {
                    return Observable.just([])
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { result in
                self.movies = result
                self.collectionView?.reloadSections(IndexSet(integer: 0))
            })
            .addDisposableTo(bag)
    }

    
    // MARK: - Methods
    
    func configureUI() {
        collectionView!.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        collectionView?.backgroundColor = .white
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(cancelButtonPressed))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    
    // MARK: - Actions
    
    func cancelButtonPressed() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return movies.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! MovieCollectionViewCell
        cell.backgroundColor = .white
        cell.configure(with: movies[indexPath.row].posterURL)
        return cell
    }
}


// MARK: - SearchResultsUpdating

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        search.onNext(searchController.searchBar.text ?? "")
    }
}


extension ObservableType where E == Array<Movie> {
    func cache(key: String) -> Observable<E> {
        return self.observeOn(MainScheduler.instance).do(onNext: { movies in
            searchCache[key] = movies
        })
    }
}
