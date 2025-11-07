//
//  ReplyCommentView.swift
//  TheHotelMedia
//
//  Created by MAC on 11/10/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReplyCommentView: View {
    @StateObject var viewModel: ReplyCommentViewModel
//    var onPressedHeart: (() -> Void)? = nil
//    var onPressedReply: (() -> Void)? = nil
    var onPressedEllipsis: (() -> Void)? = nil
    var onPressedProfile: ((String) -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading) {
            topView
            commentTextView
//            HStack {
//                Group {
//                    Image(viewModel.likedMyBe ? "heartfill" : "heart")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 17)
//                    
//                    Text(viewModel.likes)
//                }
//                .onTapGesture {
//                    viewModel.likedMyBe.toggle()
//                    if viewModel.likedMyBe {
//                        viewModel.likesCount += 1
//                    } else {
//                        viewModel.likesCount -= 1
//                    }
//                    onPressedHeart?()
//                }
//                
//                Group{
//                    Image("arrow.right")
//                    Text("Reply")
//                }
//                .onTapGesture {
//                    onPressedReply?()
//                }
//                
//            }
                
        }
        .font(.custom(Constants.comicFont, size: 12.5))
        .foregroundStyle(themeManager.currentTheme.white07_darkGray)
    }
}

#Preview {
    ReplyCommentView(viewModel: ReplyCommentViewModel(comment: ReplyComment(likes: nil, isParent: nil, businessProfileID: nil, postID: nil, parentID: nil, createdAt: nil, userID: nil, likedByMe: nil, commentedBy: nil, id: nil, message: nil)))
}

// MARK: - Components
extension ReplyCommentView {
    
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
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                    .onTapGesture {
                        onPressedProfile?(viewModel.comment.userID ?? "")
                    }
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
            })
            
            VStack(alignment: .leading) {
                Text(viewModel.name)
                    .font(.custom(Constants.comicFont, size: 13))
                    .foregroundStyle(themeManager.currentTheme.white07_darkGray)
                Text("\(viewModel.postedAgo)")
                    .font(.custom(Constants.comicFont, size: 9))
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
                .frame(width: 23)
            HStack(spacing: 2.5) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.white)
                        .frame(width: 2.5)
                }
            }
        }
        .onTapGesture {
            onPressedEllipsis?()
        }
    }
}
