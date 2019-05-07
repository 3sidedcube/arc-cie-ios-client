//
//  ProgressTableViewController.swift
//  Cash In Emergencies
//
//  Created by Joel Trew on 10/10/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import UIKit
import ThunderTable
import DMSSDK

// Table View controller for displaying the users progress of each module
class ProgressTableViewController: TableViewController {
    
    // Boolean for if the tableViews data needs to be reloaded 
    var needsReload: Bool = false
    
    /// Label displaying the title to explain the purpose of the view
    @IBOutlet weak var workflowProgressLabel: UILabel!
    
    // Label displaying the combination of all of the module progress
    @IBOutlet weak var overallProgressLabel: UILabel!
    
    // Bar that displays the overall progress
    @IBOutlet weak var overallProgressBarView: ModuleProgressView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.navigationController?.tabBarItem?.title = NSLocalizedString("PROGRESS_TABBAR_TITLE", value: "Progress", comment: "Word to display on the tab bar for the progress tab")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(valuesChanged), name: NSNotification.Name("ModulesDidIndex"), object: nil)
        
        overallProgressBarView.barColour = UIColor(hexString: "ed1b2e") ?? .red
        
        // If any of the substeps/tools become completed we need to redraw the tableView to show the updated values
        let notificationName = NSNotification.Name("ModulePropertyChanged")
        NotificationCenter.default.addObserver(self, selector: #selector(valuesChanged), name: notificationName, object: nil)
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        }
        
        redraw()
        
        self.title = NSLocalizedString("PROGRESS_NAVIGATION_TITLE", value: "Progress", comment: "The title in the navigation bar at the top of the progress view")
        workflowProgressLabel?.text = NSLocalizedString("PROGRESS_HEADER_TITLE", value:"WORKFLOW PROGRESS", comment: "A header title explaining that the view displays workflow progress. Styled in upercase")
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if needsReload {
            redraw()
        }
        
        Tracker.trackPage("Progress")
    }
    
    @objc func valuesChanged() {
        needsReload = true
    }
    
    // Creates a view model and sets it to the view controllers data source. The method loops through the modules and pulls out all of the required data that needs to be shown into one struct
    func redraw() {
        
        // Get our top level modules
        guard let modules = DirectoryManager().directories else {
            return
        }
        
        // Setup empty view model array
        var viewModels: [ProgressViewModel] = []
        
        // Loop through the top level modules
        for module in modules {
            
            // Module title i.e Preparedness
            let moduleTitle = module.directoryTitle
            // Get the hierarchy, i.e 1
            guard let hierarchy = module.metadata?["hierarchy"] as? String else { continue }
            
            // Flatmap all of the module's steps subSteps into one array
            let subSteps = module.directories?.flatMap({ (step) -> [Directory] in
                guard let stepDirectories = step.directories else { return [] }
                return stepDirectories
            }) ?? []
            
            // Collect all of the critical tools from our substeps
            let criticalTools = subSteps.flatMap({ (subStep) -> [Directory] in
                guard let subStepDirectories = subStep.directories else { return [] }
                return subStepDirectories.flatMap({ (tool) -> Directory? in
                    
                    if let isCritical = tool.metadata?["critical_path"] as? Bool,
                        isCritical {
                        return tool
                    }
                    
                    return nil
                })
            })
            
            let numberOfSubSteps = subSteps.count
            let numberOfCriticalTools = criticalTools.count
            
            // Closure which counts the number of completed modules by checking their state, this closure is passed to and ran by a reduce method on the Sub Steps and Critical tools
            let counter: ((Int, Directory) -> Int) = { (completedCount, module) -> Int in
                
                // Check if the state is complete, otherwise return our current count
                guard ProgressManager().checkState(for: module.identifier) else {
                    return completedCount
                }
                
                // If the state was true lets add on to our count and continue
                return completedCount + 1
            }
            
            // Run the counter on each array to get our completed amounts
            let completedSubSteps = subSteps.reduce(0, counter)
            let completedCriticalTools = criticalTools.reduce(0, counter)
            
            // Create the view model using all variables we gathered above
           let viewModel = ProgressViewModel(moduleHierarchy: hierarchy, moduleTitle: moduleTitle, numberOfSubSteps: numberOfSubSteps, numberOfCompletedSubSteps: completedSubSteps, numberOfCriticalTools: numberOfCriticalTools, numberOfCompletedCriticalTools: completedCriticalTools)
            
            viewModels.append(viewModel)
        }
        
        // Set the overall progress
        let totalPercentage = viewModels.reduce(0) { (value, viewModel) -> Double in
            return value + Double(viewModel.percentageComplete)
        }
       
        let overallProgressAmount = (totalPercentage / Double(viewModels.count))
        overallProgressBarView.progress = overallProgressAmount

        overallProgressLabel.text = String(format: NSLocalizedString("PROGRESS_HEADER_COMPLETION", value: "OVERALL COMPLETION %lu%%", comment: "Displays the percentage completion of the progress by the user"), arguments: [Int(overallProgressAmount)])
        
        self.data = [TableSection(rows: viewModels)]
        needsReload = false
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
        
    }
        
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
