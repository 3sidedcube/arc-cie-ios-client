//
//  SettingsTableViewController.swift
//  Cash In Emergencies
//
//  Created by Matthew Cheetham on 24/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import UIKit
import AVKit
import DMSSDK
import ThunderBasics
import CloudKit

/// The view controller responsible for user settings and downloading the latest bundles. This view also facilitates language switching if available
class SettingsTableViewController: UITableViewController {
    
    //MARK: - Variables
    /// The label indicating whether or not content is available. This is in the first table view cell
    @IBOutlet weak var contentAvailableLabel: UILabel!
    
    /// The button that activates downloading of the latest bundle. Hidden by default.
    @IBOutlet weak var downloadButton: UIButton!
    
    /// A button that displays the current language short code and facilitates changing language when tapped
    @IBOutlet weak var currentLanguageButton: UIButton!
    
    /// The content controller responsible for loading locale and remote bundle information and facilitating downloads.
    let contentController = ContentManager()
    
    /// The bundle information from the server containing information about languages and download URLs
    var bundleInformation: BundleInformation? {
        didSet {
            contentController.cachedBundleInformation = bundleInformation
        }
    }
    
    /// Done button to dismiss the view
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    /// Label of cell for showing welcome tutorial video
    @IBOutlet weak var watchVideoLabel: UILabel!
    
    /// Subtitle label of cell for showing tutorial video
    @IBOutlet weak var watchVideoSubLabel: UILabel!
    
    /// Title label of cell for resetting user data
    @IBOutlet weak var resetDataTitleLabel: UILabel!
    
    /// Subtitle label of cell for resetting user data
    @IBOutlet weak var resetDataSubtitleLabel: UILabel!
    
    /// Title label of cell for changing language
    @IBOutlet weak var changeLanguageTitleLabel: UILabel!
    
