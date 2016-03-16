//
//  FunctionCallViewController.swift
//  Particle Device Monitor
//
//  Created by Grayson Smith on 3/12/16.
//  Copyright © 2016 Grayson Smith. All rights reserved.
//

import UIKit

class FunctionCallViewController : UIViewController {
    var device: SparkDevice?
    var function: String?
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var args: UITextField!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var response: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
    }
    
    @IBAction func callButtonHit(sender: AnyObject) {
        guard let device = self.device, let function = self.function else { return }
        
        if let args: String = args.text {
            device.callFunction(function, withArguments: [args], completion: { (response, error) -> Void in
                if let error = error {
                    print("Error calling function, \(function): \(error)")
                } else if let response = response {
                    self.response.text = String(response)
                }
            })
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
}
