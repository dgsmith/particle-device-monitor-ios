//
//  DeviceListViewController.swift
//  Particle Device Monitor
//
//  Created by Grayson Smith on 3/9/16.
//  Copyright © 2016 Grayson Smith. All rights reserved.
//

import UIKit

class DeviceListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deviceSelectionTableView: UITableView!
    
    var devices : [SparkDevice] = []
    var deviceIDflashingDict : Dictionary<String,Int> = Dictionary()
    var deviceIDflashingTimer : NSTimer? = nil
    
    var selectedDevice : SparkDevice? = nil
    var refreshControlAdded : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !SparkCloud.sharedInstance().isLoggedIn {
            self.logoutButton.setTitle("Log in", forState: .Normal)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        if SparkCloud.sharedInstance().loggedInUsername != nil
        {
            self.loadDevices()
            
            self.deviceIDflashingTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "flashingTimerFunc:", userInfo: nil, repeats: true)
        }
        super.viewWillAppear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        self.deviceIDflashingTimer!.invalidate()
        if segue.identifier == "monitor"
        {
            if let deviceView = segue.destinationViewController as? DeviceMonitorViewController
            {
                deviceView.device = self.selectedDevice!
            }
        }
    }
    
    func flashingTimerFunc(timer : NSTimer)
    {
        for (deviceid, timeleft) in self.deviceIDflashingDict
        {
            if timeleft > 0 {
                self.deviceIDflashingDict[deviceid]=timeleft-1
            } else {
                self.deviceIDflashingDict.removeValueForKey(deviceid)
                self.loadDevices()
            }
        }
    }
    
    func loadDevices()
    {
        var hud : MBProgressHUD
        
        // do a HUD only for first time load
        if self.refreshControlAdded == false {
            hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            hud.mode = .CustomView//.Indeterminate
            hud.animationType = .ZoomIn
            hud.labelText = "Loading"
            hud.minShowTime = 0.4
            
            // prepare spinner view for first time populating of devices into table
            let spinnerView : UIImageView = UIImageView(image: UIImage(named: "imgSpinner"))
            spinnerView.frame = CGRectMake(0, 0, 37, 37);
            spinnerView.contentMode = .ScaleToFill
            let rotation = CABasicAnimation(keyPath:"transform.rotation")
            rotation.fromValue = 0
            rotation.toValue = 2*M_PI
            rotation.duration = 1.0;
            rotation.repeatCount = 1000; // Repeat
            spinnerView.layer.addAnimation(rotation,forKey:"Spin")
            
            hud.customView = spinnerView
            
        }
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            SparkCloud.sharedInstance().getDevices({ (devices:[AnyObject]?, error:NSError?) -> Void in
                
                self.handleGetDevicesResponse(devices, error: error)
                
                // do anyway:
                dispatch_async(dispatch_get_main_queue()) {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    // first time add the custom pull to refresh control to the tableview
                    if self.refreshControlAdded == false {
                        self.addRefreshControl()
                        self.refreshControlAdded = true
                    }
                }
            })
        }
    }
    
    func handleGetDevicesResponse(devices:[AnyObject]?, error:NSError?)
    {
        if let e = error {
            if e.code == 401 {
                self.logoutButtonTapped(self.logoutButton)
            } else {
                TSMessage.showNotificationWithTitle("Error", subtitle: "Error loading devices, please check your internet connection.", type: .Error)
            }
        } else {
            if let d = devices {
                self.devices = d as! [SparkDevice]
                
                // Sort alphabetically
                self.devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                    if let n1 = firstDevice.name {
                        if let n2 = secondDevice.name {
                            return n1 < n2 //firstDevice.name < secondDevice.name
                        }
                    }
                    return false;
                })
                
                // then sort by device type
                self.devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                    return firstDevice.type.rawValue > secondDevice.type.rawValue
                })
                
                // and then by online/offline
                self.devices.sortInPlace({ (firstDevice:SparkDevice, secondDevice:SparkDevice) -> Bool in
                    return firstDevice.connected && !secondDevice.connected
                })
                
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.deviceSelectionTableView.reloadData()
            }
        }
    }
    
    func addRefreshControl()
    {
        self.deviceSelectionTableView.addPullToRefreshWithPullText("Pull To Refresh", refreshingText: "Refreshing Devices") { () -> Void in
            SparkCloud.sharedInstance().getDevices() { (devices:[AnyObject]?, error:NSError?) -> Void in
                self.handleGetDevicesResponse(devices, error: error)
                self.deviceSelectionTableView.finishLoading()
            }
            
        }
    }
    
    @IBAction func logoutButtonTapped(sender: AnyObject) {
        SparkCloud.sharedInstance().logout()
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
    }
    
    // MARK: - UITableViewDataSource functions
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var masterCell : UITableViewCell?
        
        if indexPath.row < self.devices.count {
            let cell:DeviceTableViewCell = self.deviceSelectionTableView.dequeueReusableCellWithIdentifier("device_cell") as! DeviceTableViewCell
            if let name = self.devices[indexPath.row].name {
                cell.deviceNameLabel.text = name
            } else {
                cell.deviceNameLabel.text = "<no name>"
            }
            
            cell.deviceImageView.image = UIImage(named: "img\(self.devices[indexPath.row].type.description())")
            cell.deviceTypeLabel.text = self.devices[indexPath.row].type.description()            
            cell.deviceIDLabel.text = devices[indexPath.row].id.uppercaseString
            
            let online = self.devices[indexPath.row].connected
            switch online
            {
            case true :
                cell.deviceStateLabel.text = "Online"
                cell.deviceStateImageView.image = UIImage(named: "imgGreenCircle") // TODO: breathing cyan
            default :
                cell.deviceStateLabel.text = "Offline"
                cell.deviceStateImageView.image = UIImage(named: "imgRedCircle") // gray circle
            }
            
            // override everything else
            if devices[indexPath.row].isFlashing || self.deviceIDflashingDict.keys.contains(devices[indexPath.row].id) {
                cell.deviceStateLabel.text = "Flashing"
                cell.deviceStateImageView.image = UIImage(named: "imgPurpleCircle") // gray circle
            }
            masterCell = cell
        }
        
        // make cell darker if it's even
        if (indexPath.row % 2) == 0 {
            masterCell?.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        } else { // lighter if even
            masterCell?.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        }
        
        return masterCell!
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // user swiped left
        if editingStyle == .Delete
        {
            TSMessage.showNotificationInViewController(self, title: "Unclaim confirmation", subtitle: "Are you sure you want to remove this device from your account?", image: UIImage(named: "imgQuestionWhite"), type: .Error, duration: -1, callback: { () -> Void in
                // callback for user dismiss by touching inside notification
                TSMessage.dismissActiveNotification()
                tableView.editing = false
                } , buttonTitle: " Yes ", buttonCallback: { () -> Void in
                    // callback for user tapping YES button - need to delete row and update table (TODO: actually unclaim device)
                    self.devices[indexPath.row].unclaim() { (error: NSError?) -> Void in
                        if let err = error
                        {
                            TSMessage.showNotificationWithTitle("Error", subtitle: err.localizedDescription, type: .Error)
                            self.deviceSelectionTableView.reloadData()
                        }
                    }
                    
                    self.devices.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
                    // update table view display to show dark/light cells with delay so that delete animation can complete nicely
                    dispatch_after(delayTime, dispatch_get_main_queue()) {
                        tableView.reloadData()
                    }}, atPosition: .Top, canBeDismissedByUser: true)
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row < self.devices.count
    }
    
    // MARK: - UITableViewDelegate functions
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Unclaim"
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        // user touches elsewhere
        TSMessage.dismissActiveNotification()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        TSMessage.dismissActiveNotification()
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        if devices[indexPath.row].isFlashing || self.deviceIDflashingDict.keys.contains(devices[indexPath.row].id) {
            TSMessage.showNotificationWithTitle("Device is being flashed", subtitle: "Device is currently being flashed, please wait for the process to finish.", type: .Warning)
        } else if self.devices[indexPath.row].connected {
            self.selectedDevice = self.devices[indexPath.row]
            self.performSegueWithIdentifier("monitor", sender: self)            
        } else {
            TSMessage.showNotificationWithTitle("Device offline", subtitle: "This device is offline, please turn it on and refresh in order to Tinker with it.", type: .Error)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
}
