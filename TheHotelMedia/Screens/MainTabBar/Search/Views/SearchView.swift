//
//  SearchView.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI
import Flow
import SDWebImageSwiftUI


struct SearchView: View {
    
    @Binding var hideTabbar: Bool
    @Binding var createPostOn: Bool
    @StateObject var viewModel: SearchViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @AppStorage("isIndividual") var isIndividual: Bool = true
    @AppStorage("ownUserID") var ownUserID: String = ""
//    @Namespace var blueCapsuleNamespace
    
    @StateObject private var keyboardManager = KeyboardManager2()
    var onStoryButtonPressed: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 14){
            if isIndividual {
                HeaderView {
                    viewModel.showNotificationScreen()
                }
            } else {
                dismissHeader
            }
            
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 10) {
                    searchField
                        .fullScreenCover(isPresented: $viewModel.showPlaceSearch, onDismiss: {
                            if viewModel.isChangingLocationDirectly {
                                viewModel.nearbyProfileData.removeAll()
                                viewModel.nearbyDataPageNo = 1
                                viewModel.getSearchResult(type: .business, query: viewModel.searchFieldText, resetData: true)
                                viewModel.isChangingLocationDirectly = false
                            }
                        }) {
                            PlacesSearchRepresentable(selectedPlace: $viewModel.selectedPlace, isPresented: $viewModel.showPlaceSearch)
                                .edgesIgnoringSafeArea(.all) // Make the autocomplete view full-screen
                        }
                    if viewModel.showSearchFilterView {
                        filterSection
                            .onAppear {
                                viewModel.selectedBusinessType = viewModel.appliedBusinessType
                            }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            tabButtonsView
                            tabView
                                .overlay {
                                    if keyboardManager.isKeyboardOpen {
                                        Color.black.opacity(0.001)
                                            .onTapGesture {
                                                endEditing()
                                            }
                                    }
                                }
                        }
                    }
                }
                .onReceive(viewModel.$showSearchFilterView, perform: { bool in
                    hideTabbar = bool
                })
                .padding(.horizontal, 12)
                .frame(height: Constants.screenHeight - 46, alignment: .top)
//                .animation(.easeInOut, value: viewModel.showSearchFilterView)
            }
            .scrollDisabled(true)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .withComicFont(12.5, color: themeManager.currentTheme.white06_darkGray06)
