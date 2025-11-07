//
//  THMMessageView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI

struct THMMessageView: View {
    
    // MARK: Public Properties
    var story: THMStory
    
    @Binding var showEmoji: Bool
    let userClosure: THMUserCompletionHandler?
    
    // MARK: Private Properties
    @State private var text: String = ""
    @State private var likeButtonTapped: Bool = false
    @State private var clearText: Bool = false
   
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                switch story.config.storyType {
                case .plain(let config):
                    HStack {
                        Spacer()
                        buttonViewBuilder(config)
                    }
                case .message(let config, _, let placeholder):
                    messageViewBuilder(config, placeholder)
                }
            }
        }
    }
}

private extension THMMessageView {
    var onCommitAction: () -> Void {
        return {
            guard !text.isEmpty else {
                return
            }
            clearText.toggle()
            userClosure?(story, text, nil, false)
        }
    }
    
    
    var likeButton: some View  {
        Button {
            likeButtonTapped.toggle()
            userClosure?(story, text, nil, likeButtonTapped)
        } label: {
            Image(systemName: likeButtonTapped ? Constants.MessageView.likeImageTapped : Constants.MessageView.likeImage)
                .font(.title2)
                .foregroundColor(likeButtonTapped ? .red : .white)
            
        }
    }
    
    var shareButton: some View  {
        Button {
        } label: {
            Image(systemName: Constants.MessageView.shareImage)
                .font(.title2)
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    func buttonViewBuilder(_ config: THMStoryInteractionConfig?) -> some View {
        if let config {
            HStack(spacing: 16) {
                if config.showLikeButton {
                    likeButton
                }
            }
            .frame(height: Constants.MessageView.height)
        } else {
            EmptyView()
        }
    }
    
    
    func messageViewBuilder(_ config: THMStoryInteractionConfig?, _ placeholder: String) -> some View {
        HStack(spacing: 16) {
            TextField("",
                      text: $text,
                      onCommit: onCommitAction)
            .placeholder2(when: text.isEmpty, view: {
                Text(placeholder).foregroundColor(.white)
            })
            .onChange(of: text, perform: { newValue in
                showEmoji = newValue.isEmpty
            })
            .onChange(of: clearText, perform: { newValue in
                text = ""
                showEmoji = newValue
            })
            .onChange(of: story, perform: { newValue in
                likeButtonTapped = newValue.isLiked
            })
            .foregroundColor(.white)
            .frame(height: Constants.MessageView.height)
            .padding(Constants.MessageView.padding)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.MessageView.cornerRadius)
                    .stroke(.white)
            )
            
            buttonViewBuilder(config)
        }
    }
}

struct THMMessageView_Previews: PreviewProvider {
    static var previews: some View {
        THMMessageView(story: THMStory(mediaID: "", mediaURL: "", date: "", config: THMStoryConfiguration(mediaType: .image)), showEmoji: .constant(true), userClosure: nil)
    }
}


extension TextField {
    func placeholder2<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder view: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                view().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}


