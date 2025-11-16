//
//  NotificationView.swift
//  HotelMedia
//
//  Created by MAC on 06/09/24.
//


import SDWebImageSwiftUI
import UserNotifications
import SwiftUI

struct NotificationView: View {
    
    @StateObject var viewModel: NotificationViewModel
    @AppStorage("hasReadNotifcation") var hasReadNotifcation: Bool = false
    @AppStorage("viaOtherNotification") var viaOtherNotification: Bool = false
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
           
//            List {
//                ForEach(viewModel.notifications) { notification in
//                    notificationView(notification: notification)
//                        .id(notification)
//                        .onAppear {
//                            if let lastNotification = viewModel.notifications.last {
//                                if lastNotification.id == notification.id {
//                                    viewModel.pageNo += 1
//                                    viewModel.getNotifications()
//                                }
//                            }
//                        }
//                        .listRowSeparator(.hidden)
//                        .listRowBackground(Color.black)
//                        .listRowSpacing(12)
//                        .listRowInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))
//                }
//            }
//            .listStyle(PlainListStyle())
//            .scrollIndicators(.hidden)
//            .frame(maxWidth: .infinity)
//            .padding(.top, 50)
//            .padding(.horizontal, 12)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.notifications) { notification in
                        notificationView(notification: notification)
//                            .id(notification)
                            .onAppear {
                                if let lastNotification = viewModel.notifications.last {
                                    if lastNotification.id == notification.id {
                                        viewModel.pageNo += 1
                                        viewModel.getNotifications()
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 50)
                
            }
//            .id(viewModel.isRefreshed)
        }
        .background(
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
        )
        .overlay {
            VStack {
                if viewModel.notifications.isEmpty && !viewModel.showLoadingIndicator {
                    EmptyScreenView(image: "BellIcon2", title: "no_notifications_yet".localized(localizationManager.language), subtitle: "you_have_no_notifications_right_now_come_back_later".localized(localizationManager.language))
                }
            }
            .frame(width: UIScreen.main.bounds.width)
        }
        .overlay(
            header
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            , alignment: .top
        )
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator )
        }
        .onAppear {
            viewModel.clearNotifications()
            hasReadNotifcation = true
            viaOtherNotification = false
            // Refresh notifications when screen appears
            viewModel.getNotifications(isRefreshed: true)
        }
        .onDisappear {
            viewModel.clearNotifications()
            hasReadNotifcation = true
        }
        
    }
}

// MARK: - Preview
struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        NotificationView(viewModel: NotificationViewModel(router: router))
    }
}


// MARK: - Functions
extension NotificationView {
    func handleNotificationTap(notification: NotificationModel) {
        if let type = notification.type {
            
            if let userID = notification.userID {
                if type == "like-comment" {
                    viewModel.showProfileScreen(userID: userID)
                    
                } else if type == "follow-request" {
                    viewModel.showProfileScreen(userID: userID)
                    
                } else if type == "accept-follow-request" {
                    viewModel.showProfileScreen(userID: userID)
                    
                } else if type == "following" {
                    viewModel.showProfileScreen(userID: userID)
                    
                } else if type == "like-a-story" {
                    viewModel.showProfileScreen(userID: userID)
                    
                } else if type == "job" {
                    if let jobID = notification.metadata?.jobID {
                        viewModel.showJobDetailScreen(id: jobID)
                    }
                } else if type.contains("book") {
                    if let bookingID = notification.metadata?.bookingID {
                        if let summaryType = notification.metadata?.type {
                            if summaryType == "booking" {
                                viewModel.showRoomBookingSummaryScreen(bookingID: bookingID)
                            } else {
                                viewModel.showBookingSummaryScreen(bookingID: bookingID)
                            }
                        }
                    }
                }
                
                if let postID = notification.metadata?.postID {
                    if type == "comment" {
                        if let postType = notification.metadata?.postType,
                           postType == "event" {
                            viewModel.showEventDetailScreen(eventID: postID)
                        } else {
                            viewModel.showPostScreen(postID: postID)
                        }
                        
                    } else if type == "like-post" {
                        viewModel.showPostScreen(postID: postID)
                        
                    } else if type == "reply" {
                        viewModel.showPostScreen(postID: postID)
                        
                    } else if type == "tagged" {
                        viewModel.showPostScreen(postID: postID)
                    } else if type == "event-join" {
                        viewModel.showEventDetailScreen(eventID: postID)
                    }
                }
            }
        }
    }
}



// MARK: - Components

