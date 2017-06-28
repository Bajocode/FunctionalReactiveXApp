//
//  GenresViewController.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 26/06/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class GenresViewController: UIViewController {
    
    // MARK: - Properties
    
    // UI
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.dataSource = self; tv.delegate = self
        tv.separatorStyle = .none
        tv.rowHeight = 64
        tv.frame = self.view.bounds
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")
        return tv
    }()
    // Rx
    fileprivate let genres = Variable<[Genre]>([])
    private let disposeBag = DisposeBag()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        
        // Update TableView everytime genres gets a new value
        genres
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            })
            .addDisposableTo(disposeBag)
        
        // Bind
        startDownload()
    }
    
    
    // MARK: - Methods
    
    // Fetch genres and movies and combine the genres in one observable
    private func startDownload() {
        // Fetch genres and fetch acompanies movies
        let genresObs = TmdbService.genres
        let moviesObs = TmdbService.popularMovies()
        let genresWithMovies = Observable.combineLatest(genresObs, moviesObs) { (genres, movies) -> [Genre] in
            // CLosure executes with latest genres array from genres and movies Observable
            return genres.map { genre in
                var genreCopy = genre
                genreCopy.movies = movies.filter { $0.genres.contains(genre.id) }
                return genreCopy
            }
        }
        // Bind items from the genres observable and genres from the genresWithMovies observable.
        genresObs
            .concat(genresWithMovies)
            .bindTo(genres)
            .addDisposableTo(disposeBag)
    }
}


// MARK: - Tableview Delegate

extension GenresViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedGenre = genres.value[indexPath.row]
        if !selectedGenre.movies.isEmpty {
            let moviesVC = MoviesViewController()
            moviesVC.title = selectedGenre.name
            moviesVC.movies.value = selectedGenre.movies
            navigationController?.pushViewController(moviesVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


// MARK: - Tableview Datasource

extension GenresViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return genres.value.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)
        let genre = genres.value[indexPath.row]
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline).withSize(25)
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.text = "\(genre.name) (\(genre.movies.count))".uppercased()
        cell.textLabel?.textColor = genre.movies.isEmpty ? .lightGray : .black
        return cell
    }
}
