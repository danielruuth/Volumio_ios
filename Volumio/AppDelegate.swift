//
//  AppDelegate.swift
//  Volumio
//
//  Created by Federico Sintucci on 20/09/16.
//  Copyright © 2016 Federico Sintucci. All rights reserved.
//

import UIKit

import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        Log.setLog(level: BundleInfo[.logLevel])

        handleArguments()

        UIBarButtonItem.appearance()
            .setTitleTextAttributes(
				[NSAttributedString.Key.foregroundColor: UIColor.clear], for: UIControl.State.normal
        )
        UIBarButtonItem.appearance()
            .setTitleTextAttributes(
				[NSAttributedString.Key.foregroundColor: UIColor.clear], for: UIControl.State.highlighted
        )
        UINavigationBar.appearance().tintColor = UIColor.black

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        VolumioIOManager.shared.closeConnection()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.

        VolumioIOManager.shared.connectCurrent()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

extension InfoKeys {
    static let logLevel = InfoKey<String?>("AppLogLevel")
}

extension DefaultsKeys {
    static let selectedPlayer = DefaultsKey<Player?>("selectedPlayer")
}

// MARK: - App Launch Arguments

extension AppDelegate {

    func handleArguments() {
        if ProcessInfo.shouldResetUserDefaults {
            Defaults.removeAll()
        }
        if ProcessInfo.shouldDefaultUserDefaults {
            Defaults.removeAll()
            let defaultPlayer = Player(
                name: "Volumio",
                host: "volumio.local.",
                port: 3000
            )
            Defaults[.selectedPlayer] = defaultPlayer
        }
    }

}

extension ProcessInfo {
    /**
        Used to reset user defaults on startup.

        let app = XCUIApplication()
        app.launchArguments.append("reset-user-defaults")
     */
    class var shouldResetUserDefaults: Bool {
        return processInfo.arguments.contains("reset-user-defaults")
    }
    /**
        Used to set user defaults to default values on startup.

        let app = XCUIApplication()
        app.launchArguments.append("default-user-defaults")
     */
    class var shouldDefaultUserDefaults: Bool {
        return processInfo.arguments.contains("default-user-defaults")
    }
}
