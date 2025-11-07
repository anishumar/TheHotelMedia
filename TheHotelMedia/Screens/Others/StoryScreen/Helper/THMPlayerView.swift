//
//  THMPlayerView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import Foundation
import UIKit
import AVKit

class THMPlayerView: UIView {
    
    // MARK: Public Properties
    weak var player: AVPlayer?
    var duration: Double = 0.0
    var state: THMMediaState = .notStarted
    var mediaState: ((THMMediaState, Double) -> ())?
    var onReadyToPlay: (() -> Void)?
    
    let contentView = UIView()
    
    // MARK: Private Properties
    private let playerLayer = AVPlayerLayer()
    private var url: URL?
    private let cacheManager: THMCacheManager
     // MARK: - Initializers
    override init(frame: CGRect) {
        self.cacheManager = THMCacheManager()
        super.init(frame: frame)
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        setupPlayer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
        player = nil
    }
    
    required init?(coder: NSCoder) { nil }

    func startVideo(url: URL?) {
        guard let validatedUrl = url else { return }
        if self.url == url { return }
        self.url = validatedUrl
        addActivityIndicatory()
        // stop video if it's playing before video request
        stopVideo()
        guard let url = url else { return }
        setupPlayer(url)
//        cacheManager.loadVideo(from: url) { [weak self] result in
//            switch result {
//            case .success(let url):
//                self?.setupPlayer(url)
//            case .failure(let error):
//                print(error)
//            }
//        }
    }
  
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem, playerItem.status == .readyToPlay {
                // Video is ready to play
                removeActivityIndicatory()
                onReadyToPlay?()
            } else if let playerItem = object as? AVPlayerItem, playerItem.status == .failed {
                // Handle error
                print("Player Item Failed: \(String(describing: playerItem.error?.localizedDescription))")
            }
        }
        
        if keyPath == "timeControlStatus" {
            if player?.timeControlStatus == .playing {
                removeActivityIndicatory()
                state = .started
                mediaState?(state, duration)
            } else if player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                addActivityIndicatory()
            }
        }
        
        if keyPath == "rate" {
            if let rate = player?.rate {
                if rate > 0 {
                    mediaState?(.playbackStarted, duration)
                } else if rate == 0 {
                    mediaState?(.playbackStopped, duration)
                }
            }
        }
    }
    
    private func getVideoLength(videoURL: URL) {
        duration = AVURLAsset(url: videoURL).duration.seconds
    }
    
    private func stopAndRestartVideo() {
        player?.seek(to: .zero)
    }
    
    private func stopVideo() {
        if player?.timeControlStatus == .playing {
            player?.pause()
            player?.seek(to: .zero)
            state = .stopped
        }
    }
    
    func restartVideo() {
        if player?.timeControlStatus == .paused {
            player?.seek(to: .zero)
            player?.play()
            state = .restart
        }
    }

    private func setupPlayer(_ url: URL) {
        let playerItem = AVPlayerItem(url: url)
        
        // Observe the status of the player item
        playerItem.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        
        // Replace the current player item
        if self.player == nil {
            self.player = AVPlayer(playerItem: playerItem)
        } else {
            self.player?.replaceCurrentItem(with: playerItem)
        }
        
        self.player?.addObserver(self, forKeyPath: "timeControlStatus", options: .new, context: nil)
        self.player?.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
        self.player?.automaticallyWaitsToMinimizeStalling = false
        self.getVideoLength(videoURL: url)
        
        self.playerLayer.player = self.player
        self.playerLayer.videoGravity = .resizeAspectFill
        self.playerLayer.backgroundColor = UIColor.black.cgColor
        
        playerLayer.removeFromSuperlayer()
        self.contentView.layer.addSublayer(self.playerLayer)
        
        state = .ready
        mediaState?(.ready, duration)
        addObserverToVideo()
    }
    
    private func addObserverToVideo() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restartVideoObserver),
            name: .restartVideoTHM,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopVideoObserver),
            name: .stopVideoTHM,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopAndRestartVideoObserver),
            name: .stopAndRestartVideoTHM,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(replaceCurrentItemObserver),
            name: .replaceCurrentItemTHM,
            object: nil
        )
    }
}

extension THMPlayerView {
    private func addActivityIndicatory() {
        removeActivityIndicatory()
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        let view = UIView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        view.backgroundColor = .black
        view.tag = 999
        self.addSubview(view)
        let activityView = UIActivityIndicatorView(style: .large)
        activityView.color = UIColor.lightGray.withAlphaComponent(0.7)
        activityView.frame = CGRect(x: w / 2, y: h / 2, width: .zero, height: .zero)
        view.addSubview(activityView)
        addConst(view: activityView)
        activityView.startAnimating()
    }
    
    private func setupPlayer() {
        self.addSubview(contentView)
        contentView.frame.size.width = self.frame.size.width
        contentView.frame.size.height = self.frame.size.height
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor,constant: 0),
            contentView.rightAnchor.constraint(equalTo: self.rightAnchor,constant: 0),
            contentView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor,constant: 0),
            contentView.topAnchor.constraint(equalTo: self.topAnchor,constant: 0),
        ])
        playerLayer.frame = contentView.frame
    }
    
    private func removeActivityIndicatory() {
       self.subviews.forEach { (view) in
            if view.tag == 999 {
                view.removeFromSuperview()
            }
        }
    }
    
    private func addConst(view: UIActivityIndicatorView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: view.superview!.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: view.superview!.centerYAnchor)
        ])
    }
    
    @objc private func stopAndRestartVideoObserver() {
        stopAndRestartVideo()
    }
    
    @objc private func restartVideoObserver() {
        restartVideo()
    }
    
    @objc private func stopVideoObserver() {
        stopVideo()
    }
    
    @objc private func replaceCurrentItemObserver() {
        NotificationCenter.default.removeObserver(self)
        self.player?.replaceCurrentItem(with: nil)
        self.player?.removeObserver(self, forKeyPath: "timeControlStatus")
        self.player = nil
    }
}

