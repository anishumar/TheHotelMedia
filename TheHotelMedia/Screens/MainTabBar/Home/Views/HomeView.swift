//
//  HomeView.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI
import UIKit
import SwiftUIPullToRefresh
import SDWebImageSwiftUI
import ActivityIndicatorView
import BetterScrollViewSwiftUI
import SwiftfulRouting
import AVKit


struct VisibleRectanglePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}


struct VisibleRectangleProfilePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}


struct DummyPostModel: Identifiable, Equatable {
    let id = UUID().uuidString
}


enum NavigationScreen {
    case notifiction
    case search
}


struct HomeView: View {
    
    @Binding var hideTabBar: Bool
    @Binding var uploadedNewStory: Bool
    @Binding var refreshHomeData: Bool
    @Binding var createPostOn: Bool
    @Binding var onDoubleTap: Bool
    @GestureState var dragState: DragState = .inactive
    @AppStorage("isIndividual") var isIndividual: Bool = true
    @AppStorage("ownUserID") var ownUserID: String = ""
    @AppStorage("hasReadNotifcation") var hasReadNotifcation: Bool = true
    @AppStorage("profilePic") var profilePic: String = ""
    
    @StateObject var viewModel: HomeViewModel
    @State var posts: [PostData] = []
    var plusButtonPressed: (() -> Void)?
    var onStoryButtonPressed: (() -> Void)?
    var onScrollChange: ((Bool) -> Void)?
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        
        PostView2(belongTo: .home, posts: $viewModel.allPosts, viewModel: PostViewModel2(router: viewModel.router), content: {
            ScrollView(.horizontal, showsIndicators: false) {
                profileStoriesSection
                    .padding(.horizontal, 12)
                    .padding(.top, 34)
                    .padding(.vertical, 5)
            }
        }, onPagination: {
            guard !viewModel.loadingHomeData else { return }
            viewModel.getHomeData(page: viewModel.currentPageNo + 1, showLoadingIndicator: false, suggestion: false)
        }, onPressedEvent: { id in
            refreshHomeData = false
            
        }, onEllipsisPressed: { yOffset, postID in
            viewModel.postOptionYOffset = yOffset
            viewModel.reportID = postID
            viewModel.reportType = "post"
            viewModel.showPostOptionView.toggle()
        }, onPressedSuggestionCross: { postID, suggestionID in
            if let postIndex = viewModel.allPosts.firstIndex(where: {$0.id == postID}) {
                if let suggIndex = viewModel.allPosts[postIndex].data?.firstIndex(where: {$0.id == suggestionID}) {
                    if let count = viewModel.allPosts[postIndex].data?.count, count <= 1 {
                        viewModel.allPosts.remove(at: postIndex)
                    } else {
                        viewModel.allPosts[postIndex].data?.remove(at: suggIndex)
                    }
                }
            }
        }, onScrollChange: { isScrolling in
            onScrollChange?(isScrolling)
            
        } , onRefresh: {
            Task {
                await viewModel.getStories(pageNo: 1)
                await viewModel.getHomeData(page: 1, refreshedData: true, showLoadingIndicator: false, suggestion: true)
            }
        }, onNavigate: {
            refreshHomeData = false
        })
        .environmentObject(viewModel)
        .background(
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
        )
        .overlay(alignment: .top) {
            header
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            if refreshHomeData || viewModel.createdNewContent {
                viewModel.getHomeData(page: 1, refreshedData: true, showLoadingIndicator: false, suggestion: true)
            }
            refreshHomeData = true
            UserDefaultsManager.shared.setMuteStatus(true)
            viewModel.getStories(refreshData: true, pageNo: 1)
            if viewModel.navigatedToNotification {
                viewModel.onNavigate(bool: false)
                viewModel.navigatedToNotification = false
            }
        }
        .onDisappear {
            viewModel.createdNewContent = false
            viewModel.navigationScreen = nil
            viewModel.newPostData = []
            viewModel.cancelHomeDataTask()
            viewModel.cancelStoryDataTask()
        }
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
                            viewModel.setMuteStatus(bool: true)
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            refreshHomeData = false
                            viewModel.showCreateReviewScreen()
                        }
                    } else {
                        BlueButton(title: "create_event".localized(localizationManager.language), icon: "CreateEvent") {
                            viewModel.setMuteStatus(bool: true)
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            refreshHomeData = false
                            viewModel.showCreateEventScreen()
                        }
                    }
                    
                    HStack {
                        Spacer()
                        BlueButton(title: "create_post".localized(localizationManager.language), icon: "CreatePost") {
                            viewModel.setMuteStatus(bool: true)
                            withAnimation(.smooth) {
                                createPostOn.toggle()
                            }
                            refreshHomeData = false
                            viewModel.showCreatePostScreen()
                        }
                        Spacer()
                        BlueButton(title: "create_story".localized(localizationManager.language), icon: "CreateStory") {
                            viewModel.setMuteStatus(bool: true)
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("newNotificationArrived"))) { notification in
            viewModel.showDot = !hasReadNotifcation
        }
        .onChange(of: uploadedNewStory, perform: { newValue in
            if newValue {
                viewModel.storyDataPageNo = 1
                viewModel.storyDataTotalPages = 1
                viewModel.getStories()
            }
        })
        .onChange(of: onDoubleTap) { newValue in
            viewModel.getHomeData(page: 1, refreshedData: true, showLoadingIndicator: true, suggestion: true)
        }
        .onReceive(networkMonitor.$isActive, perform: { bool in
            if !bool && viewModel.allPosts.isEmpty {
                viewModel.getHomeData(page: 1, refreshedData: true, showLoadingIndicator: true, suggestion: true)
                viewModel.getStories()
            }
        })
        .fullScreenCover(isPresented: $viewModel.showStoryScreen, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.onNavigate(bool: false)
            }
        }) {
            VStack {
                RouterView { router in
                    THMStoryView(stories: viewModel.stories, selectedIndex: viewModel.selectedStoryIndex, router: router) { story, message, emoji, isLiked in
                        print(story, message ?? "😃")
                    } onDeleteStory: { index in
        
                        
                    } onDismiss: {
                        viewModel.getStories(refreshData: true, pageNo: 1)
                        if !UserDefaultsManager.shared.getMuteStatus() {
                            do {
                                try AVAudioSession.sharedInstance().setCategory(.playback)
                            } catch(let error) {
                                print(error.localizedDescription)
                            }
                        } else {
                            do {
                                try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
                            } catch(let error) {
                                print(error.localizedDescription)
                            }
                        }
                    }
                    .environmentObject(themeManager)
                    .navigationBarBackButtonHidden()
                    .background(BackgroundClearView())
                }
                .background(BackgroundClearView())
            }
            .background(BackgroundClearView())
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
        .simultaneousGesture(swipeToChatGesture)
    }
}


// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        HomeView( hideTabBar: .constant(false), uploadedNewStory: .constant(false), refreshHomeData: .constant(false), createPostOn: .constant(false), onDoubleTap: .constant(false), viewModel: HomeViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Gestures
extension HomeView {
    private var swipeToChatGesture: some Gesture {
        DragGesture(minimumDistance: 25, coordinateSpace: .local)
            .updating($dragState) { value, state, _ in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                
                if abs(horizontal) > abs(vertical) {
                    state = .dragging(translation: value.translation)
                }
            }
            .onEnded { value in
                handleSwipeToChat(translation: value.translation)
            }
    }
    
    private func handleSwipeToChat(translation: CGSize) {
        let horizontal = translation.width
        let vertical = translation.height
        let horizontalMagnitude = abs(horizontal)
        let verticalMagnitude = abs(vertical)
        
        guard horizontal < -120 else { return }
        guard horizontalMagnitude > verticalMagnitude * 1.2 else { return }
        
        haptics(.light)
        openChatTab()
    }
}


// MARK: - Components

extension HomeView {
    private var header: some View {
        HStack {
            Image(themeManager.currentTheme.Title)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 38)
            
            Spacer()
            
            WeatherView()
                .onTapGesture {
                    if let weatherURL = URL(string: "https://www.google.com/search?q=weather") {
                        UIApplication.shared.open(weatherURL, options: [:], completionHandler: nil)
                    }
                }
            Button {
                DispatchQueue.main.async {
                    refreshHomeData = false
                    viewModel.showNotificationScreen()
//                    viewModel.showCreatePostScreen()
                }
            } label: {
                Image(themeManager.currentTheme.BellIcon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.leading)
                    .background(.black.opacity(0.001))
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .opacity(hasReadNotifcation ? 0.0 : 1.0)
                            .offset(x: -3, y: 5)
                    }
                    .offset(y: 2)
            }
            
