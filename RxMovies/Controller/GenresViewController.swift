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
    private lazy var progressView: ContourProgressView = {
        let top = UIApplication.shared.statusBarFrame.height + self.navigationController!.navigationBar.bounds.height
        let frame = CGRect(x: 0, y: top, width: self.view.bounds.width, height: self.view.bounds.height - top)
        let progressView = ContourProgressView(frame: self.view.bounds)
        progressView.lineWidth = 5
        progressView.progressTintColor = Colors.primary
        return progressView
    }()

    
    // Rx
    fileprivate let genres = Variable<[Genre]>([])
    private let disposeBag = DisposeBag()
    typealias GenreInfo = (genreCount: Int, genres: [Genre])
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(progressView)
        
        // Bind result to genres Variable and retrieve Genres filled with fetched movies
        let genresObservable = TmdbService.genres
        let moviesObservable = genresObservable.flatMap { genreArray in
            return Observable.from(genreArray.map { TmdbService.movies(forGenre: $0) })
            }
            .merge(maxConcurrent: 2)
        let genresWithMovies = genres(genresObservable, combinedWithMovies: moviesObservable)
        
        // Fetch genres -> Fetch movies & add to genres -> bind updated genres stream to genres Variable
        genresObservable
            .concat(genresWithMovies.map { $0.genres })
            .bindTo(genres)
            .addDisposableTo(disposeBag)
        
        // Drive UI with download progress
        let progressDriver = genresWithMovies.asDriver(onErrorJustReturn: (genreCount: 0, genres: []))
            .map { CGFloat($0.genreCount) / CGFloat($0.genres.count) }
        progressDriver.drive(progressView.rx.progress).addDisposableTo(disposeBag)
        
        // Bind genres variable to tableView reload
        genres
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.tableView.reloadData() })
            .addDisposableTo(disposeBag)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    override var prefersStatusBarHidden: Bool { return true }
    
    
    // MARK: - Methods
    
    private func genres(_ genres: Observable<[Genre]>, combinedWithMovies movies: Observable<[Movie]>) -> Observable<GenreInfo> {
        // Fetch and insert movies into genres.movies
        return genres.flatMap { genreArray in
            movies.scan(GenreInfo(0, genreArray)) { genreInfo, movies in
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
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.text = "\(genre.name) (\(genre.movies.count))".uppercased()
        cell.textLabel?.textColor = genre.movies.isEmpty ? .lightGray : .black
        return cell
    }
}
