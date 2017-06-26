//
//  Genre.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 26/06/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import Foundation

struct Genre {
    
    // MARK: - Properties
    
    let id: Int
    let name: String
    var movies = [Movie]()
    
    
    // MARK: - Initializers
    init?(json: JSONObject) {
        guard
            let id = json["id"] as? Int,
            let name = json["name"] as? String else {
                return nil
        }
        self.id = id
        self.name = name
    }
}
