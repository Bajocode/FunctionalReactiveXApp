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
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-mm-dd"
        return formatter
    }()
    static var genres: Observable<[Genre]> = {
        return TmdbService.genericRequest(withEndPoint: .genres, params: ["api_key": apiKey])
            .map { jsonObject in
                guard let jsonGenres = jsonObject["genres"] as? [JSONObject] else {
                    throw TmdbError.invalidJSON(TmdbEndpoint.genres.rawValue)
                }
                return jsonGenres.flatMap(Genre.init).sorted { $0.name < $1.name }
            }
            .shareReplay(1)
    }()
    
    
    // MARK: - Methods
    
    // Public
    static func movies(forGenre genre: Genre) -> Observable<[Movie]> {
        let observables = Array(1..<2).map { movies(forResultsPage: $0, endpoint: .discover, extraParams: ["genre_ids":[genre.id]])}
        return Observable.from(observables)
            .merge()
            .reduce([]) { running, new in
                running + new
            }
    }
    static func popularMovies() -> Observable<[Movie]> {
        let observables = Array(1...20).map { movies(forResultsPage: Int($0), endpoint: .popularMovies) }
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
    
    private static func movies(forResultsPage page: Int, endpoint: TmdbEndpoint, extraParams: [String:Any] = [:]) -> Observable<[Movie]> {
        let params = [["api_key": apiKey, "page": page], extraParams]
            .flatMap { $0 }.reduce([String:Any]()) { dict, newPair in
                var copyDict = dict
                copyDict.updateValue(newPair.value, forKey: newPair.key)
                return copyDict
        }
        print(params)
        return genericRequest(withEndPoint: endpoint, params: params)
            .map { jsonObject in
                guard let jsonMovies = jsonObject["results"] as? [JSONObject] else {
                    throw TmdbError.invalidJSON(endpoint.rawValue)
                }
                return jsonMovies.flatMap(Movie.init)
            }
    }
    
    private static func genericRequest(withEndPoint endpoint: TmdbEndpoint, params: [String:Any] = [:]) -> Observable<JSONObject> {
        do {
            // Url
            guard
                let url = URL(string: baseURLString)?.appendingPathComponent(endpoint.rawValue),
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                    throw TmdbError.invalidURL(endpoint.rawValue)
            }
            components.queryItems = try params.flatMap { key, value in
                guard let v = value as? CustomStringConvertible else {
                    throw TmdbError.invalidParameter(key, value)
                }
                return URLQueryItem(name: key, value: v.description)
            }
            guard let finalURL = components.url else { throw TmdbError.invalidURL(endpoint.rawValue)}
            
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
enum TmdbEndpoint: String {
    case popularMovies = "/movie/popular"
    case genres = "/genre/movie/list"
    case discover = "/discover/movie"
}
enum TmdbError: Error {
    case invalidURL(String)
    case invalidParameter(String, Any)
    case invalidJSON(String)
}
