//
//  EventDetalView.swift
//  TheHotelMedia
//
//  Created by MAC on 24/10/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct EventDetailView: View {
    
    @StateObject var viewModel: EventDetailViewModel
    @State var isSheet: Bool = false
    @State var showing: Bool = false
    @State var offset: CGFloat = 0.0
    var onPressedJoin: ((String) -> Void)? = nil
    var onPressedShare: ((String) -> Void)? = nil
    
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    var body: some View {
        VStack {
            if isSheet {
                VStack {
                    if showing {
                        mainComponent
                            .transition(.move(edge: .trailing))
                    }
                }
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            withAnimation(.interactiveSpring) {
                                if value.translation.width >= 0 {
                                    offset = value.translation.width
                                }
                            }
                        })
                        .onEnded { value in
                            if value.translation.width > Constants.screenWidth * 0.25 {
                                dismissScreen()
                            } else {
                                withAnimation(.interactiveSpring) {
                                    offset = 0
                                }
                            }
                        }
                )
                .onAppear {
                    withAnimation(.smooth(duration: 0.2)) {
                        showing = true
                    }
                }
            } else {
                mainComponent
            }
        }
    }
}


// MARK: - Preview
struct EventDetalView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EventDetailView(viewModel: EventDetailViewModel(router: router, postID: "672b584d28685d994782c304"))
    }
}


// MARK: - Functions
extension EventDetailView {
    private func handleIncomingURL(_ url: URL) {
        // Parse the URL
        if url.host == "thehotelmedia.com" {
            let path = url.path // e.g., "/share/users"
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            
            if path.contains("/share/users") {
                if let id = queryItems?.first(where: { $0.name == "id" })?.value,
                   let userID = queryItems?.first(where: { $0.name == "userID" })?.value {
                    if let decryptedID = EncryptionHelper.decrypt(id),
                       let decryptedUserID = EncryptionHelper.decrypt(userID) {
                            
                        guard decryptedID != ownUserID else { return }
                        
                        viewModel.showSharedProfile(sharedID: decryptedID, sharedByID: decryptedUserID)
                    }
                }
            } else if path.contains("/share/posts") {
                if let postID = queryItems?.first(where: { $0.name == "postID" })?.value,
                   let userID = queryItems?.first(where: { $0.name == "userID" })?.value {
//                    if let decryptedID = EncryptionHelper.decrypt(id),
//                       let decryptedUserID = EncryptionHelper.decrypt(userID) {
//
//                        guard decryptedID != ownUserID else { return }
//
//                    }
                    viewModel.showSharePostView(postID: postID, sharedByID: userID)
                }
            } else if path.contains("/share/events") {
                if let postID = queryItems?.first(where: { $0.name == "postID" })?.value,
                   let userID = queryItems?.first(where: { $0.name == "userID" })?.value {
                    if let decryptedPostID = EncryptionHelper.decrypt(postID),
                       let decryptedUserID = EncryptionHelper.decrypt(userID) {

                        viewModel.showShareEventView(postID: decryptedPostID, sharedByID: decryptedUserID)

                    }
                    
                }
            } else if path.contains("/review") {
                if let businessProfileID = queryItems?.first(where: { $0.name == "id" })?.value,
                   let placeID = queryItems?.first(where: { $0.name == "placeID" })?.value {
                    
                    viewModel.showCreateReviewScreen(id: businessProfileID, placeID: placeID)
                }
            }
        } else {
            UIApplication.shared.open(url)
        }
    }
    
    
    private func dismissScreen() {
        withAnimation(.smooth(duration: 0.2)) {
            showing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}


// MARK: - Main Component
extension EventDetailView {
    private var mainComponent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
//                profileHeaderView
                    
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 190)
                    .onTapGesture {
                        viewModel.selectedMedia = .image(urlString: viewModel.eventPost?.mediaRef?[0].sourceURL ?? "")
                        viewModel.showPreview.toggle()
                    }
                    .overlay {
                        WebImage(url: URL(string: viewModel.eventPost?.mediaRef?[0].sourceURL ?? ""), content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 190)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .allowsHitTesting(false)
                        }, placeholder: {
                            Image("PostImagePlaceholder")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 190)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        })
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .fullScreenCover(isPresented: $viewModel.showPreview, onDismiss: {
                        modifyOrientation(.portrait)
                    }, content: {
                        MediaPreviewView(media: viewModel.selectedMedia)
                            .background(BackgroundClearView())
                    })
                
                VStack(alignment: .leading, spacing: 20) {
                    eventTitle
                    peopleJoinedSection
                    descriptionSection
                    if viewModel.offlineEvent {
                        locationView
                    }
                    timeView
                    if viewModel.offlineEvent {
                        mapSection
                    }
                    
                    if let streamingLink = viewModel.eventPost?.streamingLink, !streamingLink.isEmpty {
                        streamingLinkSection(link: streamingLink)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.top, 60)
            .padding(.bottom, 65)
        }
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            HStack(spacing: 12) {
                shareButton
                    .onTapGesture {
                        viewModel.showShareView(id: viewModel.postID)
                    }
                if viewModel.isValidEvent {
                    joinButton
                }
                saveButton
            }
            .padding(.bottom, 20)
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay(alignment: .topLeading) {
            HStack(spacing: 0) {
                Button {
                    if isSheet {
                        dismissScreen()
                    } else {
                        viewModel.dismissScreen()
                    }
                    
                } label: {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.black.opacity(0.001))
                            .frame(width: 30, height: 50)
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.label)
                    }
                    
                }
                .padding(.leading)
                .zIndex(2.0)
                
                profileHeaderView
                    .sheet(isPresented: $viewModel.isSharePresented) {
                        UnifiedShareSheet(
                            shareURL: viewModel.shareURL.absoluteString,
                            postData: viewModel.sharePostData,
                            router: viewModel.router,
                            onChatSelected: { username, userID, profilePic, name in
                                viewModel.isSharePresented = false
                            },
                            onDismiss: {
                                viewModel.isSharePresented = false
                                viewModel.sharePostData = nil
                            }
                        )
                        .environmentObject(ThemeManager.shared)
                        .environmentObject(LocalizationManager.shared)
                        .presentationDetents([.medium, .large])
                    }
                Spacer()
            }
            .background(themeManager.currentTheme.backgroundColor)
        }
        .onReceive(locationManager.$currentLocation) { coordinate in
            guard let coordinate else { return }
            viewModel.currentLongitude = coordinate.longitude.magnitude
            viewModel.currentLatitude = coordinate.latitude.magnitude
        }
        .onAppear {
            locationManager.requestLocation()
            viewModel.getEvent(id: viewModel.postID)
        }
        .onOpenURL { url in
            switch url.scheme {
            case "readmore":
//                guard let host = url.host, host == viewModel.data.id ?? "" else { return }
                viewModel.isExpanded.toggle()
                viewModel.getAttributedDescription(id: viewModel.eventPost?.id ?? "")
                
            default:
                break
            }
        }
    }
}



