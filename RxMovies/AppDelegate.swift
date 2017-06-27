//
//  AppDelegate.swift
//  RxMovies
//
//  Created by Fabijan Bajo on 26/06/2017.
//  Copyright © 2017 Fabijan Bajo. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties
    
    var window: UIWindow?
    
    
    // MARK: - Methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Configure window
        window = UIWindow(frame: UIScreen.main.bounds)
        let genresVC = GenresViewController()
        genresVC.title = "Genres"
        let navC = UINavigationController(rootViewController: genresVC)
        window!.rootViewController = navC
        window!.makeKeyAndVisible()
        return true
    }
}

