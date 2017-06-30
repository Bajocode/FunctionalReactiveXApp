//
//  GenresViewController.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 26/06/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ContourProgressView

final class GenresViewController: UIViewController {
    
    
    // MARK: - Properties
    
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.dataSource = self; tv.delegate = self
        tv.separatorStyle = .none
        tv.rowHeight = 64
        tv.frame = self.view.bounds
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")
        return tv
    }()
    private lazy var progressView: ContourProgressView = {
        let top = UIApplication.shared.statusBarFrame.height + self.navigationController!.navigationBar.bounds.height
        let frame = CGRect(x: 0, y: top, width: self.view.bounds.width, height: self.view.bounds.height - top)
        let progressView = ContourProgressView(frame: frame); progressView.lineWidth = 5
        return progressView
    }()
    fileprivate let genres = Variable<[Genre]>([])
    private let disposeBag = DisposeBag()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(progressView)
        
        // Update TableView everytime genres gets a new value
        genres
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.async {
                    print("New genre batch came in, refreshing table now!")
                    self?.tableView.reloadData()
                }
            })
            .addDisposableTo(disposeBag)
        
        // Bind
        startDownloadSplit()
    }
    
    
    // MARK: - Methods
    
    private func startDownloadSplit() {
        // First get the categories.
        let genresObs = TmdbService.genres
        let moviesObs = genresObs.flatMap { genreArray in
            return Observable.from(genreArray.map { TmdbService.movies(forGenre: $0) })
        }
        .merge(maxConcurrent: 2)
        
        typealias GenreInfo = (genreCount: Int, genres: [Genre])
        let genresWithMovies = genresObs.flatMap { genreArray in
            moviesObs.scan(GenreInfo(0, genreArray)) { genreInfo, movies in
                return (genreInfo.genreCount + 1, genreInfo.genres.map { genre in
                    let moviesForGenre = movies.filter { movie in
                        movie.genres.contains(genre.id) &&
                        !genre.movies.contains { $0.id == movie.id }
                    }
                    if !moviesForGenre.isEmpty {
                        var genreCopy = genre
                        genreCopy.movies = genreCopy.movies + moviesForGenre
                        return genreCopy
                    }
                    return genre
                })
            }
        }
        .do(onNext: { [weak self] genreInfo in
            DispatchQueue.main.async {
                self?.progressView.progress = CGFloat(genreInfo.genreCount) / CGFloat(genreInfo.genres.count)
            }
        })
        .do(onCompleted: { [weak self] in
            DispatchQueue.main.async { self?.progressView.removeFromSuperview() }
        })
        
        // Bind
        genresObs
            .concat(genresWithMovies.map { $0.genres })
            .bindTo(genres)
            .addDisposableTo(disposeBag)
    }
    
    // Fetch genres and movies and combine the genres in one observable
    private func startDownloadPopular() {
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
