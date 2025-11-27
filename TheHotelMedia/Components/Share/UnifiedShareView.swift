//
//  UnifiedShareSheet.swift
//  TheHotelMedia
//
//  Created by MAC on 26/11/25.
//

import SwiftUI
import SDWebImageSwiftUI
import SwiftfulRouting

struct UnifiedShareSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.router) var envRouter
    @StateObject private var shareViewModel: ShareToChatViewModel
    
    var shareURL: String
    var postData: PostData?
    var router: AnyRouter?
    var onChatSelected: ((String, String, String, String) -> Void)?
    var onDismiss: (() -> Void)?
    
    @State private var searchText = ""
    
    init(shareURL: String, postData: PostData?, router: AnyRouter?, onChatSelected: ((String, String, String, String) -> Void)?, onDismiss: (() -> Void)?) {
        self.shareURL = shareURL
        self.postData = postData
        self.router = router
        self.onChatSelected = onChatSelected
        self.onDismiss = onDismiss
        
        // Router is required for UnifiedShareSheet - MediaPreviewView should use ActivityViewController
        guard let router = router else {
            fatalError("Router is required for UnifiedShareSheet. Use ActivityViewController for file sharing.")
        }
        _shareViewModel = StateObject(wrappedValue: ShareToChatViewModel(router: router))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top header with close button and post preview
            topHeader
            
            // Share options and user list together
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Share action buttons
                    shareOptionsRow
                        .padding(.vertical, 20)
                    
                    Divider()
                        .background(themeManager.currentTheme.white06_darkGray06)
                        .padding(.vertical, 12)
                    
                    // User grid section
                    userGridSection
                }
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .onAppear {
            shareViewModel.sharePostData = postData
            shareViewModel.loadChats()
        }
    }
    
    @ViewBuilder
    private var topHeader: some View {
        VStack(spacing: 0) {
            // Top bar with close button
            HStack {
                Spacer()
                Button {
                    onDismiss?()
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.black09_white)
                            .frame(width: 30, height: 30)
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.label)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Post preview
            if let postData = postData {
                postPreviewContent(postData: postData)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .overlay(
            Rectangle()
                .fill(themeManager.currentTheme.white06_darkGray06)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private func postPreviewContent(postData: PostData) -> some View {
        HStack(spacing: 12) {
            if let firstMedia = postData.mediaRef?.first,
               let thumbnailUrl = firstMedia.thumbnailURL ?? firstMedia.sourceURL {
                WebImage(url: URL(string: thumbnailUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(postData.content ?? "Post")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.label)
                    .lineLimit(2)
                
                Text("thehotelmedia.com")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.black09_white)
    }
    
    private var shareOptionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 25) {
                shareOptionButton(
                    icon: "doc.on.doc",
                    label: "Copy",
                    color: .blue
                ) {
                    UIPasteboard.general.string = shareURL
                    haptics(.light)
                }
                
                shareOptionButton(
                    icon: "folder",
                    label: "Save to Files",
                    color: .blue
                ) {
                    // Implement save to files
                    haptics(.light)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var userGridSection: some View {
        VStack(spacing: 16) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
                
                TextField("Search", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.label)
                    .padding(.vertical, 10)
                    .padding(.trailing, 12)
                    .onChange(of: searchText) { newValue in
                        shareViewModel.searchText = newValue
                        shareViewModel.filterChats()
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.currentTheme.black09_white)
            )
            .padding(.horizontal, 16)
            
            // User grid
            if !shareViewModel.filteredOnlineUsers.isEmpty || !shareViewModel.filteredRecentChats.isEmpty || !shareViewModel.filteredFollowersFollowing.isEmpty {
                LazyVStack(spacing: 16) {
                    // Online users grid
                    if !shareViewModel.filteredOnlineUsers.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
                            ForEach(shareViewModel.filteredOnlineUsers) { user in
                                userGridItem(user: user)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        if !shareViewModel.filteredRecentChats.isEmpty || !shareViewModel.filteredFollowersFollowing.isEmpty {
                            Divider()
                                .background(themeManager.currentTheme.white06_darkGray06)
                                .padding(.vertical, 8)
                        }
                    }
                    
                    // Recent chats grid
                    if !shareViewModel.filteredRecentChats.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
                            ForEach(shareViewModel.filteredRecentChats) { chat in
                                if let username = chat.username,
                                   let userID = chat.id,
                                   let name = chat.name {
                                    chatGridItem(chat: chat, username: username, userID: userID, name: name)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        if !shareViewModel.filteredFollowersFollowing.isEmpty {
                            Divider()
                                .background(themeManager.currentTheme.white06_darkGray06)
                                .padding(.vertical, 8)
                        }
                    }
                    
                    // Followers and Following grid
                    if !shareViewModel.filteredFollowersFollowing.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
                            ForEach(shareViewModel.filteredFollowersFollowing) { profile in
                                if let username = profile.username,
                                   let name = profile.name {
                                    followerFollowingGridItem(profile: profile, username: username, userID: profile.id, name: name)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            } else if shareViewModel.gotInitialData {
                EmptyScreenView(
                    image: "EmptyInbox",
                    title: "No chats found",
                    subtitle: "Start a conversation to share posts"
                )
                .padding(.top, 40)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func shareOptionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.currentTheme.label)
            }
        }
    }
    
    private func userGridItem(user: ChatUser) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                WebImage(url: URL(string: user.profilePic?.small ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                
                if user.isOnline == 1 {
                    Circle()
                        .fill(.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(themeManager.currentTheme.backgroundColor, lineWidth: 2)
                        )
                }
            }
            
            Text(user.name ?? "")
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.label)
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .onTapGesture {
            haptics(.light)
            if let username = user.username,
               let userID = user.userID,
               let name = user.name {
                onChatSelected?(username, userID, user.profilePic?.small ?? "", name)
            }
        }
    }
    
    private func chatGridItem(chat: RecentChat, username: String, userID: String, name: String) -> some View {
        VStack(spacing: 8) {
            WebImage(url: URL(string: chat.profilePic?.small ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.label)
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .onTapGesture {
            haptics(.light)
            onChatSelected?(username, userID, chat.profilePic?.small ?? "", name)
        }
    }
    
    private func followerFollowingGridItem(profile: SearchProfileData, username: String, userID: String, name: String) -> some View {
        VStack(spacing: 8) {
            WebImage(url: URL(string: profile.profilePic?.small ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(themeManager.currentTheme.label)
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .onTapGesture {
            haptics(.light)
            onChatSelected?(username, userID, profile.profilePic?.small ?? "", name)
        }
    }
}

