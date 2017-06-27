//
//  Movie.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 26/06/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import Foundation

struct Movie {
    
    // MARK: - Properties
    
    let id: Int
    let title: String
    let year: Int
    let genres: [Int]
    
    
    // MARK: - Initializers
    
    init?(json: JSONObject) {
        guard
            let id = json["id"] as? Int,
            let title = json["title"] as? String,
            let genres = json["genre_ids"] as? [Int],
            let dateString = json["release_date"] as? String else {
                return nil
        }
        self.id = id
        self.title = title
        self.genres = genres
        guard let date = TmdbService.yearFormatter.date(from: dateString) else { return nil }
        self.year = Calendar.current.component(.year, from: date)
    }
}
