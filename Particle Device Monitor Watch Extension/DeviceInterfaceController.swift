//
//  InterfaceController.swift
//  Particle Device Monitor Watch Extension
//
//  Created by Grayson Smith on 3/12/16.
//  Copyright © 2016 Grayson Smith. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

struct SparkVariable {
    let name: String
    let type: String
    var value: String
    
    // TODO: add fetching of variable values...
}

struct SparkDevice {
    let name: String
    let type: String
    let isOnline: Bool
    let variables: [SparkVariable]
    let functions: [String]
}

class DeviceInterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet var devicesTable: WKInterfaceTable!
    
    var devices: [SparkDevice] = [] {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.devicesTable.setNumberOfRows(self.devices.count, withRowType: "DeviceRow")
            }
        }
    }
    
    var session: WCSession? {
        didSet {
            if let session = self.session {
                session.delegate = self
                session.activateSession()
            }
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session!.sendMessage(["devices": "please"], replyHandler: { (devicesList) -> Void in
                for device in devicesList.values {
                    if let device = device as? Dictionary<String,AnyObject> {
                        let name      = device["name"]      as! String
                        let type      = device["type"]      as! String
                        let isOnline  = device["isOnline"]  as! Bool
                        let variables = device["variables"] as! [(String, String, String)]
                        let functions = device["functions"] as! [String]
                        
                        var sparkVariables: [SparkVariable] = []
                        for variable in variables {
                            sparkVariables.append(SparkVariable(name: variable.0, type: variable.1, value: variable.2))
                        }
                        
                        let sparkDevice = SparkDevice(name: name, type: type, isOnline: isOnline, variables: sparkVariables, functions: functions)
                        
                        self.devices.append(sparkDevice)
                    }
                }
                }, errorHandler: { (error) -> Void in
                    print("Error sending or recieving message: \(error)")
            })
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
