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
        // Configure window with NavC
        window = UIWindow(frame: UIScreen.main.bounds)
        let genresVC = GenresViewController()
        genresVC.title = "Genres"
        let navC = UINavigationController(rootViewController: genresVC)
        navC.navigationBar.tintColor = Colors.primary
        window!.rootViewController = navC
        window!.makeKeyAndVisible()
        return true
    }
}


// MARK: - UI Colors

struct Colors {
    static let primary = UIColor(hue:0.97, saturation:0.80, brightness:0.99, alpha:1.00)
}
