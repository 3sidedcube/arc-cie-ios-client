//
//  ToolkitTable.swift
//  Cash In Emergencies
//
//  Created by Matthew Cheetham on 22/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import UIKit
import ThunderTable
import DMSSDK
import QuickLook
import ThunderBasics

class ToolkitTableViewController: TableViewController {

    /// Any identifiers in this list are modules that should be expanded. The children of these modules will be included in `displayableModuleObjects`
    var expandedModuleIdentifiers = [Int]()
    
    /// A dictionary where the key is the module identifier of every module (recursively) through the structure.json and it's value being an integer of what depth level it is app. Zero based.
    var moduleDepthMap = [Int: Int]()
    
    /// Handles delaying searches by 0.5 seconds
    private var timer: Timer?
    
    /// The URL of the module a user may have selected to display. We have to have this due to the way QLPreview works using delegates
    internal var displayableURL: URL?
    
    /// The standard calculated data source for displaying modules. Prevents recreating where uncecessary
    private var standardDataSource: [Section]?
    
    /// The data source calculated to display only critical tools. Prevents recreating where unecessary
    private var criticalToolsDataSource: [Section]?
    
    var documentController: UIDocumentInteractionController?
    
    /// Value that stores the content Offset of the tableView before dispearing so it can be restored later to avoid the tableView jumping
    var previousContentOffset: CGPoint? = nil

