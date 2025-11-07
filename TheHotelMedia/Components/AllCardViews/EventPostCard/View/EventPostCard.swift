//
//  EventPostCard.swift
//  HotelMedia
//
//  Created by MAC on 29/08/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct EventPostCard: View {
    
    @Binding var isPaused: Bool
    @Binding var postData: PostData
    @StateObject var viewModel: EventCardViewModel
    var onPressedShare: ((String) -> Void)? = nil
    var onPressedBookmark: (() -> Void)? = nil
    var onPressedProfile: ((String) -> Void)? = nil
    var onPressedJoin: ((String) -> Void)? = nil
    var onPressedEvent: ((String) -> Void)? = nil
    var onPressedEllipsis: ((String) -> Void)? = nil
    var onPressedComment: ((String) -> Void)? = nil
    @State var isMute: Bool = false
    @State var skip: Bool = true
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            profileDetailView
                .drawingGroup()
                .onTapGesture {
                    if let id = viewModel.data.postedBy?.id {
                        onPressedProfile?(id)
                    }
                }
            contentView
                .onTapGesture {
                    onPressedEvent?(viewModel.data.id ?? "")
                }
            
            if viewModel.mediaContent.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<viewModel.mediaContent.count) { index in
                        Circle()
                            .fill(viewModel.currentPage == index ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.lightGray_mediumGray)
                            .frame(width: 4)
                    }
                }
                .id(viewModel.mediaContent)
                .drawingGroup()
            }
            
            description
                .drawingGroup()
            divider
            HStack(spacing: 6) {
                if viewModel.isValidEvent {
                    joinButton
                        .onTapGesture {
                            withAnimation(.smooth) {
    //                            isJoining.toggle()
                                viewModel.isJoining.toggle()
                                onPressedJoin?(viewModel.data.id ?? "")
                            }
                            
                        }
                }
                
                
                HMCustomButton(icon: .constant(themeManager.currentTheme.comment), count: $viewModel.comments)
                    .onTapGesture {
                        haptics(.light)
                        onPressedComment?(viewModel.data.id ?? "")
                    }
                
                HMCustomButton(icon: .constant(themeManager.currentTheme.share), count: $viewModel.shares)
                    .onTapGesture {
                        haptics(.light)
                        onPressedShare?(viewModel.data.id ?? "")
                    }
                
                if let views = viewModel.data.views, views > 0 {
                    HMCustomButton(icon: .constant(themeManager.currentTheme.eye3), count: .constant(Double(views).formatNumber()))
                }
                Spacer()
                Button(action: {
                    haptics(.light)
                    viewModel.savedByMe.toggle()
                    onPressedBookmark?()
                }) {
                    Image(viewModel.savedByMe ? "bookmarkfill" : themeManager.currentTheme.bookmark)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .scaleEffect(viewModel.savedByMe ? 1.2 : 1.0)
                        .animation(.none, value: viewModel.savedByMe)
                }
            }
            .padding(.vertical, 2)
            .drawingGroup()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .background(
            CustomShape4()
                .fill(themeManager.currentTheme.black09_white)
                .drawingGroup()
                
        )
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .drawingGroup()
        )
        .overlay(
            ellipsisButton
                .drawingGroup()
            , alignment: .topTrailing
        )
        .animation(.easeInOut(duration: 0.2 ), value: viewModel.currentPage)
        .onChange(of: isPaused, perform: { value in
            if viewModel.isPausePost != value {
                if !skip {
                    viewModel.isPausePost = value
                } else {
                    skip = false
                }
            }
        })
        .onChange(of: postData) { newValue in
            viewModel.data = postData
        }   
    }
}


// MARK: - Preview
#Preview {
    VStack {
        EventPostCard(isPaused: .constant(false), postData: .constant(DummyData.post), viewModel: EventCardViewModel(data: DummyData.post))
        
            
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        Color.black
            .ignoresSafeArea()
    )
}


// MARK: - Components
extension EventPostCard {
    
