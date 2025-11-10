//
//  NotificationViewModel.swift
//  HotelMedia
//
//  Created by MAC on 06/09/24.
//

import SwiftUI
import SwiftfulRouting


class NotificationViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = NotificationDataManager()
    @Published var dummyNotification: [String] = []
    @Published var notifications: [NotificationModel] = []
    @Published var showLoadingIndicator: Bool = false
    @Published var isRefreshed: Bool = false
    @Published var pageNo: Int = 1
    @Published var totalPages: Int = 1
    
    init(router: AnyRouter) {
        self.router = router
        getNotifications()
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showProfileScreen(userID: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: userID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showPostScreen(postID: String) {
        router.showScreen(.push) { router in
            SinglePostView(viewModel: SinglePostViewModel(router: router, postID: postID), isPaused: .constant(false))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEventDetailScreen(eventID: String) {
        router.showScreen(.push) { router in
            EventDetailView(viewModel: EventDetailViewModel(router: router, postID: eventID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func clearNotifications() {
        var ids: [String] = []
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            for notification in notifications {
                let userInfo = notification.request.content.userInfo
                
                if let type = userInfo["screen"] as? String {
                    if type != "messaging" {
                        ids.append(notification.request.identifier)
                    }
                }
            }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
        }
    }
    
    
    func showJobDetailScreen(id: String) {
        router.showScreen(.push) { router in
            JobDetailView(viewModel: JobDetailViewModel(router: router, jobID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showBookingSummaryScreen(bookingID: String) {
        router.showScreen(.push) { router in
            TableSummaryView(viewModel: TableSummaryViewModel(router: router, bookingDetailID: bookingID, showButtons: true))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showRoomBookingSummaryScreen(bookingID: String) {
        router.showScreen(.push) { router in
            BookingSummaryView(viewModel: BookingSummaryViewModel(router: router, bookingDetailID: bookingID, lastScreen: "notification"))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}


enum CollaborationResponseAction: String {
    case accept
    case reject
}


// MARK: - Networking
extension NotificationViewModel {
    
    func getNotifications(isRefreshed: Bool = false) {
        
        print("🟣 [NOTIFICATIONS] ========================================")
        print("🟣 [NOTIFICATIONS] Fetching notifications...")
        print("🟣 [NOTIFICATIONS] IsRefreshed: \(isRefreshed)")
        print("🟣 [NOTIFICATIONS] PageNo: \(isRefreshed ? 1 : pageNo)")
        print("🟣 [NOTIFICATIONS] TotalPages: \(totalPages)")
        
        if !isRefreshed {
            guard pageNo <= totalPages else {
                print("🟣 [NOTIFICATIONS] ⚠️ PageNo exceeds totalPages, skipping fetch")
                return
            }
        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                print("🟣 [NOTIFICATIONS] Calling dataManager.getNotifications...")
                let result = try await dataManager.getNotifications(pageNo: isRefreshed ? 1 : pageNo)
                
                print("🟣 [NOTIFICATIONS] API Response received:")
                print("🟣 [NOTIFICATIONS]   Status: \(result.status)")
                print("🟣 [NOTIFICATIONS]   StatusCode: \(result.statusCode)")
                print("🟣 [NOTIFICATIONS]   Message: \(result.message)")
                print("🟣 [NOTIFICATIONS]   Notifications count: \(result.data?.count ?? 0)")
                print("🟣 [NOTIFICATIONS]   PageNo: \(result.pageNo ?? 0)")
                print("🟣 [NOTIFICATIONS]   TotalPages: \(result.totalPages ?? 0)")
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            print("🟣 [NOTIFICATIONS] Processing \(data.count) notifications...")
                            
                            // Log all notification types
                            for (index, notification) in data.enumerated() {
                                print("🟣 [NOTIFICATIONS]   Notification \(index + 1):")
                                print("🟣 [NOTIFICATIONS]     ID: \(notification.id ?? "N/A")")
                                print("🟣 [NOTIFICATIONS]     Type: \(notification.type ?? "N/A")")
                                print("🟣 [NOTIFICATIONS]     Type (raw): '\(notification.type ?? "N/A")'")
                                print("🟣 [NOTIFICATIONS]     Description: \(notification.description ?? "N/A")")
                                print("🟣 [NOTIFICATIONS]     UserID: \(notification.userID ?? "N/A")")
                                print("🟣 [NOTIFICATIONS]     IsCollaborationInvite: \(notification.isCollaborationInvite)")
                                print("🟣 [NOTIFICATIONS]     CollaborationStatus: \(notification.collaborationStatus)")
                                if let metadata = notification.metadata {
                                    print("🟣 [NOTIFICATIONS]     Metadata.postID: \(metadata.postID ?? "N/A")")
                                    print("🟣 [NOTIFICATIONS]     Metadata.type: \(metadata.type ?? "N/A")")
                                    print("🟣 [NOTIFICATIONS]     Metadata.type (raw): '\(metadata.type ?? "N/A")'")
                                    print("🟣 [NOTIFICATIONS]     Metadata.userID: \(metadata.userID ?? "N/A")")
                                }
                                
                                // Special logging for any notification that might be collaboration-related
                                let typeLower = (notification.type ?? "").lowercased()
                                let descLower = (notification.description ?? "").lowercased()
                                let metaTypeLower = (notification.metadata?.type ?? "").lowercased()
                                
                                if typeLower.contains("collab") || descLower.contains("collab") || metaTypeLower.contains("collab") ||
                                   typeLower.contains("invite") || descLower.contains("invite") || metaTypeLower.contains("invite") {
                                    print("🟡 [NOTIFICATIONS] ⚠️ POTENTIAL COLLABORATION NOTIFICATION DETECTED!")
                                    print("🟡 [NOTIFICATIONS] ⚠️   Type contains 'collab' or 'invite': \(typeLower.contains("collab") || typeLower.contains("invite"))")
                                    print("🟡 [NOTIFICATIONS] ⚠️   Description contains 'collab' or 'invite': \(descLower.contains("collab") || descLower.contains("invite"))")
                                    print("🟡 [NOTIFICATIONS] ⚠️   Metadata.type contains 'collab' or 'invite': \(metaTypeLower.contains("collab") || metaTypeLower.contains("invite"))")
                                }
                            }
                            
                            if isRefreshed {
                                notifications = data
                                self.isRefreshed.toggle()
                                print("🟣 [NOTIFICATIONS] ✅ Refreshed notifications. New count: \(notifications.count)")
                            } else {
                                notifications += data
                                print("🟣 [NOTIFICATIONS] ✅ Appended notifications. Total count: \(notifications.count)")
                            }
                            
                            // Check for collaboration invites specifically
                            let collaborationInvites = notifications.filter { $0.isCollaborationInvite }
                            print("🟣 [NOTIFICATIONS] Collaboration invites found: \(collaborationInvites.count)")
                            for invite in collaborationInvites {
                                print("🟣 [NOTIFICATIONS]   - Collaboration invite from: \(invite.usersRef?.name ?? "N/A")")
                                print("🟣 [NOTIFICATIONS]   - Status: \(invite.collaborationStatus)")
                                print("🟣 [NOTIFICATIONS]   - PostID: \(invite.metadata?.postID ?? "N/A")")
                            }
                        } else {
                            print("🟣 [NOTIFICATIONS] ⚠️ No notification data in response")
                        }
                        pageNo = result.pageNo ?? 1
                        totalPages = result.totalPages ?? 1
                        print("🟣 [NOTIFICATIONS] Updated PageNo: \(pageNo), TotalPages: \(totalPages)")
                    } else {
                        print("🔴 [NOTIFICATIONS] ❌ Failed to fetch notifications!")
                        print("🔴 [NOTIFICATIONS] Status: \(result.status), StatusCode: \(result.statusCode)")
                        print("🔴 [NOTIFICATIONS] Message: \(result.message)")
                    }
                }
            } catch {
                print("🔴 [NOTIFICATIONS] ❌ Exception occurred!")
                print("🔴 [NOTIFICATIONS] Error: \(error)")
                print("🔴 [NOTIFICATIONS] Error Description: \(error.localizedDescription)")
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
            
            print("🟣 [NOTIFICATIONS] ========================================")
        }
    }
    
    
    func followBack(connectionID: String) {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.followBackUser(id: connectionID)
                
                try? await Task.sleep(nanoseconds: 1500_000_000)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        getNotifications(isRefreshed: true)
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
    
    
    func acceptFollowRequest(connectionID: String) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.acceptFollowRequest(id: connectionID)
                
                try? await Task.sleep(nanoseconds: 1500_000_000)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        getNotifications(isRefreshed: true)
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                print(error)
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
    
    
    func rejectFollowRequest(connectionID: String) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.rejectFollowRequest(id: connectionID)
                
                try? await Task.sleep(nanoseconds: 1500_000_000)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        getNotifications(isRefreshed: true)
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                print(error)
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
    
    
    func respondToCollaboration(postID: String, action: CollaborationResponseAction) {
        print("🟠 [COLLAB RESPOND] ========================================")
        print("🟠 [COLLAB RESPOND] Responding to collaboration invite")
        print("🟠 [COLLAB RESPOND] PostID: \(postID)")
        print("🟠 [COLLAB RESPOND] Action: \(action.rawValue)")
        
        showLoadingIndicator = true
        
        Task {
            do {
                print("🟠 [COLLAB RESPOND] Calling dataManager.respondToCollaboration...")
                let result = try await dataManager.respondToCollaboration(postID: postID, action: action)
                
                print("🟠 [COLLAB RESPOND] API Response received:")
                print("🟠 [COLLAB RESPOND]   Status: \(result.status)")
                print("🟠 [COLLAB RESPOND]   StatusCode: \(result.statusCode)")
                print("🟠 [COLLAB RESPOND]   Message: \(result.message)")
                
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        print("🟠 [COLLAB RESPOND] ✅ Success! Refreshing notifications...")
                        getNotifications(isRefreshed: true)
                    } else {
                        print("🔴 [COLLAB RESPOND] ❌ Failed!")
                        print("🔴 [COLLAB RESPOND] Status: \(result.status), StatusCode: \(result.statusCode)")
                        print("🔴 [COLLAB RESPOND] Message: \(result.message)")
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                print("🔴 [COLLAB RESPOND] ❌ Exception occurred!")
                print("🔴 [COLLAB RESPOND] Error: \(error)")
                print("🔴 [COLLAB RESPOND] Error Description: \(error.localizedDescription)")
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
            
            print("🟠 [COLLAB RESPOND] ========================================")
        }
    }
}

