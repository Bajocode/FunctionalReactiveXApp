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
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(progressView)
        
        // Bind genres variable to tableView reload
        genres
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.tableView.reloadData() })
            .addDisposableTo(disposeBag)
        
        // Bind result to genres Variable
        startDownload()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    override var prefersStatusBarHidden: Bool { return true }
    
    
    // MARK: - Methods
    
    private func startDownload() {
        // First get the categories.
        let genresObs = TmdbService.genres
        let moviesObs = genresObs.flatMap { genreArray in
            return Observable.from(genreArray.map { TmdbService.movies(forGenre: $0) })
        }
        .merge(maxConcurrent: 2)
        
        // Insert movies into genres.movies
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
        .observeOn(MainScheduler.instance)
        
        // Update progressView
        .do(onNext: { [weak self] genreInfo in
            let progress = CGFloat(genreInfo.genreCount) / CGFloat(genreInfo.genres.count)
            self?.progressView.progress = progress
        })
        
        // Bind updated genres observable to genres Variable
        genresObs
            .concat(genresWithMovies.map { $0.genres })
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
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.text = "\(genre.name) (\(genre.movies.count))".uppercased()
        cell.textLabel?.textColor = genre.movies.isEmpty ? .lightGray : .black
        return cell
    }
}
