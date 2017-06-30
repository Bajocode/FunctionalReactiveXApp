//
//  GenreTableViewCell.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 29/06/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import UIKit

class GenreTableViewCell: UITableViewCell {
    
    
    // MARK: - Properties
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(withGenre genre: Genre) {
        nameLabel.text = "\(genre.name) (\(genre.movies.count)"
        nameLabel.textColor = genre.movies.isEmpty ? .lightGray : .black
    }
}
