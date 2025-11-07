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


// MARK: - Networking
extension NotificationViewModel {
    
    func getNotifications(isRefreshed: Bool = false) {
        
        if !isRefreshed {
            guard pageNo <= totalPages else { return }
        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getNotifications(pageNo: isRefreshed ? 1 : pageNo)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            if isRefreshed {
                                notifications = data
                                self.isRefreshed.toggle()
                            } else {
                                notifications += data
                            }
                            
                        }
                        pageNo = result.pageNo ?? 1
                        totalPages = result.totalPages ?? 1
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
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
}