    /// Subtitle label of cell for changing language
    @IBOutlet weak var changeLanguageSubtitleLabel: UILabel!
    //MARK: - VC Lifecycle & Drawing
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        }
        
        redraw()
        bundleInformation = contentController.cachedBundleInformation
        getBundleInformation()
        
        title = NSLocalizedString("SETTINGS_TITLE", value: "Settings", comment: "Title for the settings screen shown in the navigation bar")
        doneButton?.title = NSLocalizedString("SETTINGS_BUTTON_DONE", value: "Done", comment: "Done button to dismiss the settings view")
        downloadButton?.setTitle(NSLocalizedString("SETTINGS_BUTTON_DOWNLOAD", value: "Download", comment: "Download button shown when new content is available to download"), for: .normal)
        watchVideoLabel?.text = NSLocalizedString("SETTINGS_TUTORIAL_LABEL_TITLE", value: "Watch the video", comment: "Title Label of cell that triggers watching tutorial video")
        watchVideoLabel?.text = NSLocalizedString("SETTINGS_TUTORIAL_LABEL_SUBTITLE", value: "Watch the tutorial video", comment: "Subtitle Label of cell that triggers watching tutorial video")
        resetDataTitleLabel?.text = NSLocalizedString("SETTINGS_RESET_LABEL_TITLE", value: "Reset All Data", comment: "Title Label of cell that triggers resetting user data")
        resetDataSubtitleLabel?.text = NSLocalizedString("SETTINGS_RESET_LABEL_SUBTITLE", value: "Clears all progress and note data", comment: "Subtitle Label of cell that triggers resetting user data")
        changeLanguageTitleLabel?.text = NSLocalizedString("SETTINGS_LANGUAGE_LABEL_TITLE", value: "Change Language", comment: "Title Label of cell that presents options for changing language")
        changeLanguageSubtitleLabel?.text = NSLocalizedString("SETTINGS_LANGUAGE_LABEL_SUBTITLE", value: "Downloads the App Content in another Language", comment: "Subtitle Label of cell that presents options for changing language")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Tracker.trackPage("Settings")
    }
    
    func redraw() {
        
        let currentTimestamp = contentController.currentBundleTimestamp
        if let publishDate = bundleInformation?.publishDate, publishDate.timeIntervalSince1970 > currentTimestamp {
            
            downloadButton.isHidden = false
            contentAvailableLabel.text = NSLocalizedString("SETTINGS_LABEL_NEWCONTENT", value: "New Content Available", comment: "Indicates that there is new content available to download")
        } else if let publishDate = bundleInformation?.publishDate, publishDate.timeIntervalSince1970 == currentTimestamp {
            
            downloadButton.isHidden = true
            contentAvailableLabel.text = NSLocalizedString("SETTINGS_LABEL_UPTODATE", value: "Content up to date", comment: "Indicates that the content is up to date and no update is available")
        } else {
            
            downloadButton.isHidden = true
            contentAvailableLabel.text = NSLocalizedString("SETTINGS_LABEL_UPDATECHECKING", value: "Checking for updates...", comment: "Indicates that the app is currently checking for updates")
        }
        
        if let languages = bundleInformation?.availableLanguages, languages.count > 0 {
            currentLanguageButton.isEnabled = true
        }
        
        //Set language label
        if let language = UserDefaults.standard.string(forKey: "ContentOverrideLanguage") {
            currentLanguageButton.setTitle(language.uppercased(), for: .normal)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Table View Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            //Download section
            switch indexPath.row {
            case 0:
                //Perform update
                return
            default:
                return
            }
        case 1:
            switch indexPath.row {
            case 0:
                //Play video
                handlePlayVideo()
                return
            case 1:
                handleResetData()
                return
            case 2:
                //Change language
                handleLanguagePicker()
                return
            default:
                return
            }
        default:
            return
        }
    }
    
    //MARK: - Action handling
    /// Resets the user data so that the app works like a fresh install
    func handleResetData() {
        
        let resetDataAlert = UIAlertController(title: NSLocalizedString("SETTINGS_ALERT_RESET_TITLE", value: "Reset all data", comment: "Title of alert warning user that all data will be reset"), message: NSLocalizedString("SETTINGS_ALERT_RESET_MESSAGE", value: "This will clear all progress and notes recorded in the app", comment: "Message of alert warning user that all data will be reset"), preferredStyle: .alert)
        
        resetDataAlert.addAction(UIAlertAction(title: NSLocalizedString("SETTINGS_ALERT_RESET_BUTTON_OKAY", value: "Okay", comment: "Button to accept resetting user data"), style: .destructive, handler: { (action: UIAlertAction) in
            ProgressManager().clearAllUserValues()
        }))
        
        resetDataAlert.addAction(UIAlertAction(title: NSLocalizedString("SETTINGS_ALERT_RESET_BUTTON_CANCEL", value: "Cancel", comment: "Button to abort the resetting of user data"), style: .cancel, handler: nil))
        
        present(resetDataAlert, animated: true, completion: nil)
        
        Tracker.trackEventWith("Settings", action: "Reset all data", label: nil, value: nil)
    }
    
    
    /// Handles tapping of the download button on the bundle cell
    ///
    /// - Parameter sender: The download button
    @IBAction func handleDownloadButton(_ sender: UIButton) {
        
        let downloadWarning = UIAlertController(title: NSLocalizedString("SETTINGS_ALERT_DOWNLOAD_TITLE", value: "Warning!", comment: "Title of alert warning user that downloading data is dangerous"), message: NSLocalizedString("SETTINGS_ALERT_DOWNLOAD_MESSAGE", value: "We recommend you not to do this during an active operation, as the structure and content of the toolkit may have changed significantly", comment: "Message body of alert warning user that downloading data is dangerous while on an active operation"), preferredStyle: .alert)
        downloadWarning.addAction(UIAlertAction(title: NSLocalizedString("SETTINGS_ALERT_DOWNLOAD_BUTTON_ACCEPT", value: "Proceed", comment: "Button to proceed with downloading new bundle"), style: .destructive, handler: { [weak self] (action) in
            if let welf = self {
                welf.navigationItem.rightBarButtonItem?.isEnabled = false
                HUDActivityView.addHUDWith(identifier: "download", to: welf.view.window)
                sender.isEnabled = false
                welf.downloadBundle()
            }
        }))
        
        downloadWarning.addAction(UIAlertAction(title: NSLocalizedString("SETTINGS_ALERT_DOWNLOAD_BUTTON_CANCEL", value: "Cancel", comment: "Button to abort the downloading new bundle"), style: .cancel, handler: nil))
        present(downloadWarning, animated: true, completion: nil)
    }
    
    /// Presents the tutorial video and dismisses on completion
    func handlePlayVideo() {
        
        if let _fileURL = Bundle.main.url(forResource: "onboarding_video", withExtension: "mp4") {
            
            let player = AVPlayer(url: _fileURL)
            
            let playerView = AVPlayerViewController()
            playerView.showsPlaybackControls = true
            if #available(iOS 11.0, *) {
                playerView.exitsFullScreenWhenPlaybackEnds = true
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            }
            
            playerView.player = player
            
            present(playerView, animated: true, completion: nil)
            
            player.play()
        }
        
        Tracker.trackPage("Tutorial video")
    }
    
    /// Presents an action sheet with available languages that the user can select
    @IBAction func handleLanguagePicker() {
        
        let languagePicker = UIAlertController(title: NSLocalizedString("SETTINGS_ACTIONSHEET_LANGUAGE_TITLE", value: "Select Language", comment: "Title of action sheet that lists available languages to switch the app content to. User may select one option"), message: nil, preferredStyle: .actionSheet)
        
        if let languageOptions = bundleInformation?.availableLanguages {
            
            for language in languageOptions.reversed() {
                
                let languageString = Locale.current.localizedString(forIdentifier: language)
                
                languagePicker.addAction(UIAlertAction(title: languageString, style: .default, handler: { (action) in
                    
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    HUDActivityView.addHUDWith(identifier: "download_bundle", to: self.view.window)
                    UserDefaults.standard.set(language, forKey: "ContentOverrideLanguage")
                    self.downloadBundle()
                }))
            }
            
            languagePicker.addAction(UIAlertAction(title: NSLocalizedString("SETTINGS_ACTIONSHEET_LANGUAGE_BUTTON_CANCEL", value: "Cancel", comment: "Button to cancel switching app content language"), style: .cancel, handler: nil))
        }
        
        showDetailViewController(languagePicker, sender: self)
        
        Tracker.trackEventWith("Settings", action: "Change Language", label: nil, value: nil)
    }
    
    /// Dismisses the tutorial video on devices running iOS 10 when the video finishes playing
    ///
    /// - Parameter note: The notification that was sent from the player on completion of the video playback
    @objc func playerDidFinishPlaying(note: NSNotification) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Downloading
    func downloadBundle() {
        
        //Set base URL
        var url: URL?
        
        //Add language if required
        if let baseURL = self.bundleInformation?.downloadURL, let language = UserDefaults.standard.string(forKey: "ContentOverrideLanguage") {
            if let _newURL = URL(string: "\(baseURL)&language=\(language)") {
                url = _newURL
            }
        } else {
            url = self.bundleInformation?.downloadURL
        }
        
        guard let _url = url else {
            return
        }
        
        self.contentController.downloadBundle(from: _url, progress: { (progress, bytesDownloaded, totalBytes) in
            print(progress)
        }, completion: { [weak self] (result) in
            
            switch result {
            case .success:
                OperationQueue.main.addOperation({
                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    HUDActivityView.removeHUDWith(identifier: "download_bundle", in: self?.view.window)
                    NotificationCenter.default.post(name: NSNotification.Name("ContentControllerBundleDidUpdate"), object: nil)
                    
                    //Save and reload
                    if let _interval = self?.bundleInformation?.publishDate?.timeIntervalSince1970 {
                        UserDefaults.standard.set(_interval, forKey: "CurrentBundleTimestamp")
                    }
                    self?.redraw()

                })
            case .failure(let error):
                if let welf = self {
                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    UIAlertController.presentError(error, in: welf)
                }
            }
            }
        )
    }
    
    /// Downloads the latest bundle information and sets it to the `bundleInformation` variable. This causes the view to reload on completion
    func getBundleInformation() {
        
        let language = UserDefaults.standard.string(forKey: "ContentOverrideLanguage")
        contentController.getBundleInformation(for: "1", language: language) { [weak self] (result) in
            
            switch result {
            case .success(let information):
                
                self?.bundleInformation = information
                OperationQueue.main.addOperation({
                    self?.redraw()
                })
                
            case .failure(let error):
                if let welf = self {
                    OperationQueue.main.addOperation({
                        UIAlertController.presentError(error, in: welf)
                    })
                }
            }
        }
    }
}
