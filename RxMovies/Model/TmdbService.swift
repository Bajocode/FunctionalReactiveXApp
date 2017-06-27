//
//  MovieService.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 26/06/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

typealias JSONObject = [String:Any]

class TmdbService {
    
    // MARK: - Properties
    
    private static let baseURLString = "https://api.themoviedb.org/3"
    private static let apiKey = "91e3a1fc957cde9192fede75cedb96e2"
    private static let genresEndpoint = "/genre/movie/list"
    private static let moviesEndpoint = "/movie/popular"
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-mm-dd"
        return formatter
    }()
    // fetching them asynchronously, so the best way to expose them is with an Observable
    static var genres: Observable<[Genre]> = {
        return TmdbService.request(endpoint: genresEndpoint, params: ["api_key": apiKey])
            .map { jsonObject in
                guard let jsonGenres = jsonObject["genres"] as? [JSONObject] else {
                    throw TmdbError.invalidJSON(genresEndpoint)
                }
                return jsonGenres.flatMap(Genre.init).sorted { $0.name < $1.name }
            }
            .shareReplay(1)
    }()
    
    
    // MARK: - Methods
    
    // Public
    static func popularMovies() -> Observable<[Movie]> {
        let observables = Array(1...20).map { popularMovies(page: Int($0)) }
        return Observable.from(observables)
            .merge()
            .reduce([]) { running, new in
                running + new
        }
    }
    static func posterURL(with path: String) -> URL {
        return URL(string: "https://image.tmdb.org/t/p/w342/\(path)")!
    }
    
    // Private
    private static func popularMovies(page: Int) -> Observable<[Movie]> {
        return request(endpoint: moviesEndpoint,
                       params: ["api_key": apiKey,
                                "page": page])
            .map { jsonObject in
                guard let jsonMovies = jsonObject["results"] as? [JSONObject] else {
                    throw TmdbError.invalidJSON(moviesEndpoint)
                }
                return jsonMovies.flatMap(Movie.init)
            }
    }
    private static func request(endpoint: String, params: [String:Any] = [:]) -> Observable<JSONObject> {
        do {
            // Url
            guard
                let url = URL(string: baseURLString)?.appendingPathComponent(endpoint),
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                    throw TmdbError.invalidURL(endpoint)
            }
            components.queryItems = try params.flatMap { key, value in
                guard let v = value as? CustomStringConvertible else {
                    throw TmdbError.invalidParameter(key, value)
                }
                return URLQueryItem(name: key, value: v.description)
            }
            guard let finalURL = components.url else { throw TmdbError.invalidURL(endpoint)}
            
            // Request
            let request = URLRequest(url: finalURL)
            return URLSession.shared.rx.response(request: request)
                .map {_, data -> JSONObject in
                    guard
                        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                        let mapResult = jsonObject as? JSONObject else {
                            throw TmdbError.invalidJSON(finalURL.absoluteString)
                    }
                    return mapResult
                }
        } catch {
            return Observable.empty()
        }
    }
}


// MARK: - Errors

enum TmdbError: Error {
    case invalidURL(String)
    case invalidParameter(String, Any)
    case invalidJSON(String)
}
