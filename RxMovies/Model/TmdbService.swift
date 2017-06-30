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
                    throw TmdbError.invalidJSON(TmdbEndpoint.genres.value)
                }
                return jsonGenres.flatMap(Genre.init).sorted { $0.name < $1.name }
            }
            .shareReplay(1)
    }()
    
    
    // MARK: - Methods
    
    
    static func movies(forGenre genre: Genre) -> Observable<[Movie]> {
        let observables = [1,2].map { movies(forResultsPage: $0, endpoint: .moviesForGenre(genre.id))}
        return Observable.from(observables)
            .merge()
            .reduce([]) { running, new in
                running + new
            }
    }
    // PRIVATE Call genericRequest and parse root json into Observable<[Movie]>
    private static func movies(forResultsPage page: Int, endpoint: TmdbEndpoint) -> Observable<[Movie]> {
        return genericRequest(withEndPoint: endpoint, params: ["api_key": apiKey, "page": page])
            .map { jsonObject in
                guard let jsonMovies = jsonObject["results"] as? [JSONObject] else {
                    print(jsonObject)
                    throw TmdbError.invalidJSON(endpoint.value)
                }
                return jsonMovies.flatMap(Movie.init)
            }
    }
    // PRIVATE Generic request
    static var count = 0
    private static func genericRequest(withEndPoint endpoint: TmdbEndpoint, params: [String:Any] = [:]) -> Observable<JSONObject> {
        count += 1
        print(count, " requests")
        do {
            // Url
            guard
                let url = URL(string: baseURLString)?.appendingPathComponent(endpoint.value),
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                    throw TmdbError.invalidURL(endpoint.value)
            }
            components.queryItems = try params.flatMap { key, value in
                guard let v = value as? CustomStringConvertible else {
                    throw TmdbError.invalidParameter(key, value)
                }
                return URLQueryItem(name: key, value: v.description)
            }
            guard let finalURL = components.url else { throw TmdbError.invalidURL(endpoint.value)}
            
            // Request
            let request = URLRequest(url: finalURL)
            return URLSession.shared.rx.response(request: request)
                .map {httpResponse, data -> JSONObject in
                    guard
                        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                        let mapResult = jsonObject as? JSONObject else {
                            print(httpResponse)
                            throw TmdbError.invalidJSON(finalURL.absoluteString)
                    }
                    return mapResult
                }
        } catch {
            return Observable.empty()
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
}


// MARK: - Errors
enum TmdbEndpoint {
    case popularMovies
    case genres
    case moviesForGenre(Int)
    var value: String {
        switch self {
            case .popularMovies: return "/movie/popular"
            case .genres: return "/genre/movie/list"
            case .moviesForGenre(let genreID): return "/genre/\(genreID)/movies"
        }
    }
}
enum TmdbError: Error {
    case invalidURL(String)
    case invalidParameter(String, Any)
    case invalidJSON(String)
}
