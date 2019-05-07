//
//  ToolkitTableViewController+SwipeableCells.swift
//  Cash In Emergencies
//
//  Created by Joel Trew on 13/10/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import Foundation
import UIKit
import DMSSDK
import QuickLook
import ThunderBasics
import SwipeCellKit


// Bridges iOS11's UIContextualAction and SwipeCellKit's SwipeAction classes
struct SwipeBridgingAction {
    
    // Title of the action
    var title: String?
    // Icon image showing what the action does
    var image: UIImage?
    // System style of the action, destrcutive or normal
    var style: SwipeStyle
    // The background colour showing behind the action
    var backgroundColor: UIColor? = nil
    // Closure to perform when the user selects an action, returns if it was successful
    var handler: (() -> Bool)?
    
    init(title: String?, image: UIImage?, style: SwipeStyle, handler: (() -> Bool)?) {
        self.title = title
        self.image = image
        self.style = style
        self.handler = handler
    }
    
    
    @available(iOS 11.0, *)
    /// Creates an iOS11+ UIContextualAction class to provide for the native syste frameowrk method trailingSwipeActionsConfigurationForRowAt:
    ///
    ///
    /// - Returns: a UIContextual action class with properties passed from this object
    func contextualAction() -> UIContextualAction {
        
        func contextualStyle() -> UIContextualAction.Style {
            switch self.style {
            case .normal:
                    return UIContextualAction.Style.normal
            case .destructive:
                    return UIContextualAction.Style.destructive
            }
        }
        
        let action = UIContextualAction(style: contextualStyle(), title: self.title, handler: { (action, view, completionHandler) in
            completionHandler(self.handler?() ?? true)
        })
        
        action.backgroundColor = self.backgroundColor
        action.image = image
        
        return action
    }
    
    /// Creates a SwipeCellKit SwipeAction class for supporting swipable cells iOS10 and below
    ///
    /// - Returns: a SwipeAction class with the properties on this object applied to it
    func swipeAction() -> SwipeAction {
        
        func swipeStyle() -> SwipeActionStyle {
            switch self.style {
            case .normal:
                return SwipeActionStyle.default
            case .destructive:
                return SwipeActionStyle.destructive
            }
        }
        
        let action = SwipeAction(style: swipeStyle(), title: self.title, handler: { (action, indexPath) in
            let _ = self.handler?()
        })
        
        action.backgroundColor = self.backgroundColor
        action.image = image
        
        return action
    }
    
    enum SwipeStyle {
        case normal
        case destructive
    }
}

extension ToolkitTableViewController {
    
    
    /// Creates a swipeable action for exporting a document
    ///
    /// - Parameters:
    ///   - directory: the tool(directory) the user is exporting
    ///   - indexPath: the index path of the row that was swiped
    /// - Returns: A compatible swipeAction for iOS10/11 support
    func addExportOptionIfAvailible(with directory: Directory, at indexPath: IndexPath) -> SwipeBridgingAction? {
        //Export
        
        guard let attachmentUrl = directory.attachments?.first?.url else {
            return nil
            
        }
        
        let exportFile = ContentManager().localFileURL(for: attachmentUrl)
        
        let exportTitle = exportFile == nil ? NSLocalizedString("WORKFLOW_TOOL_BUTTON_DOWNLOAD", value: "DOWNLOAD", comment: "Button that downloads a tool") : NSLocalizedString("WORKFLOW_TOOL_BUTTON_OPEN", value: "OPEN", comment: "Button that opens a tool that was already downloaded")
        var exportOption = SwipeBridgingAction(title: exportTitle, image: #imageLiteral(resourceName: "swipe_action_export"), style: .normal) { () -> Bool in
        
            if let attachment = directory.attachments?.first, let toolTitle = attachment.title {
                Tracker.trackEventWith(toolTitle, action: "Download", label: nil, value: nil)
            }
        
            DispatchQueue.main.async {
                HUDActivityView.addHUDWith(identifier: "export", to: self.view.window, withText: "Exporting document", style: .default)
                 self.toggleUserInteraction(on: false)
            }
           
            
            FileExporter.exportFile(attachmentUrl, updateHandler: nil, completionHandler: { (localFileUrl) in
                
                DispatchQueue.main.async {
                    HUDActivityView.removeHUDWith(identifier: "export", in: self.view.window)
                    self.toggleUserInteraction(on: true)
                    if let localFileUrl = localFileUrl {
                        self.documentController = UIDocumentInteractionController(url: localFileUrl)
                        self.documentController?.delegate = self
                        self.documentController?.presentPreview(animated: true)
                    }
                }
            })
            
            return true
        }
        
        exportOption.backgroundColor = UIColor(red: 237.0/255.0, green: 27.0/255.0, blue: 46.0/255.0, alpha: 1.0)
        return exportOption
    }
    
