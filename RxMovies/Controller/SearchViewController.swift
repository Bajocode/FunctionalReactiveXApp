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
    let disposeBag = DisposeBag()
    var movies = [Movie]()
    let search = BehaviorSubject(value: "")
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        // Configure search result stream
        let result = search
            .throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { query -> Observable<[Movie]> in
                return TmdbService.movies(forSearchText: query).catchErrorJustReturn([Movie]())
            }
            .cache(key: try! search.value() )
            .catchError { error in
                // Recover form error with cached result, if any
                if let cachedResults = searchCache[try! self.search.value()] {
                    return Observable.just(cachedResults)
                } else {
                    return Observable.just([])
                }
            }
        
        // Update collectionView
        result
            .bindTo(collectionView!.rx.items(cellIdentifier: cellID, cellType: MovieCollectionViewCell.self)) { item, movie, cell in
                cell.configure(with: movie.posterURL)
            }
            .addDisposableTo(disposeBag)
    }

    
    // MARK: - Methods
    
    func configureUI() {
        collectionView!.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        collectionView?.backgroundColor = .white
        collectionView?.delegate = nil; collectionView?.dataSource = nil
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
}


// MARK: - SearchResultsUpdating

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        search.onNext(searchController.searchBar.text ?? "")
    }
}


// MARK: - Caching 

extension ObservableType where E == Array<Movie> {
    func cache(key: String) -> Observable<E> {
        return self.observeOn(MainScheduler.instance).do(onNext: { movies in
            searchCache[key] = movies
        })
    }
}
