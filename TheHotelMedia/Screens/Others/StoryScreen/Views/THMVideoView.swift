//
//  THMVideoView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI
import AVKit

struct THMVideoView: UIViewRepresentable {
    
    // MARK: Public Properties
    var videoURL: String
    @Binding var state: THMMediaState
    var player: AVPlayer
    let mediaState: ((THMMediaState, Double) -> Void)?
    var onReadyToPlay: (() -> Void)?
    
    func makeUIView(context: Context) -> THMPlayerView {
        let playerView = THMPlayerView(
            frame: .init(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: UIScreen.main.bounds.height
            )
        )

        if playerView.player == nil {
            playerView.player = player
        }
        playerView.state = state
        playerView.mediaState = { state, duration in
            mediaState?(state, duration)
        }
        playerView.onReadyToPlay = {
            onReadyToPlay?()
        }
        return playerView
    }
    
    func updateUIView(_ playerView: THMPlayerView, context: Context) {
        playerView.state = state
        playerView.startVideo(url: URL(string: videoURL))
        playerView.mediaState = { state, duration in
            mediaState?(state, duration)
        }
        playerView.onReadyToPlay = {
            onReadyToPlay?()
        }
    }
    
}

