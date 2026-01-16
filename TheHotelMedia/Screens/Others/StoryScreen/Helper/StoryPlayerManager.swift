//
//  StoryPlayerManager.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import AVFoundation
import Combine
import SwiftUI

class StoryPlayerManager: ObservableObject {
    @Published var progress: Float = 0.0
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    
    var onVideoFinished: (() -> Void)?
    var onProgressUpdate: ((Float) -> Void)?
    
    init() {}
    
    func setupPlayer(url: URL) {
        cleanup()
        
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.automaticallyWaitsToMinimizeStalling = false
        
        self.playerItem = item
        self.player = newPlayer
        
        setupObservers()
    }
    
    func play() {
        DispatchQueue.main.async { [weak self] in
            guard let player = self?.player else { return }
            player.play()
            self?.isPlaying = true
        }
    }
    
    func pause() {
        DispatchQueue.main.async { [weak self] in
            self?.player?.pause()
            self?.isPlaying = false
        }
    }
    
    func seek(to time: CMTime) {
        DispatchQueue.main.async { [weak self] in
            self?.player?.seek(to: time)
        }
    }
    
    func reset() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.player?.seek(to: .zero)
            self.progress = 0.0
        }
    }
    
    var avPlayer: AVPlayer? {
        return player
    }
    
    private func setupObservers() {
        guard let player = player, let item = playerItem else { return }
        
        // Time observer for progress
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateProgress(currentTime: time)
        }
        
        // Video end observer
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.handleVideoEnd()
        }
        
        // Player status observer using KVO
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            self?.handleStatusChange(item.status)
        }
        
        // Time control status observer using KVO
        timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            self?.handleTimeControlStatus(player.timeControlStatus)
        }
    }
    
    private func updateProgress(currentTime: CMTime) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let duration = self.playerItem?.duration,
                  duration.isValid && !duration.isIndefinite else { return }
            
            let currentSeconds = CMTimeGetSeconds(currentTime)
            let totalSeconds = CMTimeGetSeconds(duration)
            
            guard totalSeconds > 0 else { return }
            
            let newProgress = Float((currentSeconds / totalSeconds) * 100.0)
            self.progress = min(newProgress, 100.0)
            self.onProgressUpdate?(self.progress)
        }
    }
    
    private func handleVideoEnd() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progress = 100.0
            self.pause()
            self.onVideoFinished?()
        }
    }
    
    private func handleStatusChange(_ status: AVPlayerItem.Status) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch status {
            case .readyToPlay:
                self.isLoading = false
            case .failed:
                self.isLoading = false
                print("Player item failed: \(self.playerItem?.error?.localizedDescription ?? "Unknown error")")
            case .unknown:
                self.isLoading = true
            @unknown default:
                break
            }
        }
    }
    
    private func handleTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch status {
            case .playing:
                self.isLoading = false
                self.isPlaying = true
            case .paused:
                self.isPlaying = false
            case .waitingToPlayAtSpecifiedRate:
                self.isLoading = true
            @unknown default:
                break
            }
        }
    }
    
    func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        
        statusObserver?.invalidate()
        statusObserver = nil
        
        timeControlObserver?.invalidate()
        timeControlObserver = nil
        
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
        progress = 0.0
        isPlaying = false
        isLoading = false
    }
    
    deinit {
        cleanup()
    }
}
