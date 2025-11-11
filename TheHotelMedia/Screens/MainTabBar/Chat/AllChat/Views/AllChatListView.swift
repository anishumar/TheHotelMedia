//
//  ChatView.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct AllChatListView: View {
    
    @StateObject var viewModel: AllChatListViewModel
    @Binding var createPostOn: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    @AppStorage("hasReadNotifcation") var hasReadNotifcation: Bool = false
    
    @AppStorage("username") var username: String = ""
    @AppStorage("lastConnectedUser") var lastConnectedUser: String = ""
    @AppStorage("hasReadChat") var hasReadChat: Bool = true
    @AppStorage("isIndividual") var isIndividual: Bool = true
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var tabBarViewModel: MainTabBarViewModel
    
    var onStoryButtonPressed: (() -> Void)?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 10) {

                searchField
                    .padding(.top, 4)
                    .padding(.horizontal, 12)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 15) {
                        ForEach(viewModel.userList) { user in
                            profilePic(user: user)
                                .onTapGesture {
//                                    viewModel.socketViewModel.leaveRecentChatEmit()
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                        print(user.id ?? "")
//                                        viewModel.showPrivateChatScreen(username: user.username ?? "", userID: user.id ?? "", profilePic: user.profilePic?.small ?? "", name: user.name ?? "")
//                                    }
                                    viewModel.showPrivateChatScreen(username: user.username ?? "", userID: user.id ?? "", profilePic: user.profilePic?.small ?? "", name: user.name ?? "")
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.top, 4)
                
                Text("recent_chat".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                
                ForEach(viewModel.recentChat) { chat in
                    profileRowView(chat: chat)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 12)
                        .onAppear {
                            if let lastChat = viewModel.recentChat.last {
                                if lastChat.id == chat.id {
                                    viewModel.pageNo += 1
                                    viewModel.socketViewModel.chatScreenEmit(query: viewModel.searchFieldText, pageNo: viewModel.pageNo)
                                }
                            }
                        }
                }
                
                if viewModel.recentChat.isEmpty && viewModel.gotIntialData && !viewModel.showLoadingIndicator {
                    EmptyScreenView(image: "EmptyInbox", title: "your_inbox_is_empty".localized(localizationManager.language), subtitle: "no_one_send_a_message_to_you_yet".localized(localizationManager.language))
                }
                
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(height: 80)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 42)
            
        }
        .clipped()
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay(
            header
            , alignment: .top
        )
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay(alignment: .bottom, content: {
            ZStack(alignment: .bottom) {
                if createPostOn {
                    themeManager.currentTheme.black08_white08
                        .onTapGesture {
                            withAnimation(.smooth) {
                                createPostOn = false
                            }
                        }
                }
                VStack {
                    if isIndividual {
                        BlueButton(title: "review".localized(localizationManager.language), icon: "ReviewIcon") {
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            viewModel.showCreateReviewScreen()
                        }
                    } else {
                        BlueButton(title: "create_event".localized(localizationManager.language), icon: "CreateEvent") {
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            viewModel.showCreateEventScreen()
                        }
                    }
                    
                    HStack {
                        Spacer()
                        BlueButton(title: "create_post".localized(localizationManager.language), icon: "CreatePost") {
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            viewModel.showCreatePostScreen()
                        }
                        Spacer()
                        BlueButton(title: "create_story".localized(localizationManager.language), icon: "CreateStory") {
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            onStoryButtonPressed?()
                        }
                        Spacer()
                        
                    }
                    .offset(y: -16)
                }
                .font(.custom(Constants.comicFont, size: 16))
                .tint(themeManager.currentTheme.label)
                .scaleEffect(createPostOn ? 1 : 0)
                .offset(y: createPostOn ? 0 : 140)
                .animation(.easeInOut(duration: 0.4), value: createPostOn)
                .padding(.bottom, 100)
            }
            
        })
        .onAppear {
            viewModel.clearMessageNotifications()
            viewModel.onThisScreen = true
            viewModel.addSubscribers()
            if lastConnectedUser != username {
                viewModel.socketViewModel.configureSocket()
                print("Re-configuring socket because last connected user is not same as current user.🖐️🖐️🖐️")
            }
            hasReadChat = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                viewModel.socketViewModel.insideRecentChatEmit()
//            }
        }
        .onDisappear {
            viewModel.userList.removeAll()
            viewModel.pageNo = 1
            viewModel.gotIntialData = false
            viewModel.cancelPublishers()
            viewModel.onThisScreen = false
            viewModel.clearMessageNotifications()
            hasReadChat = true
//            viewModel.socketViewModel.leaveRecentChatEmit()
        }
        .onReceive(viewModel.$userConnectedOrDisconnected) { isConnected in
            viewModel.socketViewModel.usersListEmit()
//            if isConnected {
//                viewModel.socketViewModel.insideRecentChatEmit()
//            }
        }
        .onReceive(viewModel.socketViewModel.$isConnected, perform: { isConnected in
            if isConnected {
                viewModel.socketViewModel.chatScreenEmit(query: "", pageNo: 1)
            }
        })
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
//                viewModel.addSubscribers()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.clearMessageNotifications()
                    hasReadChat = true
                }
                if viewModel.onThisScreen {
                    viewModel.socketViewModel.configureSocket {
                        viewModel.socketViewModel.chatScreenEmit(query: "", pageNo: 1)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        viewModel.socketViewModel.insideRecentChatEmit()
                        
                    }
                }
                
//            case .inactive:
//                viewModel.cancelPublishers()
//            case .background:
//                viewModel.cancelPublishers()
            default:
                break
            }
        }
    }
}

