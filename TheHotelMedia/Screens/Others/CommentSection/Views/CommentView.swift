//
//  CommentView.swift
//  HotelMedia
//
//  Created by MAC on 01/08/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct CommentView: View {
    
    @StateObject var viewModel: CommentViewModel
    var onPressedHeart: (() -> Void)? = nil
    var onPressedReply: (() -> Void)? = nil
    var onPressedEllipsis: (() -> Void)? = nil
    var onPressedReplyEllipsis: ((CGFloat, String) -> Void)? = nil
    var onPressedProfile: ((String) -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        LazyVStack(alignment: .leading) {
            topView
            commentTextView
            HStack {
                Group {
                    Image(viewModel.likedMyBe ? "heartfill" : themeManager.currentTheme.heart)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17)
                    
                    Text(viewModel.likes)
                }
                .onTapGesture {
                    viewModel.likedMyBe.toggle()
                    if viewModel.likedMyBe {
                        viewModel.likesCount += 1
                    } else {
                        viewModel.likesCount -= 1
                    }
                    onPressedHeart?()
                }
                
                Group{
                    Image("arrow.right")
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 12.5))
                        .foregroundColor(themeManager.currentTheme.white07_darkGray)
                        .scaledToFit()
                        .frame(width: 12.5, height: 12.5)
                    Text("Reply")
                    if let replies = viewModel.comment.repliesRef {
                        if !replies.isEmpty {
                            Text(viewModel.showReplies ? "Hide Replies" : "View Replies")
                                .foregroundColor(.hmIndigo.opacity(0.5))
                                .onTapGesture {
                                    viewModel.showReplies.toggle()
                                }
                        }
                    }
                    
                }
                .onTapGesture {
                    onPressedReply?()
                }
                
            }
            
            if viewModel.showReplies {
                LazyVStack {
                    if let replies = viewModel.comment.repliesRef {
                        ForEach(replies) { replyComment in
                            let index = replies.firstIndex(where: { $0.id == replyComment.id})
                            ReplyCommentView(viewModel: ReplyCommentViewModel(comment: replyComment)) {
                                if let index {
                                    onPressedReplyEllipsis?(viewModel.replyCommentYOffsets[index], replyComment.id ?? "")
                                }
                            } onPressedProfile: { userID in
                                onPressedProfile?(userID)
                            }
                            .overlay(
                                GeometryReader { geo in
                                    Color.black.opacity(0.0001)
                                        .preference(key: VisibleRectanglePreferenceKey.self, value: geo.frame(in: .named("SheetSpace")))
                                        .allowsHitTesting(false)
                                }
                            )
                            .onPreferenceChange(VisibleRectanglePreferenceKey.self) { frame in
                                if let index {
                                    viewModel.replyCommentYOffsets[index] = frame.minY
                                }
                            }
                        }
                    }
                    
                }
                .padding(.leading, 40)
            }
        }
        .font(.custom(Constants.comicFont, size: 12.5))
        .foregroundStyle(themeManager.currentTheme.white07_darkGray)
    }
}

#Preview {
    CommentView(viewModel: CommentViewModel(comment: Comment(id: nil, isParent: nil, userID: nil, businessProfileID: nil, postID: nil, message: nil, createdAt: nil, repliesRef: nil, commentedBy: nil, likes: nil, likedByMe: false)))
}


extension CommentView {
    
    private var commentTextView: some View {
        Text(viewModel.commentText)
            .font(.custom(Constants.comicFont, size: 12.5))
            .foregroundStyle(themeManager.currentTheme.white07_darkGray)
            .padding(.trailing, 16)
    }
    
    
    private var topView: some View {
        HStack(alignment: .top,  spacing: 11) {
            WebImage(url: URL(string: viewModel.profilePic), content: { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .onTapGesture {
                        onPressedProfile?(viewModel.comment.userID ?? "")
                    }
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            })
            
            VStack(alignment: .leading) {
                Text(viewModel.name)
                    .font(.custom(Constants.comicFont, size: 15))
                    .foregroundStyle(themeManager.currentTheme.white07_darkGray)
                Text("\(viewModel.postedAgo)")
                    .font(.custom(Constants.comicFont, size: 10))
                    .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ellipsisButton
        }
    }
    
    
    private var ellipsisButton: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: 27)
            HStack(spacing: 2.5) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.white)
                        .frame(width: 3)
                }
            }
        }
        .onTapGesture {
            onPressedEllipsis?()
        }
    }
}