//        .onAppear {
//            viewModel.searchFieldText = ""
//            viewModel.selectedBusinessTypes.removeAll()
//            viewModel.selectedCoordinates = viewModel.currentCoordinate
//        }
        .onReceive(NotificationCenter.default.publisher(for: .currentTab), perform: { notification in
            if let currentTab = notification.object as? TabbedItem {
                if currentTab == .search {
                    viewModel.searchFieldText = ""
                    viewModel.selectedBusinessTypes.removeAll()
                    viewModel.selectedCoordinates = viewModel.currentCoordinate
                }
            }
        })
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay {
            ZStack(alignment: .topTrailing) {
                if viewModel.showPostOptionView {
                    themeManager.currentTheme.black05_white05
                        .onTapGesture {
                            viewModel.showPostOptionView.toggle()
                        }
                    VStack(spacing: 6) {
                        capsuleButtonView(title: "report".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showReportScreen = true
                                viewModel.showPostOptionView.toggle()
                            }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                    )
                    .offset(x: -16, y: viewModel.postOptionYOffset - UIApplication.topSafeAreaHeightTHM + 40)
                }
            }
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
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .alert("Location Access Denied", isPresented: $viewModel.locationManager.showAlert) {
            Button("Open Settings") {
                viewModel.locationManager.openAppSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To use this feature, please enable location access in Settings.")
        }
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SearchView(hideTabbar: .constant(true), createPostOn: .constant(false), viewModel: SearchViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


extension SearchView {
    
    private func capsuleButtonView(title: String) -> some View {
        Text(title)
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundColor(themeManager.currentTheme.label)
            .frame(width: 74, height: 26, alignment: .center)
            .background(
                ZStack {
                    Capsule()
                        .fill(themeManager.currentTheme.darkGray05_white)
                    Capsule()
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                }
            )
    }
    
    
    private var dismissHeader: some View {
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
            
            Text("search".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
    }
    
    private var tabButtonsView: some View {
        HStack(spacing: 6) {
            let width = (UIScreen.main.bounds.width - 24 - 24) / 5
            tabButton(type: .business, width: width)
            tabButton(type: .profile, width: width)
            tabButton(type: .post, width: width)
            tabButton(type: .event, width: width)
            tabButton(type: .review, width: width)
        }
    }
    
    
    private var tabView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                switch viewModel.selectedType {
                case .profile:
                    profilesTab
                        .onAppear {
                            guard viewModel.refreshOnAppear else { return }
                            viewModel.searchProfileData.removeAll()
                            viewModel.profileDataPageNo = 1
                            viewModel.getSearchResult(type: .profile, query: viewModel.searchFieldText, resetData: true)
                        }
                case .post:
                    postsTab
                        .onAppear {
                            guard viewModel.refreshOnAppear else { return }
                            viewModel.searchPostData.removeAll()
                            viewModel.postDataPageNo = 1
                            viewModel.getSearchResult(type: .post, query: viewModel.searchFieldText, resetData: true)
                        }
                case .event:
                    eventsTab
                        .onAppear {
                            guard viewModel.refreshOnAppear else { return }
                            viewModel.searchEventData.removeAll()
                            viewModel.eventDataPageNo = 1
                            viewModel.getSearchResult(type: .event, query: viewModel.searchFieldText, resetData: true)
                        }
                case .review:
                    reviewsTab
                        .onAppear {
                            guard viewModel.refreshOnAppear else { return }
                            viewModel.searchReviewData.removeAll()
                            viewModel.reviewDataPageNo = 1
                            viewModel.getSearchResult(type: .review, query: viewModel.searchFieldText, resetData: true)
                        }
                case .business:
                    nearbyTab
                        .onAppear {
                            guard viewModel.refreshOnAppear else { return }
                            
                            if viewModel.selectedCoordinates != nil {
                                viewModel.nearbyProfileData.removeAll()
                                viewModel.nearbyDataPageNo = 1
                                viewModel.getSearchResult(type: .business, query: viewModel.searchFieldText, resetData: true)
                            } else {
                                viewModel.locationManager.requestLocationPermission()
                            }
                        }
                }
                
                if viewModel.selectedType == .business || viewModel.selectedType == .profile {
                    Rectangle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: UIApplication.bottomSafeAreaHeightTHM > 0 ? 170 : 100)
                }
            }
            .sheet(isPresented: $viewModel.showReportScreen, content: {
                ReportView(viewModel: ReportViewModel(reportID: viewModel.reportID, reportType: viewModel.reportType, onReport: { message in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                        ErrorModalManager.showErrorModal(router: viewModel.router, errorText: message)
                    }
                }))
                .environmentObject(themeManager)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.fraction(Constants.getReportSheetHeight())])
            })
        }
    }
    
    
    
    private var profilesTab: some View {
        VStack {
            LazyVStack {
                ForEach(viewModel.searchProfileData) { profile in
                    if let index = viewModel.searchProfileData.firstIndex(where: {$0.id == profile.id}) {
                        ProfileCardView(viewModel: ProfileCardViewModel(profile: profile), onEllipsisButtonPressed: { profileID in
//                            if let index {
//                                
//                            }
                            viewModel.postOptionYOffset = viewModel.yOffsetArrayOfProfiles[index]
                            viewModel.reportType = "user"
                            viewModel.reportID = profileID
                            viewModel.showPostOptionView.toggle()
                        })
                        .overlay(
                            GeometryReader { geo in
                                Color.black.opacity(0.0001)
                                    .preference(key: VisibleRectangleProfilePreferenceKey.self, value: geo.frame(in: .global))
                                    .allowsHitTesting(false)
                            }
                        )
                        .onPreferenceChange(VisibleRectangleProfilePreferenceKey.self) { frame in
//                            if let index {
//                                
//                            }
                            if viewModel.profilesCount - 1 >= index {
                                viewModel.yOffsetArrayOfProfiles[index] = frame.minY
                            }
                        }
                        .onTapGesture {
                            endEditing()
//                            if ownUserID != profile.id {
//                                viewModel.showUserProfileScreen(id: profile.id)
//                            }
                            viewModel.refreshOnAppear = false
                            viewModel.showUserProfileScreen(id: profile.id)
                        }
                        .onAppear {
                            if let lastProfile = viewModel.searchProfileData.last {
                                if lastProfile.id == profile.id {
                                    print("Last Profile")
                                    viewModel.profileDataPageNo += 1
                                    viewModel.getSearchResult(type: .profile, query: viewModel.searchFieldText)
                                }
                            }
                        }
                    }
                }
//                Rectangle()
//                    .fill(themeManager.currentTheme.backgroundColor)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 100)
            }
            
            if viewModel.searchProfileData.isEmpty {
                EmptyScreenView(image: "Search3", title: "no_result_found".localized(localizationManager.language), height: 0.3)
                    .opacity(viewModel.showLoadingIndicator ? 0.0 : 1.0)
            }
        }
//        .id(viewModel.searchProfileData)
        .frame(maxWidth: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
//        .id(viewModel.searchProfileData)
    }
    
    
    private var nearbyTab: some View {
        VStack {
            LazyVStack {
                ForEach(viewModel.nearbyProfileData) { profile in
                    if let index = viewModel.nearbyProfileData.firstIndex(where: {$0.id == profile.id}) {
                        ProfileCardView(viewModel: ProfileCardViewModel(profile: profile), onEllipsisButtonPressed: { profileID in
//                            if let index {
//
//                            }
                            viewModel.postOptionYOffset = viewModel.yOffsetArrayOfNearbyProfiles[index]
                            viewModel.reportType = "user"
                            viewModel.reportID = profileID
                            viewModel.showPostOptionView.toggle()
                        })
                        .overlay(
                            GeometryReader { geo in
                                Color.black.opacity(0.0001)
                                    .preference(key: VisibleRectangleProfilePreferenceKey.self, value: geo.frame(in: .global))
                                    .allowsHitTesting(false)
                            }
                        )
                        .onPreferenceChange(VisibleRectangleProfilePreferenceKey.self) { frame in
//                            if let index {
//
//                            }
                            if viewModel.nearbyProfilesCount - 1 >= index {
                                viewModel.yOffsetArrayOfNearbyProfiles[index] = frame.minY
                            }
                        }
                        .onTapGesture {
                            endEditing()
//                            if ownUserID != profile.id {
//                                viewModel.showUserProfileScreen(id: profile.id)
//                            }
                            viewModel.refreshOnAppear = false
                            viewModel.showUserProfileScreen(id: profile.id)
                        }
                        .onAppear {
                            if let lastProfile = viewModel.nearbyProfileData.last {
                                if lastProfile.id == profile.id {
                                    print("Last Profile")
                                    viewModel.nearbyDataPageNo += 1
                                    viewModel.getSearchResult(type: .business, query: viewModel.searchFieldText)
                                }
                            }
                        }
                    }
                }
//                Rectangle()
//                    .fill(themeManager.currentTheme.backgroundColor)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 100)
            }
            
            if viewModel.nearbyProfileData.isEmpty {
                EmptyScreenView(image: "Search3", title: "Try changing location!".localized(localizationManager.language), buttonTitle: "Change Location".localized(localizationManager.language), height: 0.3, onPressedButton: {
                    viewModel.isChangingLocationDirectly = true
                    viewModel.showPlaceSearch.toggle()
                })
                    .opacity(viewModel.showLoadingIndicator ? 0.0 : 1.0)
            }
        }
//        .id(viewModel.nearbyProfileData)
        .frame(maxWidth: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
//        .id(viewModel.searchProfileData)
    }
    
    
    private var postsTab: some View {
        VStack {
            PostView(belongTo: .search, posts: $viewModel.searchPostData, viewModel: PostViewModel(router: viewModel.router), onPagination: {
                viewModel.postDataPageNo += 1
                viewModel.getPostResults(type: .post, query: viewModel.searchFieldText, resetData: false)
                
            }, onPressedProfile: { id in
//                if ownUserID != id {
//                    viewModel.showUserProfileScreen(id: id)
//                }
//                viewModel.showUserProfileScreen(id: id)
            }, onEllipsisPressed: { yOffset, postID in
                viewModel.postOptionYOffset = yOffset
                viewModel.reportID = postID
                viewModel.reportType = "post"
                viewModel.showPostOptionView.toggle()
            })
            
            if viewModel.searchPostData.isEmpty {
                EmptyScreenView(image: "Search3", title: "no_result_found".localized(localizationManager.language), height: 0.3)
                    .opacity(viewModel.showLoadingIndicator ? 0.0 : 1.0)
            }
        }
        
    }
    
    
    private var eventsTab: some View {
        VStack {
            PostView(belongTo: .search, posts: $viewModel.searchEventData, viewModel: PostViewModel(router: viewModel.router), onPagination: {
                viewModel.eventDataPageNo += 1
                viewModel.getPostResults(type: .event, query: viewModel.searchFieldText, resetData: false)
                
            },onPressedProfile: { id in
//                if ownUserID != id {
//                    viewModel.showUserProfileScreen(id: id)
//                }
//                viewModel.showUserProfileScreen(id: id)
            },onPressedEvent: { id in
//                viewModel.showEventDetailScreen(id: id)
                
            } , onEllipsisPressed: { yOffset, postID in
                viewModel.postOptionYOffset = yOffset
                viewModel.reportID = postID
                viewModel.reportType = "post"
                viewModel.showPostOptionView.toggle()
            })
            
            
            if viewModel.searchEventData.isEmpty {
                EmptyScreenView(image: "Search3", title: "no_result_found".localized(localizationManager.language), height: 0.3)
                    .opacity(viewModel.showLoadingIndicator ? 0.0 : 1.0)
            }
        }
    }
    
//    private var eventsTab2: some View {
//        VStack {
//            
//            PostView2(belongTo: .search, posts: $viewModel.searchEventData, viewModel: PostViewModel2(router: viewModel.router), onPagination: {
//                viewModel.eventDataPageNo += 1
//                viewModel.getPostResults(type: .event, query: viewModel.searchFieldText, resetData: false)
//            }, onEllipsisPressed: { yOffset, postID in
//                viewModel.postOptionYOffset = yOffset
//                viewModel.reportID = postID
//                viewModel.reportType = "post"
//                viewModel.showPostOptionView.toggle()
//            })
//            
//            
//            if viewModel.searchEventData.isEmpty {
//                EmptyScreenView(image: "Search3", title: "no_result_found".localized(localizationManager.language), height: 0.3)
//                    .opacity(viewModel.showLoadingIndicator ? 0.0 : 1.0)
//            }
//        }
//    }
    
    
    private var reviewsTab: some View {
        VStack {
            PostView(belongTo: .search, posts: $viewModel.searchReviewData, viewModel: PostViewModel(router: viewModel.router), onPagination: {
                viewModel.reviewDataPageNo += 1
                viewModel.getPostResults(type: .review, query: viewModel.searchFieldText, resetData: false)
                
            },onPressedProfile: { id in
//                if ownUserID != id {
//                    viewModel.showUserProfileScreen(id: id)
//                }
//                viewModel.showUserProfileScreen(id: id)
                
            } , onEllipsisPressed: { yOffset, postID in
                viewModel.postOptionYOffset = yOffset
                viewModel.reportID = postID
                viewModel.reportType = "post"
                viewModel.showPostOptionView.toggle()
            })
            
            if viewModel.searchReviewData.isEmpty {
                EmptyScreenView(image: "Search3", title: "no_result_found".localized(localizationManager.language), height: 0.3)
                    .opacity(viewModel.showLoadingIndicator ? 0.0 : 1.0)
            }
        }
    }
    
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 23) {
            categoryFilterSection
            locationView
                .onTapGesture {
                    viewModel.showPlaceSearch.toggle()
                }
                
            sliderView
            
//            HFlow {
//                ForEach(viewModel.mostlySearched, id: \.self) { text in
//                    Button(action: {
//                        
//                    }, label: {
//                        HStack {
//                            Image("Hotel2")
//                                .resizable()
//                                .frame(width: 15, height: 15)
//                            Text(text)
//                                
//                                
//                        }
//                        .padding(.horizontal)
//                        .background(
//                            CapsuleBackground(height: 28.5)
//                        )
//                    })
//                    .frame(height: 30)
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                if !viewModel.selectedBusinessTypes.isEmpty {
                    viewModel.selectedType = .business
                }
                viewModel.showSearchFilterView = false
            }, label: {
                Text("apply".localized(localizationManager.language).capitalized)
                    .withComicFont(15.5, color: .white)
                    .frame(width: 147, height: 45)
                    .background(
                        Capsule()
                            .fill(
                                themeManager.currentTheme.hmIndigo_hmIndigo05
//                                .shadow(.inner(color: .black, radius: 5))
//                                .shadow(.inner(color: .black, radius: 3))
//                                .shadow(.inner(color: .black, radius: 2.5))
                            )
                    )
                    .overlay(content: {
                        Capsule()
                            .stroke(lineWidth: 1)
                            .fill(themeManager.currentTheme.backgroundColor)
                    })
                    .frame(maxWidth: .infinity)
            })
        }
        .padding(.horizontal, 12)
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
            
            if viewModel.showSearchFilterView {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .onTapGesture {
                        endEditing()
                        viewModel.radius = 50
                        viewModel.selectedBusinessTypes.removeAll()
                        if let currentCoordinates = viewModel.currentCoordinate {
                            viewModel.selectedCoordinates = currentCoordinates
                            viewModel.addressString = viewModel.currentAddressString
                        }
                        viewModel.showSearchFilterView.toggle()
                    }
            } else {
                Image("FilterIcon")
                    .renderingMode(.template)
                    .font(.system(size: 23))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .onTapGesture {
                        viewModel.refreshOnAppear = true
                        viewModel.showSearchFilterView.toggle()
                    }
            }
            
        }
        .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
        .frame(height: 47)
        .padding(.horizontal, 12)
        .background(
            CapsuleBackground(borderColor: themeManager.currentTheme.mediumGray_hmIndigo, backgroundColor: themeManager.currentTheme.darkGray05_white)
        )
    }
    
    
    private func businessCategoryButton(type: TypeModel) -> some View {
        HStack {
            WebImage(url: URL(string: type.icon ?? ""))
                .resizable()
                .renderingMode(.template)
                .foregroundColor(viewModel.selectedBusinessTypes.contains(where: {$0.id == type.id}) ? .white : themeManager.currentTheme.white_darkGray)
                .frame(width: 15, height: 15)
            
            Text(type.name ?? "")
                .withComicFont(11, color: viewModel.selectedBusinessTypes.contains(where: {$0.id == type.id}) ? .white : themeManager.currentTheme.white06_darkGray06)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 11)
        .background(
            CapsuleBackground(
                height: 29,
                borderColor: viewModel.selectedBusinessTypes.contains(where: {$0.id == type.id}) ? .clear : .hmDarkerGray,
                backgroundColor: viewModel.selectedBusinessTypes.contains(where: {$0.id == type.id}) ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.darkGray05_white
            )
        )
        .onTapGesture {
            if let index = viewModel.selectedBusinessTypes.firstIndex(where: {$0.id == type.id}) {
                viewModel.selectedBusinessTypes.remove(at: index)
            } else {
                viewModel.selectedBusinessTypes.append(type)
            }
            
//            if viewModel.selectedBusinessType?.id == type.id {
//                viewModel.selectedBusinessType = nil
//            } else {
//                viewModel.selectedBusinessType = type
//            }
        }
    }
    
    
    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("looking_for".localized(localizationManager.language))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
            HFlow {
                ForEach(viewModel.businessTypes) { type in
                    businessCategoryButton(type: type)
                }
            }
        }
    }
    
    
    private var sliderLabelView: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 29)
            Circle()
                .fill(.hmIndigo)
                .frame(width: 24)
        }
    }
    
    
    private var locationView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("location".localized(localizationManager.language))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
            HStack {
                Image("LocationPin2")
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(viewModel.addressString.isEmpty ? "Select a location" : viewModel.addressString)
                    .foregroundColor(viewModel.addressString.isEmpty ? .white.opacity(0.6) : themeManager.currentTheme.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(CapsuleBackground(height: 40, borderColor: viewModel.addressString.isEmpty ? .hmDarkerGray : .hmIndigo, backgroundColor: themeManager.currentTheme.darkGray05_white))
        }
    }
    
    
    private var sliderView: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("radius".localized(localizationManager.language))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(String(format: "%.0f", arguments: [viewModel.radius]))km")
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
            }
            Slider(value: $viewModel.radius, in: 1...100, step: 1)
        }
    }
    
    
    private func tabButton(type: PostType, width: CGFloat) -> some View {
        Text(type == .business && (!viewModel.selectedBusinessTypes.isEmpty || viewModel.selectedCoordinates != viewModel.currentCoordinate) ? "business".localized(localizationManager.language) : type.rawValue.lowercased().localized(localizationManager.language))
            .withComicFont(12, color: viewModel.selectedType == type ? .white : themeManager.currentTheme.white06_darkGray06)
            .frame(width: width, height: 32)
            .background(
                ZStack {
                    if viewModel.selectedType == type {
                        CapsuleBackground(
                            height: 32,
                            borderWidth: 1.2,
                            borderColor: .clear,
                            backgroundColor: themeManager.currentTheme.hmIndigo07_hmIndigo
                        )
//                        .matchedGeometryEffect(id: "blueCapsuleNamespace", in: blueCapsuleNamespace)
                    } else {
                        CapsuleBackground(
                            height: 32,
                            borderWidth: 1.2,
                            borderColor: .clear,
                            backgroundColor: themeManager.currentTheme.darkGray06_mediumGray03
                        )
                    }
                }
//                    .animation(.bouncy, value: viewModel.selectedType)
//                CapsuleBackground(
//                    height: 32,
//                    borderWidth: 1.2,
//                    borderColor: .clear,
//                    backgroundColor: viewModel.selectedType == type ? themeManager.currentTheme.hmIndigo07_hmIndigo : themeManager.currentTheme.darkGray06_mediumGray03
//                )
            )
            .onTapGesture {
                viewModel.refreshOnAppear = true
                viewModel.selectedType = type
            }
    }
}