// MARK: - Preview
struct AllChatListView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        AllChatListView(viewModel: AllChatListViewModel(router: router), createPostOn: .constant(false))
    }
}


// MARK: - Components
extension AllChatListView {
    private func profileRowView(chat: RecentChat) -> some View {
        HStack(spacing: 15) {
            WebImage(url: URL(string: chat.profilePic?.small ?? ""), content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 41, height: 41)
                    .clipShape(Circle())
                    .padding(.leading, 8)
//                    .onTapGesture {
//                        viewModel.showUserProfileScreen(id: chat.id ?? "")
//                    }
                    .onTapGesture {
                        haptics(.light)
//                        viewModel.socketViewModel.leaveRecentChatEmit()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                            print(chat.id ?? "")
//                            viewModel.showPrivateChatScreen(username: chat.username ?? "", userID: chat.id ?? "", profilePic: chat.profilePic?.small ?? "", name: chat.name ?? "")
//                        }
                        viewModel.showPrivateChatScreen(username: chat.username ?? "", userID: chat.id ?? "", profilePic: chat.profilePic?.small ?? "", name: chat.name ?? "")
                    }
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 41, height: 41)
                    .clipShape(Circle())
                    .padding(.leading, 8)
                    .onTapGesture {
                        haptics(.light)
                        viewModel.socketViewModel.leaveRecentChatEmit()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print(chat.id ?? "")
                            viewModel.showPrivateChatScreen(username: chat.username ?? "", userID: chat.id ?? "", profilePic: chat.profilePic?.small ?? "", name: chat.name ?? "")
                        }
                    }
            })
            
            VStack( alignment: .leading) {
                Text(chat.name ?? "")
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.label)
                
                Text(((chat.type ?? "") != "text" ? chat.type ?? "" : viewModel.censorWords(in: chat.message ?? "")))
                    .font(.custom(Constants.comicFont, size: 12.5))
                    .minimumScaleFactor(0.85)
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 50)
            .frame(height: 46, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 58, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.black09_white)
                .overlay(
                    Text(DateManager.getPostedAgoTime(date: chat.createdAt ?? "", language: localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 9.8))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .padding(.bottom, 6)
                        .padding(.trailing, 8)
                    
                    , alignment: .bottomTrailing
                )
                .overlay(alignment: .topTrailing) {
                    if let unseenCount = chat.unseenCount, unseenCount != 0 {
                        Text("\(unseenCount)")
                            .font(.custom(Constants.comicFont, size: 9))
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(themeManager.currentTheme.hmIndigo_hmIndigo05)
                            .clipShape(Circle())
                            .padding(.top, 4)
                            .padding(.trailing, 8)
                    }
                }
        )
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
        )
        .onTapGesture {
            haptics(.light)
//            viewModel.socketViewModel.leaveRecentChatEmit()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                print(chat.id ?? "")
//                viewModel.showPrivateChatScreen(username: chat.username ?? "", userID: chat.id ?? "", profilePic: chat.profilePic?.small ?? "", name: chat.name ?? "")
//            }
            viewModel.showPrivateChatScreen(username: chat.username ?? "", userID: chat.id ?? "", profilePic: chat.profilePic?.small ?? "", name: chat.name ?? "")
        }
    }
    
    
    private var header: some View {
        let showBackButton = tabBarViewModel.chatNavigationSource == .homeShortcut
        
        return HStack(spacing: 12) {
            if showBackButton {
                Button {
                    haptics(.light)
                    withAnimation(.smooth(duration: 0.2)) {
                        tabBarViewModel.createPostOn = false
                        tabBarViewModel.chatNavigationSource = .tab
                        tabBarViewModel.selectedTab = .home
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.label)
                        .frame(width: 32, height: 32)
                }
            } else {
                Color.clear
                    .frame(width: 32, height: 32)
            }
            
            Image(themeManager.currentTheme.Title)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 38)
            
            Spacer()
            
            Image(themeManager.currentTheme.BellIcon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(themeManager.currentTheme.label)
                .padding(.vertical, 8)
                .padding(.leading)
                .background(.black.opacity(0.001))
                .onTapGesture {
                    haptics(.light)
                    viewModel.showNotificationScreen()
                }
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .opacity(hasReadNotifcation ? 0 : 1.0)
                        .offset(x: -3, y: 5)
                }
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17))
                .fontWeight(.semibold)
            
            TextField(
                "",
                text: $viewModel.searchFieldText,
                prompt: Text("search".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            )
            .foregroundStyle(themeManager.currentTheme.label)
            .frame(maxWidth: .infinity)
            
        }
        .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
        .frame(height: 46)
        .padding(.horizontal, 16)
        .background(
            CapsuleBackground(borderColor: themeManager.currentTheme.mediumGray_hmIndigo, backgroundColor: themeManager.currentTheme.darkGray05_white)
        )
    }
    
    
    private func profilePic(user: ChatUser) -> some View {
        WebImage(url: URL(string: user.profilePic?.small ?? ""), content: { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(Circle())
                .overlay(alignment: .bottomTrailing) {
                    if let isOnline = user.isOnline, isOnline == 1 {
                        ZStack {
                            Circle()
                                .fill(.black)
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(.green)
                                .frame(width: 14, height: 14)
                        }
                        .padding(.bottom, 3)
                        .padding(.trailing, 3)
                    }
                }
        }, placeholder: {
            Image("NoProfilePic")
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(Circle())
                .overlay(alignment: .bottomTrailing) {
                    if let isOnline = user.isOnline, isOnline == 1 {
                        ZStack {
                            Circle()
                                .fill(.black)
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(.green)
                                .frame(width: 14, height: 14)
                        }
                        .padding(.bottom, 3)
                        .padding(.trailing, 3)
                    }
                }
        })
    }
}
