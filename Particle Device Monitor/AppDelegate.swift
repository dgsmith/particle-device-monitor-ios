//
//  AppDelegate.swift
//  Particle Device Monitor
//
//  Created by Grayson Smith on 3/9/16.
//  Copyright © 2016 Grayson Smith. All rights reserved.
//

import UIKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension SparkDeviceType {
    func description() -> String {
        switch (self) {
        case .Core:
            return "Core"
        case .Photon:
            return "Photon"
        case .Electron:
            return "Electron"
        }
    }
}

extension AppDelegate: WCSessionDelegate {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        if let deviceRequest = message["devices"] as? String where deviceRequest == "please" {
            // gotta say please
            if SparkCloud.sharedInstance().loggedInUsername != nil {
                SparkCloud.sharedInstance().getDevices({ (devices, error) -> Void in
                    if let e = error {
                        replyHandler(["error": e])
                    } else {
                        if let d = devices {
                            var devices = d as! [SparkDevice]
                            
                            // Sort alphabetically
                            devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                                if let n1 = firstDevice.name {
                                    if let n2 = secondDevice.name {
                                        return n1 < n2 //firstDevice.name < secondDevice.name
                                    }
                                }
                                return false;
                            })
                            
                            // then sort by device type
                            devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                                return firstDevice.type.rawValue > secondDevice.type.rawValue
                            })
                            
                            // and then by online/offline
                            devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                                return firstDevice.connected && !secondDevice.connected
                            })
                            
                            var devicesToSend: [Dictionary<String,Dictionary<String,AnyObject>>] = []
                            for device in devices {
                                devicesToSend.append([device.id: ["name": device.name!]])
                                devicesToSend.append([device.id: ["type": device.type.description()]])
                                devicesToSend.append([device.id: ["isOnline": device.connected]])
                                
                            }
                        }
                    }
                })
            }
        }
    }
}

