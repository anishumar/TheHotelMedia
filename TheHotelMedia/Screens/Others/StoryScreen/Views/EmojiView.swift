//
//  EmojiView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI

struct THMEmojiView: View {
    
    var story: THMStory
    var emojiArray: [[String]]?
    
    @Binding var startAnimating: Bool
    @Binding var selectedEmoji: String
    
    let userClosure: THMUserCompletionHandler?
    
    private var emojiSize: CGFloat {
        if emojiArray?.count == 1 {
            return 55
        }
        return CGFloat(100/(emojiArray?.count ?? .zero))
    }
    
    private var spacing: CGFloat {
        if emojiArray?.count == 1 {
            return 40
        }
        return CGFloat(80/(emojiArray?.count ?? .zero))
    }
    
    var body: some View {
        if let emojiArray {
            VStack(spacing: spacing) {
                ForEach(emojiArray.lazy.indices) { index in
                    HStack(spacing: spacing) {
                        ForEach(emojiArray[index].lazy.indices) { icon in
                            Button(emojiArray[index][icon]) {
                                let emoji = emojiArray[index][icon]
                                startAnimate()
                                select(emoji: emoji)
                                dismissKeyboard()
                                userClosure?(story, nil, emoji, false)
                            }
                            .font(.system(size: emojiSize))
                        }
                    }
                }
            }
        }
        
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.endEditing(true)
    }
    
    private func select(emoji: String) {
        selectedEmoji = emoji
    }
    
    private func startAnimate() {
       startAnimating = true
    }
}

struct THMEmojiView_Previews: PreviewProvider {
    static var previews: some View {
        THMEmojiView(story: .init(mediaID: "", mediaURL: "", date: "", config: THMStoryConfiguration(mediaType: .image)),
                  emojiArray: [["😂", "😮", "😍"]],
                  startAnimating: .constant(false),
                  selectedEmoji: .constant("🤪"),
                  userClosure: nil)
    }
}
