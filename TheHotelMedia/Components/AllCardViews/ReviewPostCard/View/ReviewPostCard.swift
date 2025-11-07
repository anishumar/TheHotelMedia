//
//  ReviewPostCard.swift
//  HotelMedia
//
//  Created by MAC on 29/08/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReviewPostCard: View {
    @Binding var isPaused: Bool
    @Binding var postData: PostData
    @StateObject var viewModel: ReviewPostCardViewModel
    var onPressedLike: (() -> Void)? = nil
    var onPressedBookmark: (() -> Void)? = nil
    var onPressedComment: ((String) -> Void)? = nil
    var onPressedShare: ((String) -> Void)? = nil
    var onPressedProfile: ((String) -> Void)? = nil
    var onPressedEllipsis: ((String) -> Void)? = nil
    var onTapReview: ((String) -> Void)? = nil
    var onUserNotFound: (() -> Void)? = nil
    
    @State var isMute: Bool = false
    @State var skip: Bool = true
    @State var uiImage: UIImage? = nil
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.displayScale) var displayscale
    
    var body: some View {
        VStack(spacing: 12) {
            profileDetailView
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.001))
                        .onTapGesture {
                            if let publicUserID = viewModel.data.publicUserID {
                                guard publicUserID.isEmpty else {
                                    onUserNotFound?()
                                    return
                                }
                                if let id = viewModel.data.postedBy?.id {
                                    onPressedProfile?(id)
                                }
                            } else if viewModel.data.publicUserID == nil {
                                if let id = viewModel.data.postedBy?.id {
                                    onPressedProfile?(id)
                                }
                            }
                        }
                }
//            if let uiImage {
//                Image(uiImage: uiImage)
//                    .overlay {
//                        Rectangle()
//                            .fill(.black.opacity(0.001))
//                            .onTapGesture {
//                                if let publicUserID = viewModel.data.publicUserID {
//                                    guard publicUserID.isEmpty else {
//                                        onUserNotFound?()
//                                        return
//                                    }
//                                    if let id = viewModel.data.postedBy?.id {
//                                        onPressedProfile?(id)
//                                    }
//                                } else if viewModel.data.publicUserID == nil {
//                                    if let id = viewModel.data.postedBy?.id {
//                                        onPressedProfile?(id)
//                                    }
//                                }
//                            }
//                    }
//                    
//            }
//                .zIndex(2.0)
                
            contentView
//                .zIndex(1.0)
            if !viewModel.content.isEmpty {
                description()
//                    .zIndex(1.5)
            }
            divider
            HStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(viewModel.likedByMe ? "heartfill" : themeManager.currentTheme.heart)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .scaleEffect(viewModel.heartScale)
                    
                    Text(viewModel.likes)
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
                
                .onTapGesture {
                    haptics(.medium)
                    viewModel.likedByMe.toggle()
                    
                    if viewModel.likedByMe {
                        viewModel.likesCount += 1
                    } else {
                        viewModel.likesCount -= 1
                    }
                    onPressedLike?()
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
//            .zIndex(2.1)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .background(
            CustomShape4()
                .fill(themeManager.currentTheme.black09_white)
                
        )
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
        )
        .overlay(
            ellipsisButton
            , alignment: .topTrailing
        )
        .drawingGroup()
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
        .onReceive(NotificationCenter.default.publisher(for: .readmore), perform: { notification in
            if let id = notification.userInfo?["id"] as? String, id == postData.id {
                viewModel.data.isExpandedDescription.toggle()
                viewModel.fullDescription = viewModel.getSimpleDescription(content: viewModel.content)
            }
        })
        .onOpenURL { url in
            guard let host = url.host, host == viewModel.data.id ?? "" else { return }
            switch url.scheme {
//            case "feeling":
//                print("Feeling tapped: \(url.host ?? "")")
//            case "tags":
//                print("Tags tapped")
//            case "location":
//                print("Location tapped: \(url.host ?? "")")
            case "readmore":
                guard let host = url.host,
                      host == viewModel.data.id ?? "" else { return }
                viewModel.data.isExpandedDescription.toggle()
                viewModel.fullDescription = viewModel.getSimpleDescription(content: viewModel.content)
                
//            case "link":
//                if let host = url.host {
//                    let urlString = url.absoluteString.replacing("link://\(host)?url=", with: "")
//                    print(urlString)
//                    if let newUrl = URL(string: urlString) {
//                        onPressedUrl?(newUrl)
//                    }
//                }
            default:
                break
            }
        }
//        .onAppear {
//            Task {
//                uiImage = profileDetailView
//                    .render(scale: displayscale)
//            }
//        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        ReviewPostCard(isPaused: .constant(true), postData: .constant(DummyData.post), viewModel: ReviewPostCardViewModel(data: DummyData.post))
            
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        Color.black
            .ignoresSafeArea()
    )
    
}


