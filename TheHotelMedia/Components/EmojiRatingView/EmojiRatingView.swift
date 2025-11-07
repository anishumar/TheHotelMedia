//
//  EmojiRatingView.swift
//  TheHotelMedia
//
//  Created by MAC on 25/09/24.
//

import SwiftUI
import Lottie

struct EmojiRatingView: View {
    
    @State var selectedStar: Int = -1
    @State var playBackMode: LottiePlaybackMode = .paused
    var title: String = "How was the cleanliness of the hotel?"
    var onRated: ((Int) -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            HStack {
                starView
                    .overlay {
                        HStack {
                            Rectangle()
                                .fill(.yellow)
                                .scaleEffect(x: 0.20 * CGFloat((selectedStar + 1)), anchor: .leading)
                        }
                        .allowsHitTesting(false)
                    }
                    .mask(starView)
                
                Spacer()
                
                if selectedStar == 0 {
                    Text("🥲")
                        .font(.system(size: 28))
                } else if selectedStar == 1 {
                    Text("☹️")
                        .font(.system(size: 28))
                } else if selectedStar == 2 {
                    Text("😑")
                        .font(.system(size: 28))
                } else if selectedStar == 3 {
                    Text("😃")
                        .font(.system(size: 28))
                } else if selectedStar == 4 {
                    Text("😍")
                        .font(.system(size: 28))
                } else {
                    Text("Rating")
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray05_mediumGray3)
        )
        }
    }
}

#Preview {
    VStack {
        EmojiRatingView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        Color.black
    )
    
}


// MARK: - Components
extension EmojiRatingView {
    private var starView: some View {
        HStack(spacing: 20) {
            ForEach(0..<5) { index in
                Image(themeManager.currentTheme.RatingStar)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            selectedStar = index
                            onRated?(index + 1)
                            haptics(.light)
                            playBackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                        }
                    }
                    .overlay {
                        VStack {
                            if selectedStar >= index {
                                LottieView(animation: .named("star-animation"))
                                    .reloadAnimationTrigger(selectedStar, showPlaceholder: false)
                                    .playbackMode(playBackMode)
                                    .animationDidFinish({ completed in
                                        playBackMode = .paused
                                    })
                                    .offset(x: -4, y: -3.2)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            selectedStar = index
                                            onRated?(index + 1)
                                            haptics(.light)
                                            playBackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                                        }
                                    }
                            }
                        }
                    }
            }
        }
    }
}
