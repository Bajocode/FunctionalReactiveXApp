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

struct TmdbService {
    
    
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
    
    static func movies(forSearchText text: String) -> Observable<[Movie]> {
        return movies(forResultsPage: 1, endpoint: .search, extraParams: ["query": text])
    }
    static func movies(forGenre genre: Genre) -> Observable<[Movie]> {
        let observables = [1,2].map { movies(forResultsPage: $0, endpoint: .moviesForGenre(genre.id))}
        return Observable.from(observables)
            .merge()
            .reduce([]) { running, new in
                running + new
            }
    }
    private static func movies(forResultsPage page: Int, endpoint: TmdbEndpoint, extraParams: [String:Any] = [:]) -> Observable<[Movie]> {
        // Merge params
        var params: [String:Any] = ["api_key": apiKey, "page": page]
        extraParams.forEach { (key,value) in params[key] = value }
        return genericRequest(withEndPoint: endpoint, params: params)
            .map { jsonObject in
                guard let jsonMovies = jsonObject["results"] as? [JSONObject] else {
                    print(jsonObject)
                    throw TmdbError.invalidJSON(endpoint.value)
                }
                return jsonMovies.flatMap(Movie.init)
            }
    }
    static func posterURL(with path: String) -> URL {
        return URL(string: "https://image.tmdb.org/t/p/w342/\(path)")!
    }
    
    
    // Generic request: endPoint -> root JSON object
    
    private static func genericRequest(withEndPoint endpoint: TmdbEndpoint, params: [String:Any] = [:]) -> Observable<JSONObject> {
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
            let requestObservable: Observable<URLRequest> = Observable.create() { observer in
                observer.onNext(URLRequest(url: finalURL)); observer.onCompleted()
                return Disposables.create()
            }
            return requestObservable.flatMap { request in
                return URLSession.shared.rx.response(request: request).map { response, data in
                    switch response.statusCode {
                    case 200..<300:
                        guard
                            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                            let mapResult = jsonObject as? JSONObject else {
                                print(response)
                            throw TmdbError.invalidJSON(finalURL.absoluteString)
                        }
                        return mapResult
                    case 401: throw TmdbError.invalidKey
                    case 400..<500: throw TmdbError.dataNotFound
                    default: throw TmdbError.serverFailure
                    }
                }
            }
        } catch {
            return Observable.empty()
        }
    }
}


// MARK: - Tmdb enums

enum TmdbEndpoint {
    case popularMovies
    case genres
    case moviesForGenre(Int)
    case search
    var value: String {
        switch self {
            case .popularMovies: return "/movie/popular"
            case .genres: return "/genre/movie/list"
            case .moviesForGenre(let genreID): return "/genre/\(genreID)/movies"
            case .search: return "/search/movie"
        }
    }
}
enum TmdbError: Error {
    case invalidURL(String)
    case invalidParameter(String, Any)
    case invalidJSON(String)
    case invalidKey
    case dataNotFound
    case serverFailure
}
