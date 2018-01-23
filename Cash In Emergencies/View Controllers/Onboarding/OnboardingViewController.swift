//
//  OnboardingViewController.swift
//  Cash In Emergencies
//
//  Created by Matthew Cheetham on 16/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import UIKit
import AVKit
import DMSSDK
import ThunderBasics

/// The onboarding view responsible for showing the onboarding video and downloading the bundle content
class OnboardingViewController: UIViewController {
    
    /// Determines if the app has downloaded a bundle. This must be true before the user is shown the app
    private var hasDownloadedBundle: Bool = false
    
    /// Determines that the user is ready to enter the app. This happens when the user has finished watching the video or they have pressed skip
    private var userIsReadyToProceed: Bool = false
    
    /// Responsible for downloading the bundle
    let contentManager = ContentManager()
    
    /// Label displaying a welcome message
    @IBOutlet weak var titleLabel: UILabel!
    
    /// Label explaining the tutorial
    @IBOutlet weak var subtitleLabel: UILabel!
    
    /// Button that activates the video tutorial
    @IBOutlet weak var playTutorialButton: UIButton!
    
    /// Label that emulates the play button's text.
    @IBOutlet weak var buttonLabel: UILabel!
    
    /// Button that skips the tutorial
    @IBOutlet weak var skipTutorialButton: UIButton!
    
    //MARK: - Video playback
    @IBAction func handlePlayVideo(_ sender: UIButton) {
        
        if let _fileURL = Bundle.main.url(forResource: "onboarding_video", withExtension: "mp4") {
            
            let player = AVPlayer(url: _fileURL)
            
            let playerView = AVPlayerViewController()
            playerView.showsPlaybackControls = true
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        
            playerView.player = player
        
            present(playerView, animated: true, completion: nil)
            
            player.play()
            
            Tracker.trackEventWith("Pre-Onboarding", action: "Watch video", label: nil, value: nil)
        }
    }
    
    //MARK: - View dismiss
    
    /// Handles callbacks from the video player when it has finished playing the video
    ///
    /// - Parameter note: The notification sent from AVPlayer
    @objc func playerDidFinishPlaying(note: NSNotification) {
        
        userIsReadyToProceed = true
        dismiss(animated: true, completion: nil)
        markOnboardingComplete()
    }
    
    /// Marks the onboarding as done so it will not be shown again
    func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "CIEHasDoneOnboarding")
    }

    // Handles skip button. If the bundle is ready, we just dismiss but if not we throw up a loading indicator and make people wait
    @IBAction func pressedSkip(_ sender: Any) {
        
        MDCHUDActivityView.start(in: self.view.window, text: "Setting up")
        userIsReadyToProceed = true
        markOnboardingComplete()
    }
    
    //MARK: Bundle downloading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Timer.scheduledTimer(withTimeInterval: 1.0, block: {
            if self.userIsReadyToProceed == true && self.hasDownloadedBundle == true {
                MDCHUDActivityView.finish(in: self.view.window)
                self.dismiss(animated: true, completion: nil)
            }
        }, repeats: true)
        
        handleDownloadBundle()
        
        Tracker.trackEventWith("Pre-Onboarding", action: "Skip", label: nil, value: nil)
        
        titleLabel?.text = NSLocalizedString("WELCOME_TITLE", value: "Get started with the  RCRCM Cash in Emergencies Toolkit", comment: "Text welcoming the user to the app")
        subtitleLabel?.text = NSLocalizedString("WELCOME_SUBTITLE", value: "Watch our quick tutorial to find out how it can help you support those affected by emergencies.", comment: "Text asking the user to watch the tutorial")
        buttonLabel?.text = NSLocalizedString("WELCOME_BUTTON_WATCH", value: "Watch the Video Tutorial", comment: "Button that plays the video tutorial")
        skipTutorialButton?.setTitle(NSLocalizedString("WELCOME_BUTTON_SKIP", value: "SKIP", comment: "Button that skips the tutorial"), for: .normal)
    }
    
    /// Displays an alert to the user letting them know that the download of the bundle failed and asks them to retry.
    func handleErrorDownloading() {
        let downloadError = UIAlertController(title: "Sorry", message: "We're having some trouble retrieving the app content. Please check your internet connection and try again", preferredStyle: .alert)
        downloadError.addAction(UIAlertAction(title: "Try again", style: .default, handler: { [weak self] (action) in
            self?.handleDownloadBundle()
        }))
        present(downloadError, animated: true, completion: nil)
    }
    
    /// Initiates a download of the latest bundle from the server
    func handleDownloadBundle() {
        
        contentManager.getBundleInformation(for: "1", language: nil) { (result) in
            
            switch result {
            case .success(let bundleInfo):
                
                if let url = bundleInfo.downloadURL {
                    
                    self.contentManager.downloadBundle(from: url, progress: { (progress, bytesDownloaded, totalBytes) in
                        
                    }, completion: { (success) in
                        
                        switch success {
                        case .success:
                            NotificationCenter.default.post(name: NSNotification.Name("ContentControllerBundleDidUpdate"), object: nil)
                            self.hasDownloadedBundle = true
                            if let _interval = bundleInfo.publishDate?.timeIntervalSince1970 {
                                UserDefaults.standard.set(_interval, forKey: "CurrentBundleTimestamp")
                            }
                        case .failure:
                            self.handleErrorDownloading()
                        }
                    })
                }
            case .failure(let error):
                self.handleErrorDownloading()
            }
        }
    }
}
