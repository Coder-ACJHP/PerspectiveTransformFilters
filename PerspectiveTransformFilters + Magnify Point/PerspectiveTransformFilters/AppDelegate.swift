//
//  AppDelegate.swift
//  PerspectiveTransformFilters
//
//  Created by Onur Işık on 29.06.2020.
//  Copyright © 2020 Coder ACJHP. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        UIView.appearance().semanticContentAttribute = .forceLeftToRight
        UIButton.appearance().semanticContentAttribute = .forceLeftToRight
        UITextView.appearance().semanticContentAttribute = .forceLeftToRight
        UITextField.appearance().semanticContentAttribute = .forceLeftToRight
                
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        self.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "PrespectiveTransformViewController")
        self.window?.semanticContentAttribute = .forceLeftToRight
        self.window?.makeKeyAndVisible()
        
        return true
    }

}