    @IBOutlet weak var searchBar: UISearchBar!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(indexDidRefresh), name: NSNotification.Name("ModulesDidIndex"), object: nil)
    }
    
    func mapTree(for modules: [Directory], level: Int) {

        for module in modules {

            moduleDepthMap[module.identifier] = level

            if let _submodules = module.directories {
                mapTree(for: _submodules, level: level + 1)
            }
        }
    }
    
    /// A compiled array of sections to display. This computed variable works out which sections are collapsed or expanded and arranges the views appropriately
    var displayableModuleObjects: [TableSection]? {
        
        var displayableSections = [TableSection]()
        
        guard let modules = DirectoryManager().directories else {
            return displayableSections
        }
        
        for _module in modules {
            
            var rows = [Row]()
            
            //Add top level row
            let moduleView = ModuleView(with: _module)
            rows.append(moduleView)
            
            if expandedModuleIdentifiers.contains(_module.identifier) {
                moduleView.shouldShowModuleRoadmap = true
            }
            
            //Add sub rows if expanded
            if let _moduleChildren = _module.directories, expandedModuleIdentifiers.contains(_module.identifier) {
                
                for moduleStep in _moduleChildren {
                    
                    let moduleStepView = Step(with: moduleStep)
                    rows.append(moduleStepView)
                    
                    //Check if the step has substeps and add them
                    
                    if let _moduleStepChildren = moduleStep.directories {
                        
                        for moduleSubStep in _moduleStepChildren {
                            
                            let moduleSubStepView = SubStep(with: moduleSubStep)
                            rows.append(moduleSubStepView)
                            
                            //Check for tools
                            if let _tools = moduleSubStep.directories,  expandedModuleIdentifiers.contains(moduleSubStep.identifier) {
                                
                                moduleSubStepView.shouldShowAddNoteButton = true
                                
                                for tool in _tools {
                                    let toolView = Tool(with: tool)
                                    toolView.parentHierarchy = _module.metadata?["hierarchy"] as? String
                                    rows.append(toolView)
                                }
                            }
                        }
                    }
                }
            }
            
            let moduleSection = TableSection(rows: rows, header: nil, footer: nil, selectionHandler: nil)
            displayableSections.append(moduleSection)
            
        }
        
        //Update stuff
        moduleDepthMap.removeAll()
        mapTree(for: modules, level: 0)
        
        return displayableSections
        
        //        let moduleManager = ModuleManager()
        //
        //        if let _modules = moduleManager.modules {
        //            let section = TableSection(rows: _modules)
        //
        //            return [section]
        //        }
        //        return nil
        
    }
    
    //    override var childViewControllerForStatusBarStyle: UIViewController? {
    //        return toolkitTableViewController
    //    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _displayableObjects = displayableModuleObjects {
            standardDataSource = _displayableObjects
        }
        
        redraw()
        
        reload { (error) in
            self.redraw()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let previousContentOffset = previousContentOffset {
            tableView.contentOffset = previousContentOffset
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previousContentOffset = tableView.contentOffset
    }
    
    @objc func indexDidRefresh() {
        DispatchQueue.main.async {
            HUDActivityView.addHUDWith(identifier: "reload", to: self.view.window)
        }
        self.reload { [weak self] (error) in
            if error == nil {
                HUDActivityView.removeHUDWith(identifier: "reload", in: self?.view.window)
                self?.redraw()
            }
        }
    }
    
    func reload(with completionHandler: ((Error?) -> Void)?) {
        
        if let _displayableObjects = displayableModuleObjects {
            standardDataSource = _displayableObjects
        }
        
        ToolIndexManager.shared.searchCriticalTools { (error, tools) in
            
            let orderedItems = Dictionary(grouping: tools, by: { tool in tool.parent })
            
            var sections = [Section]()
            
            for (key, values) in orderedItems {
                
                var tools = [Tool]()
    
                for value in values {
                    let tool = Tool(with: value.tool)
                    tool.parentHierarchy = value.parentHierarchy
                    tools.append(tool)
                }
                
                let newSection = TableSection(rows: tools, header: key, footer: nil, selectionHandler: nil)
                sections.append(newSection)
            }
            
            // Sort the sections alphanumerically by the section header
            let sortedSections = sections.sorted(by: { (sectionA, sectionB) -> Bool in
                guard let headerA = sectionA.header, let headerB = sectionB.header else {
                    return false
                }
                
                return headerA < headerB
            })
        
            OperationQueue.main.addOperation({
                self.criticalToolsDataSource = sortedSections
                if let completionHandler = completionHandler {
                    completionHandler(nil)
                }
            })
        }
    }
    
    func redraw() {
        
        if let _standardRows = standardDataSource {
            data = _standardRows
        }
    }
    
    func showCriticalToolsOnly() {
        
        if let _criticalRows = criticalToolsDataSource {
            data = _criticalRows
        }
    }
    
    func handleToggle(of module: Directory) {
        
        let moduleID = module.identifier
        
        if expandedModuleIdentifiers.contains(moduleID) {
            if let removalIndex = expandedModuleIdentifiers.index(of: moduleID) {
                expandedModuleIdentifiers.remove(at: removalIndex)
            }
            if let moduleTitle = module.directoryTitle, let hierarchy = module.metadata?["hierarchy"] as? String {
                Tracker.trackEventWith("\(hierarchy) \(moduleTitle)", action: "Collapsed", label: nil, value: nil)
            }
        } else {
            expandedModuleIdentifiers.append(moduleID)
            if let moduleTitle = module.directoryTitle, let hierarchy = module.metadata?["hierarchy"] as? String {
                Tracker.trackEventWith("\(hierarchy) \(moduleTitle)", action: "Expanded", label: nil, value: nil)
            }
        }
        
        standardDataSource = displayableModuleObjects
        redraw()
    }
    
    func handleLoadMarkdown(for contentPath: String, with attachedFile: FileDescriptor? = nil) {
        
        let contentURL = ContentManager().fileUrl(from: contentPath)
        
        guard let presentingView = self.parent else {
            return
        }
        
        if let _contentURL = contentURL, let jsonFileData = try? Data(contentsOf: _contentURL) {
            
            let markdown = String(data: jsonFileData, encoding: .utf8)
            
            if let _markdownNavView = UIStoryboard(name: "Document_Viewing", bundle: Bundle.main).instantiateViewController(withIdentifier: "markdownNavigationControllerIdentifier") as? UINavigationController, let markdownViewContainer = _markdownNavView.viewControllers.first as? DocumentViewerContainerViewController {
                
                markdownViewContainer.attachedFile = attachedFile
                
                let _ = markdownViewContainer.view
                
                let markdownView = markdownViewContainer.childViewControllers.first as? MarkdownViewController
                
                if let _markdown = markdown {
                    markdownView!.loadMarkdown(string: _markdown)
                }
                presentingView.showDetailViewController(_markdownNavView, sender: self)
            }
        }
    }
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        super.scrollViewDidScroll(scrollView)
        self.parent?.view.setNeedsUpdateConstraints()
        self.parent?.view.setNeedsLayout()
    }
    
    func addNote(for module: Directory, completion: (() -> Void)? = nil) {
        
        let noteViewNavigationController = UIStoryboard(name: "Notes", bundle: Bundle.main).instantiateInitialViewController() as? UINavigationController
        
        if let noteViewNavigationController = noteViewNavigationController, let noteViewController = noteViewNavigationController.topViewController as? NoteAddViewController {
            
            OperationQueue.main.addOperation({
                noteViewController.module = module
                noteViewController.completionHandler = completion
                self.present(noteViewNavigationController, animated: true, completion: nil)
            })
        }
    }
}

extension ToolkitTableViewController: QLPreviewControllerDataSource {
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        
        if let _URL = displayableURL {
            return _URL as NSURL
        }
        return NSURL(fileURLWithPath: "lol")
    }
}

extension ToolkitTableViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(handleSearch), userInfo: nil, repeats: false)
    }
    
    @objc func handleSearch() {
        
        guard let searchText = searchBar.text else {
            redraw()
            return
        }
        
        if searchText == "" {
            redraw()
            return
        }
        
        Tracker.trackEventWith("Search", action: searchText, label: nil, value: nil)
        
        ToolIndexManager.shared.searchTools(using: searchText) { (error, tools) in
            
            let orderedItems = Dictionary(grouping: tools, by: { tool in tool.parent })
            
            var sections = [Section]()
            
            for (key, value) in orderedItems {
                
                let tools = value.flatMap({ Tool(with: $0.tool) })
                let newSection = TableSection(rows: tools, header: key, footer: nil, selectionHandler: nil)
                sections.append(newSection)
            }
            
            OperationQueue.main.addOperation({
                self.data = sections
            })
        }
    }
}
