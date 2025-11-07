//
//  InsightsView.swift
//  HotelMedia
//
//  Created by MAC on 22/08/24.
//

import SwiftUI
import SDWebImageSwiftUI
import ActivityIndicatorView

struct InsightsView: View {
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject var viewModel: InsightViewModel
    @Binding var createPostOn: Bool
    @StateObject var insightCalendarViewModel = InsightCalendarViewModel()
    
    @AppStorage("isIndividual") var isIndividual: Bool = true
    
    var onStoryButtonPressed: (() -> Void)?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
//                Rectangle()
//                    .frame(height: 114)
//                    .overlay(
//                        InsightCalendarView(viewModel: InsightCalendarViewModel(), startDate: $viewModel.startDate, endDate: $viewModel.endDate, calendarType: $viewModel.selectedType)
//                            .background(.black)
//                            
//                    )
//                    .zIndex(2.0)
                InsightCalendarView(viewModel: insightCalendarViewModel, calendarType: $viewModel.selectedType)
                    .background(themeManager.currentTheme.backgroundColor)
                    .frame(height: 114)
                    .zIndex(2.0)
                
                VStack {
                    HStack {
//                        accountReachView
                        customDetailView(
                            value: viewModel.insightData?.dashboard?.accountReached ?? 0,
                            title: "account_reached".localized(localizationManager.language),
                            icon: "ReachIcon"
                        )
                        
                        customDetailView(
                            value: viewModel.insightData?.dashboard?.totalFollowers ?? 0,
                            title: "total_followers".localized(localizationManager.language),
                            icon: "TotalFollowers"
                        )
//                        accountFollowersView
                    }
                    HStack {
//                        accountEngagedView
//                        accountWebsiteRedirectionView
                        customDetailView(
                            value: viewModel.insightData?.dashboard?.engaged ?? 0,
                            title: "engaged".localized(localizationManager.language),
                            icon: "Engaged"
                        )
                        
                        customDetailView(
                            value: viewModel.insightData?.dashboard?.websiteRedirection ?? 0,
                            title: "website_redirection".localized(localizationManager.language),
                            icon: "WebsiteRedirect"
                        )
                    }
                }
                .padding(.horizontal, 12)
                .zIndex(1.0)
                
