//
//  WorkflowViewController.swift
//  Cash In Emergencies
//
//  Created by Matthew Cheetham on 22/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import UIKit
import DMSSDK
import ThunderTable
import ThunderBasics

class WorkflowViewController: UIViewController {
    
    @IBOutlet weak var toolkitButton: UIButton!
    @IBOutlet weak var criticalToolsButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    lazy var onboardingViewController: UIViewController? = UIStoryboard(name: "Onboarding", bundle: Bundle.main).instantiateInitialViewController()
    
    var toolkitTableViewController: ToolkitTableViewController? {
        return childViewControllers.first as? ToolkitTableViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add onboarding view as a child view controller in willAppear, so we don't show the user empty tableView on launch while the vc presents
        if !UserDefaults.standard.bool(forKey: "CIEHasDoneOnboarding") {
            
            if let onboarding = onboardingViewController {
                
                view.addSubview(onboarding.view)
                onboarding.view.frame = view.bounds
                onboarding.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                
                addChildViewController(onboarding)
            }
        }
        
        Tracker.trackPage("Workflow")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let searchBar = toolkitTableViewController?.searchBar {
            toolkitTableViewController?.tableView.contentOffset = CGPoint(x: 0, y: searchBar.frame.height)
        }
        
        toolkitButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
        toolkitButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        
        criticalToolsButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
        criticalToolsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        
        // Remove the childviewcontroller and present with no animation in didAppear, this should be seemless and appear that the view has loaded with onboarding
        if !UserDefaults.standard.bool(forKey: "CIEHasDoneOnboarding")  {
            
            if let onboardingViewController = onboardingViewController {
                if childViewControllers.contains(onboardingViewController) {
                    onboardingViewController.willMove(toParentViewController: nil)
                    onboardingViewController.view.removeFromSuperview()
                    onboardingViewController.removeFromParentViewController()
                }
                
                present(onboardingViewController, animated: false, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        }
        
        self.title = NSLocalizedString("WORKFLOW_NAVIGATION_TITLE", value: "Workflow", comment: "The title in the navigation bar at the top of the workflow view")
        self.toolkitButton?.setTitle(NSLocalizedString("WORKFLOW_FILTER_BUTTON_TOOLKIT", value: "TOOLKIT", comment: "The button that filters the list to show the entire toolkit"), for: .normal)
        self.criticalToolsButton?.setTitle(NSLocalizedString("WORKFLOW_FILTER_BUTTON_CRITICALTOOLS", value: "CRITICAL TOOLS", comment: "The button that filters the list of directories to only show critical tools"), for: .normal)
        self.navigationController?.tabBarItem?.title = NSLocalizedString("WORKFLOW_TABBAR_TITLE", value: "Workflow", comment: "Word to display on the tab bar for the workflow tab")
    }

    @IBAction func handleFilterButton(_ sender: UIButton) {
        
        toolkitTableViewController?.searchBar?.resignFirstResponder()
        toolkitTableViewController?.searchBar?.text = nil
        
        toolkitButton.isSelected = !toolkitButton.isSelected
        criticalToolsButton.isSelected = !criticalToolsButton.isSelected
        
        toolkitButton.backgroundColor = toolkitButton.isSelected ? UIColor(hexString: "ed1b2e") : UIColor.clear
        toolkitButton.tintColor = toolkitButton.isSelected ? UIColor.white : UIColor(hexString: "9f9fa3")
        
        criticalToolsButton.backgroundColor = criticalToolsButton.isSelected ? UIColor(hexString: "ed1b2e") : UIColor.clear
        criticalToolsButton.tintColor = criticalToolsButton.isSelected ? UIColor.white : UIColor(hexString: "9f9fa3")
        
        if criticalToolsButton.isSelected {
            toolkitTableViewController?.showCriticalToolsOnly()
            toolkitTableViewController?.searchBar.set(height: 0)
            Tracker.trackEventWith("Workflow", action: "Critical tools", label: nil, value: nil)
        } else {
            toolkitTableViewController?.redraw()
            toolkitTableViewController?.searchBar.set(height: 56)
            Tracker.trackEventWith("Workflow", action: "Toolkit", label: nil, value: nil)
        }
    }
}
