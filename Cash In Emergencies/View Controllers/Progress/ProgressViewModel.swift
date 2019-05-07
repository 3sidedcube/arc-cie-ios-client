//
//  ProgressViewModel.swift
//  Cash In Emergencies
//
//  Created by Joel Trew on 10/10/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import Foundation
import ThunderTable

// View Model containing all the data needed to display progress information in the ProgressTableViewController
struct ProgressViewModel {
    
    // A number representing the hierarchy of a module
    var moduleHierarchy: String
    
    // A short title of a module
    var moduleTitle: String?
    
    // The total number of substeps for a given module
    var numberOfSubSteps: Int
    
    // The number of substeps the user has checked as completed
    var numberOfCompletedSubSteps: Int
    
    // The total number of critical tools for a given module
    var numberOfCriticalTools: Int
    
    // The total number of critical tools the user has checked as completed
    var numberOfCompletedCriticalTools: Int
    
    // The overall compeltion of a module, the value is between 0 and 100
    // At the moment only critical tools count towards the overall total
    var percentageComplete: Int {
        guard numberOfCriticalTools > 0 else { return 0 }
        return Int((Float(numberOfCompletedCriticalTools) / Float(numberOfCriticalTools)) * 100.0)
    }
}


// MARK: - ThunderTable Conformance
extension ProgressViewModel: Row {
    
    var cellClass: UITableViewCell.Type? {
        return ProgressTableViewCell.self
    }
    
    var accessoryType: UITableViewCellAccessoryType? {
        get {
            return UITableViewCellAccessoryType.none
        }
        set {}
    }
    
    func configure(cell: UITableViewCell, at indexPath: IndexPath, in tableViewController: TableViewController) {
        
        guard let progressCell = cell as? ProgressTableViewCell else { return }
        
        progressCell.criticalToolsTitleLabel.text = NSLocalizedString("PROGRESS_CELL_CRITICALTOOLS_TITLE", value: "CRITICAL TOOLS", comment: "Title displayed beneath count of critical tools completed")
        progressCell.criticalToolsValueLabel.text = String(format: NSLocalizedString("PROGRESS_CELL_CRITICALTOOLS_COMPLETIONCOUNT", value: "%lu/%lu", comment: "Displays the count of critical tools completed out of a maximum number. Example '1/20'"), arguments: [self.numberOfCompletedCriticalTools, self.numberOfCriticalTools])
        progressCell.subStepsTitleLabel.text = NSLocalizedString("PROGRESS_CELL_SUBSTEPS_TITLE", value: "SUB-STEPS", comment: "Title displayed beneath count of substeps completed")
        progressCell.subStepsValueLabel.text = String(format: NSLocalizedString("PROGRESS_CELL_SUBSTEPS_COMPLETIONCOUNT", value: "%lu/%lu", comment: "Displays the count of substeps completed out of a maximum number. Example '1/20'"), arguments: [self.numberOfCompletedSubSteps, self.numberOfSubSteps])
        
        progressCell.hierarchyLabel.text = self.moduleHierarchy
        progressCell.overallPercentageCompleteLabel.text = String(format: NSLocalizedString("PROGRESS_CELL_OVERALL_COMPLETEPERCENTAGE", value: "%lu%% COMPLETED", comment: "Displays the percentage of the directory completed. Example '10% COMPLETED'"), arguments: [percentageComplete])
        
        progressCell.moduleLabel.text = self.moduleTitle
        
        progressCell.moduleProgressView.progress = Double(self.percentageComplete)
        progressCell.hierarchyView.backgroundColor = ModuleColourUtility.colour(for: moduleHierarchy)
        
        let hierarchyColor = ModuleColourUtility.colour(for: moduleHierarchy)
        progressCell.moduleProgressView.barColour = hierarchyColor
        progressCell.moduleProgressView.backgroundColor = hierarchyColor.withAlphaComponent(0.2)
    }
}