                VStack(alignment: .leading) {
                    Text("overview".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    
                    ChartView(viewModel: ChartViewModel(), chartData: $viewModel.chartData)
                }
                .padding(.horizontal, 12)
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("content_you_shared".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 18))
                        .padding(.leading, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !viewModel.stories.isEmpty {
                        VStack(alignment: .leading) {
                            Text("stories".localized(localizationManager.language))
                                .font(.custom(Constants.comicFont, size: 14))
                                .padding(.leading, 12)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack {
                                    ForEach(viewModel.stories) { story in
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.black)
                                            .frame(width: 110, height: 110)
                                            .onTapGesture {
                                                if let mimeType = story.mimeType {
                                                    if mimeType.contains("video") {
                                                        viewModel.selectedMedia = .video(urlString: story.sourceURL ?? "")
                                                    } else {
                                                        viewModel.selectedMedia = .image(urlString: story.sourceURL ?? "")
                                                    }
                                                }
                                                viewModel.showPreview = true
                                            }
                                            .overlay {
                                                VStack {
                                                    if let mimeType = story.mimeType {
                                                        if mimeType.contains("video") {
                                                            WebImage(url: URL(string: story.thumbnailUrl ?? "")) { image in
                                                                image
                                                                    .resizable()
                                                                    .scaledToFill()
                                                                    .frame(width: 110, height: 110)
                                                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                                                    .overlay {
                                                                        Image("PlayIcon")
                                                                            .resizable()
                                                                            .scaledToFit()
                                                                            .frame(width: 52, height: 52)
                                                                    }
                                                            } placeholder: {
                                                                ActivityIndicatorView(isVisible: .constant(true), type: .gradient([.hmIndigo, .black.opacity(0.4)], .butt, lineWidth: 4))
                                                                    .frame(width: 25, height: 25)
                                                                    .onAppear {
                                                                        Task {
                                                                            if let image = await viewModel.generateImage(videoURL: URL(string: story.sourceURL ?? "")!) {
                                                                                if let index = viewModel.stories.firstIndex(where: { $0.id == story.id }) {
                                                                                    viewModel.stories[index].videoThumbnail = image
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                            }
                                                        } else {
                                                            WebImage(url: URL(string: story.sourceURL ?? "")) { image in
                                                                image
                                                                    .resizable()
                                                                    .scaledToFill()
                                                                    .frame(width: 110, height: 110)
                                                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                                            } placeholder: {
                                                                ActivityIndicatorView(isVisible: .constant(true), type: .gradient([.hmIndigo, .black.opacity(0.4)], .butt, lineWidth: 4))
                                                                    .frame(width: 25, height: 25)
                                                            }
                                                        }
                                                    }
                                                }
                                                .allowsHitTesting(false)
                                            }
                                    }
                                }
                                .id(viewModel.refreshData)
                                .padding(.horizontal, 12)
                            }
                            .fullScreenCover(isPresented: $viewModel.showPreview, onDismiss: {
                                modifyOrientation(.portrait)
                            }, content: {
                                MediaPreviewView(media: viewModel.selectedMedia)
                                    .background(BackgroundClearView())
                            })
                        }
                    }
                    
                    if !viewModel.mediaRefArray.isEmpty {
                        VStack(alignment: .leading) {
                            Text("posts".localized(localizationManager.language))
                                .font(.custom(Constants.comicFont, size: 14))
                                .padding(.leading, 12)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack {
                                    ForEach(viewModel.mediaRefArray) { media in
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.black)
                                            .frame(width: 110, height: 110)
                                            .onTapGesture {
                                                if media.postType == "event" {
                                                    viewModel.showEventDetailScreen(eventID: media.postID ?? "")
                                                } else {
                                                    viewModel.showPostScreen(postID: media.postID ?? "")
                                                }
                                            }
                                            .overlay {
                                                VStack {
                                                    if let mimeType = media.mimeType {
                                                        if mimeType.contains("video") {
                                                            WebImage(url: URL(string: media.thumbnailURL ?? "")) { image in
                                                                image
                                                                    .resizable()
                                                                    .scaledToFill()
                                                                    .frame(width: 110, height: 110)
                                                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                                                    .overlay {
                                                                        Image("PlayIcon")
                                                                            .resizable()
                                                                            .scaledToFit()
                                                                            .frame(width: 52, height: 52)
                                                                    }
                                                            } placeholder: {
                                                                ActivityIndicatorView(isVisible: .constant(true), type: .gradient([.hmIndigo, .black.opacity(0.4)], .butt, lineWidth: 4))
                                                                    .frame(width: 25, height: 25)
                                                                    .onAppear {
                                                                        Task {
                                                                            if let image = await viewModel.generateImage(videoURL: URL(string: media.sourceURL ?? "")!) {
                                                                                if let index = viewModel.mediaRefArray.firstIndex(where: { $0.id == media.id }) {
                                                                                    viewModel.mediaRefArray[index].videoThumbnail = image
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                            }
                                                        } else {
                                                            WebImage(url: URL(string: media.sourceURL ?? "")) { image in
                                                                image
                                                                    .resizable()
                                                                    .scaledToFill()
                                                                    .frame(width: 110, height: 110)
                                                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                                            } placeholder: {
                                                                ActivityIndicatorView(isVisible: .constant(true), type: .gradient([.hmIndigo, .black.opacity(0.4)], .butt, lineWidth: 4))
                                                                    .frame(width: 25, height: 25)
                                                            }
                                                        }
                                                    }
                                                }
                                                .allowsHitTesting(false)
                                            }
                                    }
                                }
                                .id(viewModel.refreshData)
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                }
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            }
            .padding(.top, 45)
            .padding(.bottom, 90)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.currentTheme.backgroundColor)
        }
        .clipped()
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .onAppear {
            viewModel.selectedType = .week
        }
        .onDisappear {
            if viewModel.insightData != nil {
                viewModel.cancelInsightDataTask()
            }
        }
        .overlay(
            HeaderView {
                haptics(.light)
                viewModel.showNotificationScreen()
            }
            , alignment: .top
        )
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
    }
}

// MARK: - Preview
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        InsightsView(viewModel: InsightViewModel(router: router), createPostOn: .constant(false))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components
extension InsightsView {
    
    private var accountReachView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.insightData?.dashboard?.accountReached ?? 0)")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(.white)
                .padding(.top, 10)
            
            Text("account_reached".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 8.5)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading,5)
        .background(
            CustomShape3()
                .fill(.black.opacity(0.9))
        )
        .padding(3)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.hmIndigo.opacity(0.5))
        )
        .overlay(
            Image("ReachIcon")
                .padding(.top, 7)
                .padding(.trailing, 7)
            , alignment: .topTrailing
        )
    }
    
    
    private func customDetailView(value: Int, title: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.label)
                .padding(.top, 10)
            
            Text(title)
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .padding(.bottom, 8.5)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading,5)
        .background(
            CustomShape3()
                .fill(themeManager.currentTheme.black09_white)
        )
        .padding(3)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
        )
        .overlay(
            Image(icon)
                .padding(.top, 7)
                .padding(.trailing, 7)
            , alignment: .topTrailing
        )
    }
    
    
    private var accountFollowersView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.insightData?.dashboard?.totalFollowers ?? 0)")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(.white)
                .padding(.top, 10)
            
            Text("total_followers".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 8.5)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading,5)
        .background(
            CustomShape3()
                .fill(.black.opacity(0.9))
        )
        .padding(3)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.hmIndigo.opacity(0.5))
        )
        .overlay(
            Image("TotalFollowers")
                .padding(.top, 7)
                .padding(.trailing, 7)
            , alignment: .topTrailing
        )
    }
    
    
    private var accountEngagedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.insightData?.dashboard?.engaged ?? 0)")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(.white)
                .padding(.top, 10)
            
            Text("engaged".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 8.5)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading,5)
        .background(
            CustomShape3()
                .fill(.black.opacity(0.9))
        )
        .padding(3)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.hmIndigo.opacity(0.5))
        )
        .overlay(
            Image("Engaged")
                .padding(.top, 7)
                .padding(.trailing, 7)
            , alignment: .topTrailing
        )
    }
    
    
    private var accountWebsiteRedirectionView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.insightData?.dashboard?.websiteRedirection ?? 0)")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(.white)
                .padding(.top, 10)
            
            Text("website_redirection".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 8.5)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading,5)
        .background(
            CustomShape3()
                .fill(.black.opacity(0.9))
        )
        .padding(3)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.hmIndigo.opacity(0.5))
        )
        .overlay(
            Image("WebsiteRedirect")
                .padding(.top, 7)
                .padding(.trailing, 7)
            , alignment: .topTrailing
        )
    }
    
}
