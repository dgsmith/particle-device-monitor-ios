//
//  DeviceMonitorViewController.swift
//  Particle Device Monitor
//
//  Created by Grayson Smith on 3/9/16.
//  Copyright © 2016 Grayson Smith. All rights reserved.
//

import UIKit

class DeviceMonitorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var device : SparkDevice?
    var selectedFunction: String?
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var variableTableView: UITableView!
    @IBOutlet weak var functionTableView: UITableView!
    
    var variables: [(String, String, String)] = Array<(String, String, String)>()
    var functions: [String] = Array<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        if (SparkCloud.sharedInstance().loggedInUsername != nil) {
            self.loadDeviceInformation()
        }
        super.viewWillAppear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "function_call"
        {
            if let functionView = segue.destinationViewController as? FunctionCallViewController
            {
                functionView.device = self.device!
                functionView.function = self.selectedFunction!
            }
        }
    }
    
    func loadDeviceInformation() {
        guard let device = self.device else { return }
        
        // Variables
        // Sort alphabetically by variable name
        var tempVariables = device.variables.sort { (firstVariable: (String, String), secondVariable: (String, String)) -> Bool in
            return firstVariable.0 < secondVariable.0
            }
        
        // Sort alphabetically by variable type
        tempVariables.sortInPlace({ (firstVariable: (String, String), secondVariable: (String, String)) -> Bool in
            return firstVariable.1 < secondVariable.1
        })
        
        for variable in tempVariables {
            self.variables.append((variable.0, variable.1, ""))
            self.getValueForVariable(variable.0)
        }
        
        // Functions
        // Sort alphabetically by function name
        self.functions = device.functions.sort { (firstFunction: String, secondFunction: String) -> Bool in
            return firstFunction < secondFunction
        }
        
        self.variableTableView.dataSource = self
        self.variableTableView.delegate = self
        self.variableTableView.reloadData()
        
        self.functionTableView.dataSource = self
        self.functionTableView.delegate = self
        self.functionTableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.variableTableView) {
            return self.variables.count
        } else { // tableView == self.functionTableView
            return self.functions.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var masterCell : UITableViewCell?
        
        if (tableView == self.variableTableView) {
            if !self.variables.isEmpty {
                let cell: VariableTableViewCell = self.variableTableView.dequeueReusableCellWithIdentifier("variable_cell") as! VariableTableViewCell
                cell.name.text  = self.variables[indexPath.row].0
                cell.type.text  = self.variables[indexPath.row].1
                cell.value.text = self.variables[indexPath.row].2
                
                cell.name.sizeToFit()
                cell.type.sizeToFit()
                
                masterCell = cell
            }
        } else { //tableView == self.functionTableView)
            if !self.functions.isEmpty {
                let cell: FunctionTableViewCell = self.functionTableView.dequeueReusableCellWithIdentifier("function_cell") as! FunctionTableViewCell
                cell.name.text = self.functions[indexPath.row]
                
                cell.name.sizeToFit()
                
                masterCell = cell
            }
        }
        
        // make cell darker if it's even
        if (indexPath.row % 2) == 0
        {
            masterCell?.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        }
        else // lighter if even
        {
            masterCell?.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        }
        
        return masterCell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let _ = self.device else { return }
        
        if (tableView == self.variableTableView) {
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.getValueForVariable(self.variables[indexPath.row].0)
            }
        } else {
            self.selectedFunction = self.functions[indexPath.row]
            self.performSegueWithIdentifier("function_call", sender: self)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (tableView == self.variableTableView) {
            return 70
        } else {
            return 50
        }
    }

    @IBAction func backButtonHit(sender: AnyObject) {
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
    }
    
    func getValueForVariable(variable: String) {
        guard let device = device else { return }
        
        device.getVariable(variable, completion: { (result, error) -> Void in
            if let error = error {
                print("Failed to retrieve variable, error: \(error)")
            } else if let result = result {
                
                if let index = self.variables.indexOf({ (predicate) -> Bool in
                    return predicate.0 == variable
                }) {
                    self.variables[index].2 = String(result)
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.variableTableView.reloadData()
                }
            }
        })
    }
}
