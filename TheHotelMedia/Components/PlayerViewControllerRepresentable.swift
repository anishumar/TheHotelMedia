//
//  PlayerViewControllerRepresentable.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import SwiftUI
import AVKit

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer?
    let backgroundColor: UIColor

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.view.backgroundColor = backgroundColor
        controller.showsPlaybackControls = true
        controller.exitsFullScreenWhenPlaybackEnds = false
        controller.allowsPictureInPicturePlayback = true // PIP enabled

        if let player = player {
            controller.player = player
            addReplayObserver(for: player)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.view.backgroundColor = backgroundColor

        // Update the player if it changes
        if uiViewController.player !== player {
            uiViewController.player = player
            if let player = player {
                addReplayObserver(for: player)
            }
        }
    }

    /// Adds an observer to replay the video when it ends
    private func addReplayObserver(for player: AVPlayer) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }
}

struct VideoPlayerView: View {
    let player: AVPlayer? = AVPlayer(url: URL(string: "https://www.example.com/video.mp4")!)

    var body: some View {
        PlayerViewControllerRepresentable(player: player, backgroundColor: .black)
            .frame(height: 300) // Adjust as needed
            .edgesIgnoringSafeArea(.all)
    }
}