// MARK: - Components
extension ReviewPostCard {
    private var divider: some View {
        Rectangle()
            .fill(themeManager.currentTheme.white03_darkGray03)
            .frame(height: 1)
    }
    
    
    private func description() -> some View {
        VStack {
            Text(viewModel.fullDescription)
        }
        .font(.custom(Constants.comicFont, size: 13.2))
        .foregroundStyle(themeManager.currentTheme.label)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var contentView: some View {
        ZStack {
            Rectangle()
                .fill(.hmDarkerGray)
                .frame(height: 290)
                .overlay {
                    WebImage(url: viewModel.coverImage.isEmpty ? nil : URL(string: viewModel.coverImage), content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: Constants.screenWidth - 38)
                            .frame(minHeight: (Constants.screenWidth) - (Constants.screenWidth)/4,  maxHeight: (Constants.screenWidth) + (Constants.screenWidth)/5)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .allowsHitTesting(false)
                    }, placeholder: {
                        Image("CoverPlaceholder")
                            .resizable()
                            .scaledToFit()
                    })
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            
            
        }
        .onTapGesture {
            if let postID = viewModel.data.id {
                onTapReview?(postID)
            }
        }
        .overlay(
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.85))
//                    .fill(.ultraThinMaterial)
//                    .preferredColorScheme(.dark)
                    .frame(height: 80)
                secondProfileDetailView
                    .onTapGesture {
                        if let googleReviewedBusiness = viewModel.data.googleReviewedBusiness {
                            guard googleReviewedBusiness.isEmpty else {
                                onUserNotFound?()
                                return
                            }
                            if let userID = viewModel.data.reviewedBusinessProfileRef?.userID {
                                onPressedProfile?(userID)
                            }
                        } else if viewModel.data.googleReviewedBusiness == nil {
                            if let userID = viewModel.data.reviewedBusinessProfileRef?.userID {
                                onPressedProfile?(userID)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 6)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
            }
            
            .clipShape(RoundedRectangle(cornerRadius: 14))
            , alignment: .top
        )
        .overlay(
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.85))
//                    .fill(.ultraThinMaterial)
                    .frame(height: 45)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                
                HStack {
                    HStack(spacing: 12) {
                        ForEach(0..<Int(viewModel.data.rating ?? 0)) { index in
                            FractionalStar(fraction: 1)
                                .frame(width: 20, height: 20)
                        }
                        
                        ForEach(0..<5 - Int(viewModel.data.rating ?? 0)) { index in
                            FractionalStar(fraction: 0)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .id(viewModel.data.rating)
                    Spacer()
                    
                    if let rating = viewModel.data.rating {
                        Text(rating == 1 ? "😢" : rating == 2 ? "🙁" : rating == 3 ? "😑" : rating == 4 ? "🙂" : "😍")
                            .font(.custom(Constants.comicFont, size: 20))
                    }
                    
                }
                .padding(.bottom, 12.5)
                .padding(.horizontal, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        )
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
//                BusinessProfilePicView(stringURL: viewModel.profilePic ?? "")
                businessProfilePicView
                    .offset(y: 4)

            } else {
//                IndividualProfilePicView(urlString: viewModel.profilePic ?? "")
                individualProfilePicView
                    .offset(y: 4)
            }
//            Image("Logo")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 46, height: 46)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.name ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .lineLimit(1)
                    .foregroundColor(themeManager.currentTheme.label)
                    .padding(.trailing, 40)
                
//                if viewModel.accountType == "business" {
//                    ratingView
//                }
                
                
                Text("\(DateManager.getPostedAgoTime(date: viewModel.data.createdAt ?? "", language: localizationManager.language))")
            }
            .padding(.top, 2)
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundColor(themeManager.currentTheme.white04_darkGray07)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
//        .onTapGesture {
//            if let publicUserID = viewModel.data.publicUserID {
//                guard publicUserID.isEmpty else {
//                    onUserNotFound?()
//                    return
//                }
//                if let id = viewModel.data.postedBy?.id {
//                    onPressedProfile?(id)
//                }
//            } else if viewModel.data.publicUserID == nil {
//                if let id = viewModel.data.postedBy?.id {
//                    onPressedProfile?(id)
//                }
//            }
//        }
    }
    
    
    private var businessProfilePicView: some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: 46, height: 46)
            .overlay(
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 43)
            )
            .overlay(
                WebImage(url: URL(string: viewModel.profilePic ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                        .allowsHitTesting(false)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                        .allowsHitTesting(false)
                })
            )
    }
    
    
    private var individualProfilePicView: some View {
        Circle()
            .fill(.black)
            .frame(width: 46, height: 46)
            .overlay(
                WebImage(url: URL(string: viewModel.profilePic ?? ""), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .allowsHitTesting(false)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .allowsHitTesting(false)
                })
            )
    }
    
    
    
    private var secondProfileDetailView: some View {
        HStack(alignment: .top, spacing: 15) {
            BusinessProfilePicView(stringURL: viewModel.data.reviewedBusinessProfileRef?.profilePic?.small ?? "")
                .offset(y: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.data.reviewedBusinessProfileRef?.name ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .lineLimit(1)
                    .foregroundStyle(themeManager.currentTheme.label)
                
                let rating = viewModel.data.reviewedBusinessProfileRef?.rating
                let type = viewModel.data.reviewedBusinessProfileRef?.businessTypeRef?.name ?? ""
                let subType = viewModel.data.reviewedBusinessProfileRef?.businessSubtypeRef?.name ?? ""
                
                if !type.isEmpty || !subType.isEmpty {
                    BusinessTypeAndRatingView(rating: rating, type: type, subType: subType)
                }
                
                Text(viewModel.businessAddress ?? "")
                    .lineLimit(2)
            }
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundStyle(themeManager.currentTheme.white04_darkGray07)
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
    }
}
