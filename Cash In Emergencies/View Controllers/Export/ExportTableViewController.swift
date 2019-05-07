//
//  ExportTableViewController.swift
//  Cash In Emergencies
//
//  Created by Matthew Cheetham on 13/10/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import UIKit
import ThunderBasics
import DMSSDK

class ExportTableViewController: UITableViewController {

    var documentcontroller: UIDocumentInteractionController?
    
    @IBOutlet weak var criticalPathLabel: UILabel!
    @IBOutlet weak var entireProgressLabel: UILabel!
    @IBOutlet weak var criticalPathExportButton: UIButton!
    @IBOutlet weak var entireProgressExportButton: UIButton!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var entireToolkitLabel: UILabel!
    @IBOutlet weak var criticalPathToolsLabel: UILabel!
    @IBOutlet weak var entireToolkitExportButton: UIButton!
    @IBOutlet weak var criticalPathToolsButton: UIButton!
    
    @IBAction func handleExportCriticalPath(_ sender: UIButton) {
        
        HUDActivityView.addHUDWith(identifier: "export_critical_path", to: view.window, withText: "Exporting", style: .default)
        
        defer {
            HUDActivityView.removeHUDWith(identifier: "export_critical_path", in: view.window)
        }
        
        if let criticalPathFile = CSVManager.exportModules(criticalOnly: true) {
         
            documentcontroller = UIDocumentInteractionController(url: criticalPathFile)
            documentcontroller?.presentOptionsMenu(from: sender.frame, in: view, animated: true)
        } else {
            presentError(ExportError.genericError)
        }
        
        Tracker.trackEventWith("Export content", action: "Export Critical Progress", label: nil, value: nil)
    }
    
    @IBAction func handleExportEntireProgress(_ sender: UIButton) {
        
        HUDActivityView.addHUDWith(identifier: "export_progress", to: view.window, withText: "Exporting", style: .default)
        
        defer {
            HUDActivityView.removeHUDWith(identifier: "export_progress", in: view.window)
        }

        if let criticalPathFile = CSVManager.exportModules(criticalOnly: false) {
            
            documentcontroller = UIDocumentInteractionController(url: criticalPathFile)
            documentcontroller?.presentOptionsMenu(from: sender.frame, in: view, animated: true)

        } else {
            presentError(ExportError.genericError)
        }
        
        Tracker.trackEventWith("Export content", action: "Export Entire Progress", label: nil, value: nil)
    }
    
    @IBAction func handleExportEntireToolkit(_ sender: UIButton) {
        
        let toolkitURL = urlForToolKitZip()
        if let _url = toolkitURL {
            showShareSheetFor(url: _url)
        }
        Tracker.trackEventWith("Export content", action: "Export Entire Toolkit", label: nil, value: nil)
    }
    
    @IBAction func handleExportCriticalPathTools(_ sender: UIButton) {
        let toolkitURL = urlForToolKitZip(onlyCritical: true)
        if let _url = toolkitURL {
            showShareSheetFor(url: _url)
        }
        
        Tracker.trackEventWith("Export content", action: "Export Critical Path Tools", label: nil, value: nil)
    }
    
    func showShareSheetFor(url: URL) {
        
        let shareView = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(shareView, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        }
        
        self.title = NSLocalizedString("EXPORT_NAVIGATION_TITLE", value: "Export Content", comment: "The title in the navigation bar at the top of view to export files")
        criticalPathLabel?.text = NSLocalizedString("EXPORT_CRITICALPATH_TEXT", value: "Critical Path Progress", comment: "Text for the row that allows exporting the critical path progress")
        entireProgressLabel?.text = NSLocalizedString("EXPORT_ENTIREPATH_TEXT", value: "Entire Progress", comment: "Text for the row that allows exporting the entire progress of the user")
        criticalPathExportButton?.setTitle(NSLocalizedString("EXPORT_BUTTON_EXPORT", value: "Export", comment: "Button that exports user content"), for: .normal)
        entireProgressExportButton?.setTitle(NSLocalizedString("EXPORT_BUTTON_EXPORT", value: "Export", comment: "Button that exports user content"), for: .normal)
        doneButton?.title = NSLocalizedString("EXPORT_BUTTON_DONE", value: "Done", comment: "Button to dismiss the export view")
        entireToolkitLabel?.text = NSLocalizedString("EXPORT_ENTIRETOOLKIT_TEXT", value: "Entire Toolkit", comment: "Text for the row that allows exporting the entire toolkit")
        criticalPathToolsLabel?.text = NSLocalizedString("EXPORT_CRITICALPATHTOOLS_TEXT", value: "Critical Path Tools", comment: "Text for the row that allows exporting the critical path tools")
        entireToolkitExportButton?.setTitle(NSLocalizedString("EXPORT_BUTTON_EXPORT", value: "Export", comment: "Button that exports user content"), for: .normal)
        criticalPathToolsButton?.setTitle(NSLocalizedString("EXPORT_BUTTON_EXPORT", value: "Export", comment: "Button that exports user content"), for: .normal)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // Provides localised errors for when exporting fails
    enum ExportError: LocalizedError {
        
        // General non specific error
        case genericError
        
        var errorDescription: String? {
                return "There was a problem exporting the file you requested."
        }
    }
    
    /// Created a URL for the toolkit that can be shared so users can download a zip of the tools.
    ///
    /// - Parameter onlyCritical: If this parameter is set to true the zip will only contain critical tools
    /// - Returns: Returns a ZIP file URL for the users to download content with
     func urlForToolKitZip(onlyCritical: Bool = false) -> URL? {
        
        guard let baseURLString = Bundle.main.infoDictionary?["DMSSDKBaseURL"] as? String else {
            return nil
        }
        
        //Set base URL
        var url = URL(string: baseURLString)?.appendingPathComponent("projects/1/")
        
        var itemsToAppend = [URLQueryItem]()
        
        //Add language if required
        if let language = UserDefaults.standard.string(forKey: "ContentOverrideLanguage") {
            itemsToAppend.append(URLQueryItem(name: "language", value: language))
        } else {
            // if the language default use standard code
            if let preferredLangauge = Locale.preferredLanguages.first {
                itemsToAppend.append(URLQueryItem(name: "language", value: preferredLangauge))
            } else {
                //fallback to english
                itemsToAppend.append(URLQueryItem(name: "language", value: "en"))
            }
        }
        
        //Add critical only if required
        if onlyCritical == true {
            
            url?.appendPathComponent("directories/")
            
            itemsToAppend.append(URLQueryItem(name: "meta", value: "critical_path"))
            itemsToAppend.append(URLQueryItem(name: "value", value: "true"))
        }
        
        url?.appendPathComponent("files/export")
        
        guard let _url = url else {
            return nil
        }
        
        var components = URLComponents(string: _url.absoluteString)
        components?.queryItems = itemsToAppend

        if let componentsURLString = components?.string {
            return URL(string: componentsURLString)
        }
        
        return _url
    }
}

//extension ExportTableViewController: UIDocumentInteractionControllerDelegate {
//
//    func documentInteractionController(_ controller: UIDocumentInteractionController, willBeginSendingToApplication application: String?) {
//
//    }
//
//    func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
//
//    }
//}

