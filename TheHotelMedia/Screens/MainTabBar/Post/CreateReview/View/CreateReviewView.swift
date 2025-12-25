//
//  CreateReviewView.swift
//  TheHotelMedia
//
//  Created by MAC on 25/09/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Lottie

struct CreateReviewView: View {
    
    @StateObject var viewModel: CreateReviewViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                checkinButton
                if viewModel.reviewPlace != nil {
                    reviewSection
                }
                
            }
            .padding(.top, 60)
            .padding(.horizontal, 12)
        }
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay(
            header
                .padding(.bottom, 4)
                .padding(.horizontal, 12)
                .background(
                    themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                )
            , alignment: .top
        )
        .overlay {
            ZStack {
                if viewModel.showLoadingAnimation {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    VStack {
                        LottieView(animation: .named("Animation-Posting"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
                            
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
            }
        }
        .overlay {
            ZStack {
                if viewModel.postUploaded {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    VStack {
                        Spacer()
                        LottieView(animation: .named("Animation-Uploaded"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                            .animationDidFinish { completed in
                                viewModel.postUploaded = false
                                viewModel.dismissScreen()
                            }
                            .scaleEffect(1.5)
                        Spacer()
                        Text("review_uploaded_successfully".localized(localizationManager.language))
                            .font(.custom(Constants.comicFont, size: 12))
                            .foregroundColor(themeManager.currentTheme.label)
                            .padding(.bottom, 10)
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
            }
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}


// MARK: - Preview
struct CreateReviewView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        CreateReviewView(viewModel: CreateReviewViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components
extension CreateReviewView {
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
            
            Text("review".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                viewModel.createReview()
            }, label: {
                Circle()
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    .frame(width: 28)
                    .overlay(
                        Image("Tick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    )
                    .opacity(viewModel.nextButtonDisabled ? 0.5 : 1.0)
            })
            .disabled(viewModel.nextButtonDisabled)
        }
        .padding(.top, 16)
    }
    
    
    private var reviewSection: some View {
        VStack(spacing: 26) {
            RoundedRectangle(cornerRadius: 10)
                .frame(minHeight: 204)
                .overlay(
                    WebImage(url: viewModel.coverImage.isEmpty ? nil : URL(string: viewModel.coverImage), content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }, placeholder: {
                        Image("CoverPlaceholder")
                            .resizable()
                            .scaledToFill()
                    })
                        
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    ZStack(alignment: .top) {
                        Rectangle()
                            .fill(.ultraThinMaterial.opacity(0.85))
                            .preferredColorScheme(.dark)
                            .frame(height: 68)
                        secondProfileDetailView
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding(.top, 6)
                            .padding(.horizontal, 10)
                    }
                    
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    , alignment: .top
                )
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.darkGray05_mediumGray_2)
                )
            
            
            VStack(spacing: 26) {
                ForEach(viewModel.reviewPlace?.reviewQuestions ?? [] ) { reviewQuestion in
                    EmojiRatingView(title: reviewQuestion.question) { rating in
                        if let index = viewModel.questionRatings.firstIndex(where: { questionRating in
                            reviewQuestion.id == questionRating.questionID
                        }) {
                            viewModel.questionRatings.remove(at: index)
                            viewModel.questionRatings.insert(ReviewQuestionRating(questionID: reviewQuestion.id, rating: rating), at: index)
                        }
                    }
                }
            }
            
            descriptionField
//                .padding(.bottom, 10)
            
            VStack(spacing: 4) {
                attachmentImagesSection
                    .padding(.bottom, 10)
                    .photosPicker(
                        isPresented: $viewModel.showPicker,
                        selection: $viewModel.photoPickerItems,
                        maxSelectionCount: 1
                    )
                    .ignoresSafeArea()
                
                if viewModel.mediaAttachments.count < 6 {
                    customButton(icon: themeManager.currentTheme.PhotoIcon3, title: "attachment".localized(localizationManager.language))
                        .onTapGesture {
                            viewModel.showPicker.toggle()
                        }
                        .padding(.bottom, 16)
                }
            }
            
            
             
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }
    
    
//    private func photoField(icon: String) -> some View {
//        RoundedRectangle(cornerRadius: 14)
//            .fill(Color.hmDarkestGray.opacity(0.5))
//            .frame(maxWidth: .infinity)
//            .frame(height: 120)
//            .overlay(
//                RoundedRectangle(cornerRadius: 14)
//                    .stroke(lineWidth: 1)
//                    .foregroundStyle(Color.hmDarkerGray)
//                    
//            )
//            .overlay(
//                Image(icon)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 40, height: 40)
//            )
//            .onTapGesture {
//                viewModel.showPicker.toggle()
//            }
//    }
    
    
    private func customButton(icon: String, title: String) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(.hmIndigo)
            Text(title)
                .font(.custom(Constants.comicFont, size: 13))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
        }
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.black08_white05)
        )
    }
    
    
    private var attachmentImagesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
//            Text("property_pictures".localized(localizationManager.language))
//                .font(.custom(Constants.comicFont, size: 14))
//                .foregroundColor(.white.opacity(0.6))
            LazyVGrid(columns: viewModel.columns, spacing: 20, content: {
                ForEach(viewModel.mediaAttachments) { attachment in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.currentTheme.darkGray05_mediumGray_2)
                        .overlay(
                            Image(uiImage: attachment.thumbnail)
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        )
                        .overlay(
                            Button(action: {
                                
                            }, label: {
                                Image("PlayIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 52, height: 52)
                                    .opacity(attachment.type == .video(UIImage(), URL(string: "https://www.google.com")!) ? 1 : 0)
                            })
                            
                        )
                        .overlay(
                            Circle()
                                .fill(.hmIndigo)
                                .frame(width: 18)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundColor(.white)
                                        .scaledToFit()
                                        .fontWeight(.black)
                                        .frame(width: 7, height: 7)
                                        .overlay(
                                            Color.black.opacity(0.001)
                                                .frame(width: 20, height: 20)
                                                .onTapGesture {
                                                    if let index = viewModel.mediaAttachments.firstIndex(where: { $0.id == attachment.id }) {
                                                        viewModel.mediaAttachments.remove(at: index)
                                                    }
                                                }
                                        )
                                        
                                )
                                .offset(x: -5, y: 5)
                            , alignment: .topTrailing
                        )
                        .frame(height: Constants.screenWidth * 0.4)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            })
            .animation(.smooth, value: viewModel.selectedImages)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private func pickedPhoto(image: UIImage, index: Int) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.hmDarkestGray.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.hmDarkerGray)
                    
            )
            .overlay(
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            )
            .overlay(
                Circle()
                    .fill(.hmIndigo.opacity(0.8))
                    .frame(width: 24)
                    .overlay(
                        Image(systemName: "xmark")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .scaledToFit()
                            .fontWeight(.black)
                            .frame(width: 10, height: 10)
                            .onTapGesture {
                                viewModel.selectedImages.remove(at: index)
                            }
                    )
                    .offset(x: -10, y: 10)
                , alignment: .topTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    
    private var secondProfileDetailView: some View {
        HStack(alignment: .top, spacing: 15) {
            profilePic2
                .offset(y: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.reviewPlace?.businessProfileRef?.name?.capitalized ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(viewModel.addressString)
                    .lineLimit(2)
            }
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundStyle(.white.opacity(0.4))
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
    }
    
    
    private var profilePic2: some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: 46, height: 46)
            .overlay(
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 43)
            )
            .overlay(
                WebImage(url: URL(string: viewModel.profileImage), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 39, height: 39)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 39, height: 39)
                })
                
            )
    }
    
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("description".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.descriptionFieldText)
                    .scrollContentBackground(.hidden)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                    .frame(height: 200)
                    .padding(10)
                    .background(themeManager.currentTheme.darkGray05_mediumGray3)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(style: .init(lineWidth: 1))
                            .foregroundStyle(themeManager.currentTheme.mediumGray_mediumGray03)
                    )
                    .overlay(alignment: .topLeading, content: {
                        if viewModel.descriptionFieldText.isEmpty {
                            Text("description".localized(localizationManager.language))
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                                .offset(x: 16, y: 16)
                        }
                    })
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            doneButton
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var doneButton: some View {
        HStack {
            
            Spacer()
            Button(action: {
                endEditing()
            }, label: {
                Text("done".localized(localizationManager.language))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                    
            })
        }
    }
    
    
    private var checkinButton: some View {
        Button(action: {
            viewModel.showCheckinScreen()
        }, label: {
            HStack {
                Image(themeManager.currentTheme.CheckIn)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.hmIndigo)
                    .padding(.leading, 8)
                
                Text("check_in".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 13))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .padding(.trailing, 16)
            }
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray05_mediumGray_2)
            )
        })
    }
    
    
}
