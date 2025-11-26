//
//  ShareToChatView.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct ShareToChatView: View {
    
    @ObservedObject var viewModel: ShareToChatViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var onChatSelected: ((String, String, String, String) -> Void)? // username, userID, profilePic, name
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Share to Chat")
                    .font(.custom(Constants.comicBold, size: 18))
                    .foregroundColor(themeManager.currentTheme.label)
                Spacer()
                Button {
                    viewModel.dismissView?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.label)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Rectangle()
                .fill(themeManager.currentTheme.white06_darkGray06)
                .frame(height: 1)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .padding(.leading, 12)
                
                TextField("Search", text: $viewModel.searchText)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.label)
                    .padding(.vertical, 10)
                    .padding(.trailing, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.currentTheme.black09_white)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Chat list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Online users
                    if !viewModel.filteredOnlineUsers.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(viewModel.filteredOnlineUsers) { user in
                                    onlineUserView(user: user)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 16)
                        
                        Rectangle()
                            .fill(themeManager.currentTheme.white06_darkGray06)
                            .frame(height: 1)
                            .padding(.vertical, 8)
                    }
                    
                    // Recent chats
                    if !viewModel.filteredRecentChats.isEmpty {
                        ForEach(viewModel.filteredRecentChats) { chat in
                            chatRowView(chat: chat)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    haptics(.light)
                                    if let username = chat.username,
                                       let userID = chat.id,
                                       let name = chat.name {
                                        onChatSelected?(username, userID, chat.profilePic?.small ?? "", name)
                                    }
                                }
                        }
                    } else if viewModel.gotInitialData && !viewModel.showLoadingIndicator {
                        EmptyScreenView(
                            image: "EmptyInbox",
                            title: "No chats found",
                            subtitle: "Start a conversation to share posts"
                        )
                        .padding(.top, 60)
                    }
                    
                    Rectangle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .frame(height: 20)
                }
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .onAppear {
            viewModel.loadChats()
        }
        .onChange(of: viewModel.searchText) { _ in
            viewModel.filterChats()
        }
    }
    
    private func onlineUserView(user: ChatUser) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                WebImage(url: URL(string: user.profilePic?.small ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                })
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                Circle()
                    .fill(.green)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(themeManager.currentTheme.backgroundColor, lineWidth: 2)
                    )
            }
            
            Text(user.name ?? "")
                .font(.custom(Constants.comicFont, size: 11))
                .foregroundColor(themeManager.currentTheme.label)
                .lineLimit(1)
                .frame(maxWidth: 70)
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
    
    private func chatRowView(chat: RecentChat) -> some View {
        HStack(spacing: 15) {
            WebImage(url: URL(string: chat.profilePic?.small ?? ""), content: { image in
                image
                    .resizable()
                    .scaledToFill()
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
            })
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.name ?? "")
                    .font(.custom(Constants.comicFont, size: 15))
                    .foregroundColor(themeManager.currentTheme.label)
                
                Text(chat.message ?? "")
                    .font(.custom(Constants.comicFont, size: 12))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let unseenCount = chat.unseenCount, unseenCount > 0 {
                ZStack {
                    Circle()
                        .fill(.hmIndigo)
                        .frame(width: 20, height: 20)
                    Text("\(unseenCount)")
                        .font(.custom(Constants.comicFont, size: 10))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    @Environment(\.router) var router
    ShareToChatView(viewModel: ShareToChatViewModel(router: router))
        .environmentObject(ThemeManager.shared)
        .environmentObject(LocalizationManager.shared)
}

