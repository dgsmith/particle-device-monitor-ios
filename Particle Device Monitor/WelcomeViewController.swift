//
//  ViewController.swift
//  Particle Device Monitor
//
//  Created by Grayson Smith on 3/9/16.
//  Copyright © 2016 Grayson Smith. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, SparkSetupMainControllerDelegate {

    @IBOutlet weak var getStartedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layer = self.getStartedButton.layer
        layer.backgroundColor = UIColor.clearColor().CGColor
        layer.borderColor = UIColor.whiteColor().CGColor
        layer.cornerRadius = 3.0
        layer.borderWidth = 2.0

    }
    
    override func viewWillAppear(animated: Bool) {
        if let navController = self.navigationController {
            navController.setNavigationBarHidden(true, animated: false)
        }
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        if let navController = self.navigationController {
            navController.setNavigationBarHidden(false, animated: false)
        }
        super.viewWillDisappear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "select"
        {
            if let deviceListView = segue.destinationViewController as? DeviceListViewController
            {
                deviceListView.comingFromWelcome = true
            }
        }
    }
    
    func sparkSetupViewController(controller: SparkSetupMainController!, didFinishWithResult result: SparkSetupMainControllerResult, device: SparkDevice!) {
        
        if result == .LoggedIn
        {
            self.performSegueWithIdentifier("select", sender: self)
        }
        
        if result == .SkippedAuth
        {
            self.performSegueWithIdentifier("select", sender: self)
        }
        
    }

    @IBAction func startButtonTapped(sender: AnyObject) {
        if let _ = SparkCloud.sharedInstance().loggedInUsername
        {
            self.performSegueWithIdentifier("select", sender: self)
        }
        else
        {
            // lines required for invoking the Spark Setup wizard
            if let setupView = SparkSetupMainController(authenticationOnly: true)
            {
                setupView.delegate = self
                self.presentViewController(setupView, animated: true, completion: nil)
            }
        }
    }

}