// MARK: - Components
extension EventDetailView {
    private var profileHeaderView: some View {
        HStack(spacing: 15) {
            businessProfilePic(urlString: viewModel.eventPost?.postedBy?.businessProfileRef?.profilePic?.small ?? "")
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.eventPost?.postedBy?.businessProfileRef?.name ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
                
                Text(viewModel.businessAddress)
                    .font(.custom(Constants.comicFont, size: 11))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
//        .padding(.horizontal, 10)
//        .padding(.vertical, 8)
//        .background(
//            RoundedRectangle(cornerRadius: 14)
//                .fill(.hmDarkestGray.opacity(0.6))
//        )
    }
    
    
    private func businessProfilePic(urlString: String) -> some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: 42, height: 42)
            .overlay(
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 39)
            )
            .overlay(
                WebImage(url: URL(string: urlString), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 36, height: 36)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 36, height: 36)
                })
            )
    }
    
    
    private func individualProfilePic(urlString: String) -> some View {
        Circle()
            .fill(.black)
            .frame(width: 42, height: 42)
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
    
    
    private var eventTitle: some View {
        Text(viewModel.eventPost?.name ?? "")
            .font(.custom(Constants.comicBold, size: 16))
            .foregroundColor(themeManager.currentTheme.label)
    }
    
    
    private var peopleJoinedSection: some View {
        HStack {
            if let interestedPeople = viewModel.eventPost?.interestedPeople {
                if interestedPeople == 0 {
                    Text("nobody_has_joined_yet".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 16))
                        .foregroundColor(themeManager.currentTheme.label)
                } else if interestedPeople == 1 {
                    Text("1_person_has_joined".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 16))
                        .foregroundColor(themeManager.currentTheme.label)
                } else {
                    Text("\(interestedPeople) \("people_have_joined".localized(localizationManager.language))")
                        .font(.custom(Constants.comicFont, size: 16))
                        .foregroundColor(themeManager.currentTheme.label)
                }
                
            } else {
                Text("nobody_has_joined_yet".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
            }
            
            
            
            Spacer()
            
            HStack(spacing: -12) {
                ForEach(viewModel.joiningPeople) { profile in
                    Circle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .frame(width: 30, height: 30)
                        .overlay {
                            WebImage(url: URL(string: profile.profilePic?.small ?? ""), content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                            }, placeholder: {
                                Image("NoProfilePic")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                            })
                        }
                        .clipShape(Circle())
                }
            }
        }
    }
    
    
    private var mapView: some View {
        
        GoogleMapView(currentLocation: $locationManager.currentLocation, markLocation: $viewModel.eventLocation2DCoordinates, markers: [], applyDarkTheme: false, scrollGestures: false, zoom: 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Adjust the map height as needed
            .animation(.easeInOut(duration: 0.5), value: locationManager.currentLocation)
    }
    
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("description".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 15))
                .foregroundColor(themeManager.currentTheme.label)
            
            Text(viewModel.attributedDescription)
                .font(.custom(Constants.comicFont, size: 13))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .multilineTextAlignment(.leading)
