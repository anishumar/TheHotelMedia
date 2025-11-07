//
//  CustomVideoPlayer.swift
//  TheHotelMedia
//
//  Created by MAC on 16/12/24.
//

import SwiftUI
import AVKit

struct CustomVideoPlayer: UIViewRepresentable {
    let player: AVPlayer?
    var contentMode: AVLayerVideoGravity = .resizeAspectFill
    var backgroundColor: UIColor = .black // Added background color parameter
    var onReadyToPlay: (() -> Void)? = nil
    var onRateChange: ((Float) -> Void)? = nil
    var onTimeControlStatusChange: ((AVPlayer.TimeControlStatus) -> Void)? = nil

    func makeUIView(context: Context) -> AVPlayerView {
        return AVPlayerView(
            player: player,
            contentMode: contentMode,
            backgroundColor: backgroundColor, // Pass background color
            onReadyToPlay: onReadyToPlay,
            onRateChange: onRateChange,
            onTimeControlStatusChange: onTimeControlStatusChange
        )
    }

    func updateUIView(_ uiView: AVPlayerView, context: Context) {
        uiView.updatePlayer(player)
        uiView.updateContentMode(contentMode)
        uiView.updateBackgroundColor(backgroundColor) // Update background color
    }
}

class AVPlayerView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerRateObserver: NSKeyValueObservation?
    private var playerTimeControlObserver: NSKeyValueObservation?

    var onReadyToPlay: (() -> Void)?
    var onRateChange: ((Float) -> Void)?
    var onTimeControlStatusChange: ((AVPlayer.TimeControlStatus) -> Void)?

    init(player: AVPlayer?,
         contentMode: AVLayerVideoGravity,
         backgroundColor: UIColor, // Added background color parameter
         onReadyToPlay: (() -> Void)?,
         onRateChange: ((Float) -> Void)?,
         onTimeControlStatusChange: ((AVPlayer.TimeControlStatus) -> Void)? = nil) {
        super.init(frame: .zero)
        self.onReadyToPlay = onReadyToPlay
        self.onRateChange = onRateChange
        self.onTimeControlStatusChange = onTimeControlStatusChange
        setupPlayerLayer(contentMode: contentMode)
        updatePlayer(player)
        self.backgroundColor = backgroundColor // Set initial background color
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPlayerLayer(contentMode: AVLayerVideoGravity) {
        playerLayer.videoGravity = contentMode
        layer.addSublayer(playerLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func updatePlayer(_ player: AVPlayer?) {
        playerLayer.player = player
        observeReadyToPlay(for: player?.currentItem)
        observeRate(for: player)
        observeTimeControlStatus(for: player)
    }

    func updateContentMode(_ contentMode: AVLayerVideoGravity) {
        playerLayer.videoGravity = contentMode
    }

    func updateBackgroundColor(_ color: UIColor) {
        self.backgroundColor = color // Update background color dynamically
    }

    private func observeReadyToPlay(for item: AVPlayerItem?) {
        playerStatusObserver?.invalidate()
        playerStatusObserver = nil
        
        guard let item = item else { return }
        
        playerStatusObserver = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                self.onReadyToPlay?()
            } else if item.status == .failed {
                print("Player failed with error: \(String(describing: item.error))")
            }
        }
    }

    private func observeRate(for player: AVPlayer?) {
        playerRateObserver?.invalidate()
        playerRateObserver = nil
        
        guard let player = player else { return }
        
        playerRateObserver = player.observe(\.rate, options: [.new, .initial]) { [weak self] player, _ in
            self?.onRateChange?(player.rate)
        }
    }

    private func observeTimeControlStatus(for player: AVPlayer?) {
        playerTimeControlObserver?.invalidate()
        playerTimeControlObserver = nil
        
        guard let player = player else { return }
        
        playerTimeControlObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            self?.onTimeControlStatusChange?(player.timeControlStatus)
        }
    }

    deinit {
        playerStatusObserver?.invalidate()
        playerRateObserver?.invalidate()
        playerTimeControlObserver?.invalidate()
    }
}