    private var divider: some View {
        Rectangle()
            .fill(themeManager.currentTheme.white03_darkGray03)
            .frame(height: 1)
    }
    
    
    private var joinButton: some View {
        HStack(spacing: 6) {
            if viewModel.isJoining {
                Image("BlueStar")
                    .resizable()
                    .frame(width: 15, height: 15)
            } else {
                Image(themeManager.currentTheme.BorderStar)
                    .resizable()
                    .frame(width: 15, height: 15)
            }
            
            
            Text(viewModel.isJoining ? "Joined" : "Joining ?")
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundStyle(themeManager.currentTheme.label)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo.opacity(0.6))
        )
    }
    
    
    private var description: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.data.name ?? "") // This is Event Name
                .font(.custom(Constants.comicBold, size: 14))
            
            
            if let venue = viewModel.data.venue, !venue.isEmpty {
                HStack {
                    Image(themeManager.currentTheme.LocationPin4)
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    
                    Text(venue)
                }
            }
            
            HStack {
                Image(themeManager.currentTheme.Clock)
                    .resizable()
                    .frame(width: 20, height: 20)
                
                Text(viewModel.dateAndTimeString)
            }
            
            if let interested = viewModel.data.interestedPeople {
                if interested == 1 {
                    Text("\(interested) person interested in this event.")
                } else if interested > 1 {
                    Text("\(interested) people interested in this event.")
                }
            }
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundStyle(themeManager.currentTheme.label)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var contentView: some View {
        
        ZStack {
            WebImage(url: URL(string: viewModel.firstImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(width: Constants.screenWidth - 38)
                    .frame(minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
            } placeholder: {
                Image("PostImagePlaceholder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
        }
        .drawingGroup()
        .opacity(0)
        .overlay(
            VStack {
                if !viewModel.mediaContent.isEmpty {
                    TabView(selection: $viewModel.currentPage) {
                        if !viewModel.mediaContent.isEmpty {
                            ForEach(0..<viewModel.mediaContent.count) { index in
                                if viewModel.mediaContent[index].isImage {
                                    VStack {
                                        WebImage(url: viewModel.mediaContent[index].url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: Constants.screenWidth - 38 , minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                            
                                        } placeholder: {
                                            Image("PostImagePlaceholder")
                                        }

                                    }
                                    .tag(index)
                                    
                                }
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .id(viewModel.mediaContent)
                }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
    }
    
    
    private var ellipsisButton: some View {
        Button(action: {
            onPressedEllipsis?(viewModel.data.id ?? "")
        }, label: {
            Circle()
                .fill(themeManager.currentTheme.black09_white)
                .frame(width: 28)
                .overlay(
                    Image(systemName: "ellipsis")
                        .foregroundStyle(themeManager.currentTheme.white_hmIndigo)
                )
        })
        .padding(.top, 8)
        .padding(.trailing, 8)
    }
    
    
    
    private var profileDetailView: some View {
        HStack(alignment: .top, spacing: 15) {
            if viewModel.accountType == "business" {
                BusinessProfilePicView(stringURL: viewModel.profilePic ?? "")
                    .offset(y: 4)
            } else {
                IndividualProfilePicView(urlString: viewModel.profilePic ?? "")
                    .offset(y: 4)
            }
            
            
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.name ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .lineLimit(1)
                    .foregroundStyle(themeManager.currentTheme.label)
                    .padding(.trailing, 40)
                
                if viewModel.accountType == "business" {
                    let rating = viewModel.data.postedBy?.businessProfileRef?.rating
                    let type = viewModel.data.postedBy?.businessProfileRef?.businessTypeRef?.name ?? ""
                    let subType = viewModel.data.postedBy?.businessProfileRef?.businessSubtypeRef?.name ?? ""
                    
                    BusinessTypeAndRatingView(rating: rating, type: type, subType: subType)
                }
                
                
                Text(viewModel.location)
            }
            .padding(.top, 2)
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundStyle(themeManager.currentTheme.white04_darkGray07)
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
    }
}