    /// Creates a swipeable action for adding a note to a tool
    ///
    /// - Parameters:
    ///   - directory: the tool(directory) the user is adding a note to
    ///   - indexPath: the index path of the row that was swiped
    /// - Returns: A compatible swipeAction for iOS10/11 support
    func addNoteOption(for directory: Directory, at indexPath: IndexPath) -> SwipeBridgingAction {
        //Note
        let noteOptionTitle = (ProgressManager().note(for: directory.identifier) == nil) ? NSLocalizedString("WORKFLOW_TOOL_BUTTON_ADDNOTE", value: "ADD NOTE", comment: "Button that shows a view to add a note") : NSLocalizedString("WORKFLOW_TOOL_BUTTON_EDITNOTE", value: "EDIT NOTE", comment: "Button that shows a view to edit an existing note")
        
        var noteOption = SwipeBridgingAction(title: noteOptionTitle, image: #imageLiteral(resourceName: "swipe_action_note_add"), style: .normal) { () -> Bool in
            
            DispatchQueue.main.async {
                self.addNote(for: directory, completion: {
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                })
                
                return
            }
            
            return true
        }
        
        noteOption.backgroundColor = UIColor(red: 237.0/255.0, green: 27.0/255.0, blue: 46.0/255.0, alpha: 1.0)
        return noteOption
    }
    
    /// Creates a swipeable action for tagging a tool a 'critical'
    ///
    /// - Parameters:
    ///   - directory: the tool(directory) the user is tagging as critical
    ///   - indexPath: the index path of the row that was swiped
    /// - Returns: A compatible swipeAction for iOS10/11 support
    func addCriticalToolOption(for directory: Directory, at indexPath: IndexPath) -> SwipeBridgingAction? {
        //If it's marked as critical by DMS don't let them change it
        let _criticalTool = directory.metadata?["critical_path"] as? Bool ?? false
        
        // Only run if block criticalTool is nil or false
        if !_criticalTool  {
            
            //If its not marked as critical by user, give option
            
            let progressManager = ProgressManager()
            
            let toolOptionTitle = progressManager.userCriticalTool(for: directory.identifier) ? NSLocalizedString("WORKFLOW_TOOL_BUTTON_UNMARK", value: "UNMARK", comment: "Button that removes the critical tool mark from a tool") : NSLocalizedString("WORKFLOW_TOOL_BUTTON_MARK", value: "MARK", comment: "Button that adds the critical tool mark to a tool")
            var toolOption = SwipeBridgingAction(title: toolOptionTitle, image: #imageLiteral(resourceName: "swipe_action_critical_path_enable"), style: .normal, handler: { () -> Bool in
                
                progressManager.toggleMarkToolAsUserCritical(for: directory.identifier)
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                
                DispatchQueue.global().async {
                    ToolIndexManager.shared.indexTool(directory, completionHandler: { error in
                        self.reload(with: nil)
                    })
                }
                
                if let tool = directory.attachments?.first, let toolTitle = tool.title {
                    Tracker.trackEventWith(toolTitle, action: progressManager.userCriticalTool(for: directory.identifier) ? "Unmarked as critical" : "Marked as critical", label: nil, value: nil)
                }
                
                return true
            })
            
            toolOption.backgroundColor = UIColor(red: 237.0/255.0, green: 27.0/255.0, blue: 46.0/255.0, alpha: 1.0)
            return toolOption
        }
        
        return nil
    }
}


// Use new iOS11 trailingSwipeActionsConfigurationForRowAt swipe methods if availible
@available(iOS 11.0, *)
extension ToolkitTableViewController {
    
    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if let _toolDisplayed = data[indexPath.section].rows[indexPath.row] as? Tool, let directory = _toolDisplayed.module() {
            
            var actions = [UIContextualAction]()
            
            // Export
            if let exportOption = self.addExportOptionIfAvailible(with: directory, at: indexPath) {
                actions.append(exportOption.contextualAction())
            }
            
            // Note
            actions.append(addNoteOption(for: directory, at: indexPath).contextualAction())
        
            // Critical
            if let criticalToolOption = addCriticalToolOption(for: directory, at: indexPath) {
                actions.append(criticalToolOption.contextualAction())
            }

            // Actions
            let swipeActions = UISwipeActionsConfiguration(actions: actions)
            swipeActions.performsFirstActionWithFullSwipe = false
            
            return swipeActions
        }
        
        // Return empty array configuration as retuning nil provides default delete option
        return UISwipeActionsConfiguration(actions: [])
    }
}

// iOS10 and below use SwipeCellKit methods
extension ToolkitTableViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        // Only provide actions for swipes on the right side of the cell
        guard orientation == .right else { return nil }
        
        if let _toolDisplayed = data[indexPath.section].rows[indexPath.row] as? Tool, let directory = _toolDisplayed.module() {
            
            var actions = [SwipeAction]()
            
            // Export
            if let exportOption = self.addExportOptionIfAvailible(with: directory, at: indexPath) {
                actions.append(exportOption.swipeAction())
            }
            
            // Note
            actions.append(addNoteOption(for: directory, at: indexPath).swipeAction())
            
            // Critical
            if let criticalToolOption = addCriticalToolOption(for: directory, at: indexPath) {
                actions.append(criticalToolOption.swipeAction())
            }
        
            return actions
        }
        
        return nil
    }
}

extension ToolkitTableViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}
