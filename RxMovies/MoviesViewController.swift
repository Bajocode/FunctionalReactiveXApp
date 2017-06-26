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
    // UI
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.dataSource = self
        tv.frame = self.view.bounds
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tv.bounds.width, height: 60))
        headerView.addSubview(self.yearSlider)
        self.yearSlider.center = headerView.center
        tv.tableHeaderView = headerView
        return tv
    }()
    private lazy var yearSlider: UISlider = {
        let slider =  UISlider(frame: CGRect(x: 0, y: 0, width: 250, height: 44))
        slider.minimumValue = 1920; slider.maximumValue = 2017; slider.value = 2017
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        return slider
    }()
    // Rx
    let movies = Variable<[Movie]>([])
    let filteredMovies = Variable<[Movie]>([])
    let rating = Variable<Float>(1.0)
    let year = Variable<Int>(2017)
    private let disposeBag = DisposeBag()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        // Update tableView everytime movies gets a new value
        filteredMovies.asObservable()
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            })
            .addDisposableTo(disposeBag)
        
        
        // Filter with minimum movie year treshHold
        Observable.combineLatest(year.asObservable(), movies.asObservable()) { year, movies in
                return movies.filter {
                    return $0.year >= year }
                    .sorted { $0.title < $1.title }
            }
            .bindTo(filteredMovies)
            .addDisposableTo(disposeBag)
    }
    
    
    // MARK: - Actions
    
    func sliderChanged(sender: UISlider) {
        rating.value = sender.value
        navigationItem.prompt = "\(Int(sender.value))"
    }
}


// MARK: - Tableview Datasource

extension MoviesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(filteredMovies.value.count)
        return filteredMovies.value.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)
        let movie = filteredMovies.value[indexPath.row]
        cell.textLabel?.text = movie.title
        return cell
    }
}