            if !isIndividual {
                Image(themeManager.currentTheme.SearchIcon3)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .onTapGesture {
                        refreshHomeData = false
                        viewModel.showSearchScreen()
                    }
            }
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .padding(.horizontal, 12)
        .frame(height: 36, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    
    private var profileStoriesSection: some View {
        
        LazyHStack(spacing: 15) {
            Circle()
                .fill(viewModel.loadingStories ? themeManager.currentTheme.backgroundColor : viewModel.myStories.isEmpty ? themeManager.currentTheme.mediumGray_mediumGray03 : .hmIndigo)
                .frame(width: 68, height: 68)
                .overlay(
                    WebImage(url: URL(string: profilePic), content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                            .frame(width: 64, height: 64)
                    }, placeholder: {
                        Image("NoProfilePic")
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                            .frame(width: 64, height: 64)
                    })
                    .id(viewModel.profilePic)
                )
                .overlay {
                    VStack {
                        if viewModel.loadingStories {
                            ActivityIndicatorView(isVisible: .constant(true), type: .arcs(count: 2, lineWidth: 1.5))
                                .foregroundColor(.hmIndigo)
                                .frame(width: 72, height: 72)
                                .id(viewModel.loadingStories)
                        }
                        
                    }
                }
                .onTapGesture {
                    haptics(.light)
                    if !viewModel.myStories.isEmpty {
//                        isMute = true
                        UserDefaultsManager.shared.setMuteStatus(true)
                        viewModel.stories = viewModel.myStories
//                        viewModel.showStoryScreen()
                        viewModel.selectedStoryIndex = 0
                        viewModel.onNavigate(bool: true)
                        viewModel.showStoryScreen = true
                    }
                    
                }
            // PLUS BUTTON
                .overlay(
                    ZStack {
                        Circle()
                            .fill(.hmIndigo)
                            .frame(width: 26.5)
                        Image(systemName:"plus")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                    }
                        .onTapGesture {
                            plusButtonPressed?()
                        }
                    , alignment: .bottomTrailing
                )
            
            Rectangle()
                .fill(themeManager.currentTheme.white06_darkGray06)
                .frame(width: 1.3)
                .padding(.vertical)
            
            ForEach(viewModel.otherStories) { storyUser in
                Circle()
                    .fill(storyUser.isSeen ? themeManager.currentTheme.mediumGray_mediumGray03 : .hmIndigo)
                    .frame(width: 68, height: 68)
                    .overlay(
                        WebImage(url: URL(string: storyUser.user.image), content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: 64, height: 64)
                        }, placeholder: {
                            Image("NoProfilePic")
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: 64, height: 64)
                        })
                    )
                    .onTapGesture {
                        haptics(.light)
                        if let index = viewModel.otherStories.firstIndex(where: { $0.id == storyUser.id }), !viewModel.loadingStories {
//                            isMute = true
                            UserDefaultsManager.shared.setMuteStatus(true)
                            viewModel.stories = viewModel.otherStories
//                            viewModel.showStoryScreen(index: index)
                            viewModel.selectedStoryIndex = index
                            viewModel.onNavigate(bool: true)
                            viewModel.showStoryScreen = true
                        }
                    }
                    .onAppear {
                        viewModel.storyDataPageNo += 1
                        viewModel.getStories(refreshData: false, pageNo: viewModel.storyDataPageNo)
                    }
            }
        }
    }
    
    
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
}
