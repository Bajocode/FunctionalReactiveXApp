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
    let filteredMovies = Variable<[Movie]>([])
    let year = Variable<Int>(2017)
    private let disposeBag = DisposeBag()
    @IBOutlet var slider: UISlider!
    @IBOutlet var tableView: UITableView!
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellID")
        tableView.dataSource = self
        edgesForExtendedLayout = []
        // Update tableView everytime movies gets a new value
        filteredMovies.asObservable()
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            })
            .addDisposableTo(disposeBag)
        
        
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
    }
}


// MARK: - Tableview Datasource

extension MoviesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(filteredMovies.value.count)
        return filteredMovies.value.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID", for: indexPath)
        let movie = filteredMovies.value[indexPath.row]
        cell.textLabel?.text = movie.title
        return cell
    }
}