extension NotificationView {
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    viewModel.dismissScreen()
                }
            
            Text("notification".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
        }
        .padding(.top, 12)
    }
    
    
    private func notificationView(notification: NotificationModel) -> some View {
        HStack(alignment: .center) {
            
            if notification.usersRef?.accountType == "individual" {
                individualProfilePic(urlString: notification.usersRef?.profilePic?.small ?? "" )
                    .onTapGesture {
                        viewModel.showProfileScreen(userID: notification.userID ?? "")
                    }
            } else {
                businessProfilePic(urlString: notification.usersRef?.businessProfileRef?.profilePic?.small ?? "")
                    .onTapGesture {
                        viewModel.showProfileScreen(userID: notification.userID ?? "")
                    }
            }
            
            HStack {
                Text("\(String(notification.description?.prefix(60) ?? ""))") // Convert Substring to String
                    .foregroundColor(themeManager.currentTheme.label)
                +
                Text(notification.description?.count ?? 0 > 60 ? " ...more" : "")
                +
                Text(" \(DateManager.getPostedAgoTime(date: notification.createdAt ?? "", language: localizationManager.language))")
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            }
            .font(.custom(Constants.comicFont, size: 13))
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)
            
            if notification.type == "follow-request" {
                HStack {
                    actionButton(title: "decline".localized(localizationManager.language), image: "xmark", isSystemImage: true, buttonColor: themeManager.currentTheme.mediumGray05_darkGray05)
                        .onTapGesture {
                            viewModel.rejectFollowRequest(connectionID: notification.metadata?.connectionID ?? "")
                        }
                    actionButton(title: "accept".localized(localizationManager.language), image: "checkmark", isSystemImage: true, buttonColor: themeManager.currentTheme.hmIndigo_hmIndigo05)
                        .onTapGesture {
                            viewModel.acceptFollowRequest(connectionID: notification.metadata?.connectionID ?? "")
                        }
                }
            } else if notification.type == "accept-follow-request" {
                actionButton(title: "following".localized(localizationManager.language), image: "PersonMinus", buttonColor: themeManager.currentTheme.mediumGray05_darkGray05)
                
            } else if notification.type == "following" {
                if let isRequested = notification.isRequested,
                   let isConnected = notification.isConnected {
                    
                    if !isRequested && !isConnected {
                        actionButton(title: "follow".localized(localizationManager.language), image: "AddPerson", buttonColor: themeManager.currentTheme.hmIndigo_hmIndigo05)
                            .onTapGesture {
                                viewModel.followBack(connectionID: notification.metadata?.connectionID ?? "")
                            }
                        
                    } else if isRequested && !isConnected {
                        actionButton(title: "requested".localized(localizationManager.language), image: "PersonMinus", buttonColor: themeManager.currentTheme.mediumGray05_darkGray05)
                        
                    } else {
                        actionButton(title: "following".localized(localizationManager.language), image: "PersonMinus", buttonColor: themeManager.currentTheme.mediumGray05_darkGray05)
                    }
                }
                
            } else if notification.isCollaborationInvite {
                let status = notification.collaborationStatus
                
                if status == .pending {
                    HStack {
                        actionButton(title: "decline".localized(localizationManager.language), image: "xmark", isSystemImage: true, buttonColor: themeManager.currentTheme.mediumGray05_darkGray05)
                            .onTapGesture {
                                if let postID = notification.metadata?.postID {
                                    viewModel.respondToCollaboration(postID: postID, action: .reject)
                                }
                            }
                        actionButton(title: "accept".localized(localizationManager.language), image: "checkmark", isSystemImage: true, buttonColor: themeManager.currentTheme.hmIndigo_hmIndigo05)
                            .onTapGesture {
                                if let postID = notification.metadata?.postID {
                                    viewModel.respondToCollaboration(postID: postID, action: .accept)
                                }
                            }
                    }
                } else if status == .accepted {
                    actionButton(title: "accepted".localized(localizationManager.language), image: "PersonMinus", buttonColor: themeManager.currentTheme.mediumGray05_darkGray05)
                } else if status == .rejected {
                    actionButton(title: "declined".localized(localizationManager.language), image: "PersonMinus", buttonColor: themeManager.currentTheme.mediumGray05_darkGray05)
                }
            }
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.currentTheme.darkGray05_white)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            }
                .onTapGesture {
                    handleNotificationTap(notification: notification)
                }
        )
    }
    
    
    private func individualProfilePic(urlString: String) -> some View {
        Circle()
            .frame(width: 48)
            .overlay(
                WebImage(url: URL(string: urlString), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                })
            )
    }
    
    
    private func actionButton(title: String, image: String, isSystemImage: Bool = false, buttonColor: Color = .hmIndigo.opacity(0.5)) -> some View {
        HStack(spacing: 4) {
            if isSystemImage {
                Image(systemName: image)
                    .font(.caption)
                    .foregroundColor(.white)
                    .scaledToFit()
            } else {
                Image(image)
                    .resizable()
                    .foregroundColor(.white)
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }
            
            
            Text(title)
                .font(.custom(Constants.comicFont, size: 9.5))
                .foregroundColor(.white)
        }
        .frame(minWidth: 58)
        .frame(height: 26)
        .padding(.horizontal, 6)
        .background(
            ZStack {
                Capsule()
                    .fill(
                        buttonColor
//                        .shadow(.inner(color: .black, radius: 6))
//                        .shadow(.inner(color: .black, radius: 4))
//                        .shadow(.inner(color: .black, radius: 2))
                    )
            }
            
        )
    }
    
    
//    private func grayButton(title: String, image: String, isSystemImage: Bool = false) -> some View {
//        HStack(spacing: 4) {
//            if isSystemImage {
//                Image(image)
//                    .resizable()
//                    .foregroundColor(.white)
//                    .scaledToFit()
//                    .frame(width: 14, height: 14)
//            } else {
//                Image(image)
//                    .resizable()
//                    .foregroundColor(.white)
//                    .scaledToFit()
//                    .frame(width: 14, height: 14)
//            }
//            
//            Text(title)
//                .font(.custom(Constants.comicFont, size: 9.5))
//                .foregroundColor(.white)
//        }
//        .frame(width: 62, height: 26)
//        .background(
//            ZStack {
//                Capsule()
//                    .fill(
//                        .hmDarkerGray.opacity(0.5)
//                        .shadow(.inner(color: .black, radius: 6))
//                        .shadow(.inner(color: .black, radius: 4))
//                        .shadow(.inner(color: .black, radius: 2))
//                    )
//                Capsule()
//                    .stroke(lineWidth: 1)
//                    .fill(.hmDarkestGray)
//                    .frame(width: 63, height: 27)
//            }
//            
//        )
//    }
    
    
    private func businessProfilePic(urlString: String) -> some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: 48, height: 48)
            .overlay(
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 45)
            )
            .overlay(
                WebImage(url: URL(string: urlString), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 42, height: 42)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 42, height: 42)
                })
            )
    }
}
