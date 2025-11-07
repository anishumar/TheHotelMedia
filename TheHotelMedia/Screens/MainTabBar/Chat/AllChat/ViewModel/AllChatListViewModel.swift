//
//  ChatViewModel.swift
//  HotelMedia
//
//  Created by MAC on 29/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


final class AllChatListViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    var socketViewModel = SocketIOViewModel.shared
    var refreshRecent: Bool = true
    var pageNo: Int = 1
    var gotIntialData: Bool = false
    var onThisScreen: Bool = false
    var showLoadingIndicator: Bool = false
    var firstDataSet: Bool = true
    @Published var searchFieldText: String = ""
    @Published var userList: [ChatUser] = []
    @Published var recentChat: [RecentChat] = []
    @Published var userConnectedOrDisconnected: Bool = false
    
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func addSubscribers() {
        // List of users
        socketViewModel.$userList
            .sink { [weak self] list in
                guard let self else { return }
                userList = list
                print(userList.count)
            }
            .store(in: &cancellables)
        
        
        // Socket connection status
        socketViewModel.$isConnected
            .sink { [weak self] connected in
                guard let self else { return }
                
                if connected && !gotIntialData {
                    showLoadingIndicator = true
                    socketViewModel.usersListEmit()
                    socketViewModel.chatScreenEmit(query: "", pageNo: 1)
                    
                } else if !connected {
                    socketViewModel.configureSocket()
                }
            }
            .store(in: &cancellables)
        
        
        // Refresh recent chat or next page.
        socketViewModel.$refreshRecent
            .sink { [weak self] refresh in
                guard let self else { return }
                refreshRecent = refresh
            }
            .store(in: &cancellables)
        
        
        // List of recent chats
        socketViewModel.$recentChat
            .sink { [weak self] (chat) in
                guard let self else { return }
                
                if !firstDataSet {
                    gotIntialData = true
                    showLoadingIndicator = false
                }
                
                firstDataSet = false
                
                if refreshRecent {
                    recentChat = chat
                } else {
                    recentChat += chat
                }
            }
            .store(in: &cancellables)
        
        
        // Page no of current recent chat data set
        socketViewModel.$recentChatPageNo
            .sink { [weak self] pageNo in
                guard let self else { return }
                self.pageNo = pageNo
            }
            .store(in: &cancellables)
        
        
        socketViewModel.$userConnectedOrDisconnected
            .sink { [weak self] bool in
                guard let self else { return }
                self.userConnectedOrDisconnected = bool
            }
            .store(in: &cancellables)
            
        
        // Search query
        $searchFieldText
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                pageNo = 1
                socketViewModel.chatScreenEmit(query: query, pageNo: pageNo)
            }
            .store(in: &cancellables)
        
        
    }
    
    
    func censorWords(in content: String) -> String {
        // Load abusive words from JSON file
        guard let url = Bundle.main.url(forResource: "abusive_words", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let abusiveWords = json["abusiveWords"] as? [String] else {
            return content
        }
        
        var censoredContent = content
        
        for word in abusiveWords {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: word) + "\\b"
            
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: censoredContent, options: [], range: NSRange(censoredContent.startIndex..., in: censoredContent))
                
                // Process matches in reverse order to prevent index shifting
                for match in matches.reversed() {
                    if let range = Range(match.range, in: censoredContent) {
                        let matchedWord = String(censoredContent[range])
                        
                        // Preserve first letter and replace the rest with '*'
                        let firstLetter = matchedWord.prefix(1)
                        let stars = String(repeating: "*", count: matchedWord.count - 1)
                        let censoredWord = firstLetter + stars
                        
                        // Replace word in the original string
                        censoredContent.replaceSubrange(range, with: censoredWord)
                    }
                }
            }
        }
        
        return censoredContent
    }
    
    
    func cancelPublishers() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
    }
    
    
    func showUserProfileScreen(id: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showPrivateChatScreen(username: String, userID: String, profilePic: String, name: String) {
        router.showScreen(.push) { router in
            ChatView(viewModel: ChatViewModel(router: router, username: username, userID: userID, profilePic: profilePic, name: name, lastScreen: "recentChat"), onLeaveChat: { returnedUsername in
                self.socketViewModel.leavePrivateChatEmit(user: username)
                self.socketViewModel.insideRecentChatEmit()
            })
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showNotificationScreen() {
        router.showScreen(.push) { router in
            NotificationView(viewModel: NotificationViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showCreatePostScreen() {
        router.showScreen(.push) { router in
            CreatePostScreen(viewModel: CreatePostViewModel(router: router, onPostCreated: { [weak self] in
                guard let self else { return }
                
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    func showCreateReviewScreen(id: String? = nil, placeID: String? = nil) {
        router.showScreen(.push) { router in
            CreateReviewView(viewModel: CreateReviewViewModel(router: router, businessProfileID: id, placeID: placeID, onReviewCreated: { [weak self] in
                guard let self else { return }
//                refreshHomeData = true
            }))
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
            
        }
    }
    
    
    func showCreateEventScreen() {
        router.showScreen(.push) { router in
            CreateEventScreen(viewModel: CreateEventViewModel(router: router, onEventCreated: { [weak self] in
                guard let self else { return }
//                refreshHomeData = true
            }))
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
            
        }
    }
    
    
    func clearMessageNotifications() {
        var ids: [String] = []
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            for notification in notifications {
                let userInfo = notification.request.content.userInfo
                
                if let type = userInfo["screen"] as? String {
                    if type == "messaging" {
                        ids.append(notification.request.identifier)
                    }
                }
            }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
        }
    }
}