//            +
//            Text(viewModel.fullDescription.count > 160 ? "...Read more" : "")
//                .font(.custom(Constants.comicFont, size: 13))
//                .foregroundColor(.hmIndigo)
                
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var locationView: some View {
        HStack(alignment: .top, spacing: 16) {
            Image("LocationPin5")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.eventPost?.venue ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
                
                Text(viewModel.eventPost?.location?.placeName ?? "")
                    .font(.custom(Constants.comicFont, size: 11))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
                
        }
    }
    
    
    private var timeView: some View {
        HStack(alignment: .top, spacing: 16) {
            Image("calendarIcon2")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.isSameDate ? viewModel.startDate : "\(viewModel.startDate) - \(viewModel.endDate)")
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
                
                Text("\(viewModel.startTime) - \(viewModel.endTime)")
                    .font(.custom(Constants.comicFont, size: 11))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    private var mapSection: some View {
        VStack(alignment: .leading) {
            Text("about_the_event_venue".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 15))
                .foregroundColor(themeManager.currentTheme.label)
            
            mapView
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 14))
//                .overlay {
//                    Rectangle()
//                        .fill(.black.opacity(0.001))
//                }
            
            if viewModel.currentLatitude != 0.0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.0f", arguments: [viewModel.eventDistance]) + " km " + "distance_from_your_location".localized(localizationManager.language))
                        .font(.custom(Constants.comicBold, size: 16))
                        .foregroundColor(themeManager.currentTheme.label)
                    
                    Text(viewModel.eventPost?.location?.placeName ?? "")
                        .font(.custom(Constants.comicFont, size: 11))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    
    private func streamingLinkSection(link: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("streaming_link".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 15))
                .foregroundColor(themeManager.currentTheme.label)
            
            
            Link(destination: URL(string: link)!, label: {
                Text(link)
                    .font(.custom(Constants.comicFont, size: 11))
                    .foregroundColor(.hmIndigo)
                    .multilineTextAlignment(.leading)
            })
            
        }
        .padding(.bottom, 20)
    }
    
    
    private var joinButton: some View {
        HStack(spacing: 6) {
            if viewModel.imJoining {
                Image("BlueStar")
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.hmIndigo_white)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            } else {
                Image("BorderStar")
                    .resizable()
                    .frame(width: 22, height: 22)
            }
            
            
            Text(viewModel.imJoining ? "joined".localized(localizationManager.language) : "joining ?".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14.6))
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 10)
        }
//        .padding(.horizontal, 10)
//        .padding(.vertical, 7)
        .frame(width: 116, height: 38)
        .background(
            ZStack {
                Capsule()
                    .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(.hmIndigo.opacity(0.6))
            }
        )
        .onTapGesture {
            viewModel.imJoining.toggle()
            viewModel.joinEvent(id: viewModel.eventPost?.id ?? "")
            onPressedJoin?(viewModel.eventPost?.id ?? "")
        }
    }
    
    
    private var saveButton: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                .frame(width: 38, height: 38)
            Circle()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo.opacity(0.6))
                .frame(width: 38, height: 38)
        }
        .overlay {
            Image(viewModel.savedByMe ? themeManager.currentTheme.bookmarkfill : "bookmark")
                .resizable()
                .scaledToFit()
                .frame(width: 21, height: 21)
                .scaleEffect(viewModel.savedByMe ? 1.2 : 1.0)
    //            .animation(.none, value: viewModel.savedByMe)
        }
        .onTapGesture {
            viewModel.savedByMe.toggle()
            viewModel.saveAPost(id: viewModel.postID)
            onPressedShare?(viewModel.postID)
        }
       
    }
    
    
    private var shareButton: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                .frame(width: 38, height: 38)
            Circle()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo.opacity(0.6))
                .frame(width: 38, height: 38)
        }
        .overlay {
            Image("PaperPlane2")
                .resizable()
                .scaledToFit()
                .frame(width: 21, height: 21)
        }
    }
}
