//
//  EditPostScreen.swift
//  TheHotelMedia
//
//  Created by MAC on 05/03/25.
//

import SwiftUI
import Flow
import SwiftfulRouting
import PhotosUI
import SDWebImageSwiftUI
import Lottie
import Combine

struct EditPostScreen: View {
    
    @StateObject var viewModel: EditPostViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @State var showTagScreen: Bool = false
    @State var showFeelingScreen: Bool = false
    
    @AppStorage("name") var name: String = ""
    @AppStorage("profilePic") var profilePic: String = ""
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    profileHeader
                    VStack {
                        descriptionField
                            .frame(minHeight: Constants.screenHeight * 0.22)
                            .padding(.horizontal, 8)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    doneButton
                                }
                            }
                        
                        imagesGrid
                        tagsSection
                            
                    }
                    .frame(minHeight: Constants.screenHeight * 0.22)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray06_darkGray008)
                    )
                    
                    VStack {
                        customButton(icon: themeManager.currentTheme.PhotoIcon3, title: "photo_video".localized(localizationManager.language))
                            .onTapGesture {
                                if viewModel.mediaAttachments.count < 10 {
                                    if viewModel.hasSelectedSomeMedia {
                                        viewModel.showBottomAlert(message: "please_wait_while_your_selected_video_is_being_processed...".localized(localizationManager.language))
                                    } else {
                                        viewModel.photoPickerItem = nil
                                        viewModel.photoPickerItems.removeAll()
                                        viewModel.showPicker.toggle()
                                    }
                                } else {
                                    ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "you_cannot_select_more_than_10_items".localized(localizationManager.language))
                                }
                            }
                            .photosPicker(
                                isPresented: $viewModel.showPicker,
                                selection: $viewModel.photoPickerItems,
                                maxSelectionCount: 1
                            )
                            .ignoresSafeArea()
                            
                        customButton(icon: themeManager.currentTheme.TagIcon, title: "tag_people".localized(localizationManager.language))
                            .onTapGesture {
                                showTagScreen.toggle()
                            }
                            .fullScreenCover(isPresented: $showTagScreen) {
                                TagPeopleView(
                                    viewModel: TagPeopleViewModel(router: viewModel.router, selectedProfiles: viewModel.tagProfiles),
                                    selectedProfiles: $viewModel.tagProfiles
                                )
                                .environmentObject(localizationManager)
                            }
                        
                        customButton(icon: themeManager.currentTheme.HappyIcon, title: "feeling_activity".localized(localizationManager.language))
                            .onTapGesture {
                                showFeelingScreen.toggle()
                            }
                            .fullScreenCover(isPresented: $showFeelingScreen) {
                                AddFeelingView(viewModel: AddFeelingViewModel(router: viewModel.router, selectedFeeling: viewModel.feeling), selectedFeeling: $viewModel.feeling)
                                    .environmentObject(localizationManager)
                            }
                        
                        customButton(icon: themeManager.currentTheme.CameraIcon2, title: "camera".localized(localizationManager.language))
                            .fullScreenCover(isPresented: $viewModel.showCameraPicker) {
                                SUImagePickerView(sourceType: .camera, image: $viewModel.selectedCameraImage, isPresented: $viewModel.showCameraPicker)
                            }
                            .onTapGesture {
                                viewModel.showCameraPicker.toggle()
                            }
                        
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray06_darkGray008)
                    )
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 54)
            }
            .clipped()
            .overlay(
                header
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                    .background(themeManager.currentTheme.backgroundColor)
                
                , alignment: .top
            )
        }
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
            CustomProgressView(showIndicator: $viewModel.hasSelectedSomeMedia)
        }
    }
}

// MARK: - Components
extension EditPostScreen {
    
    private var tagsSection: some View {
        HStack(alignment: .top) {
            if !viewModel.tagProfiles.isEmpty {
                Text("tags:".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 12))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }
            
            HFlow {
                ForEach(viewModel.tagProfiles) { profile in
                    HStack {
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
                            )
                            .onTapGesture {
                                viewModel.tagProfiles.removeAll(where: {$0.id == profile.id})
                            }
                        Text(profile.username ?? "")
                            .font(.custom(Constants.comicFont, size: 11))
                            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        
                    }
                    .padding(.horizontal, 6.5)
                    .padding(.vertical, 4.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6.5)
                            .fill(themeManager.currentTheme.mediumGray_mediumGray03)
                    )
                }
            }
            .padding(.leading, 8)
            .frame(width: UIScreen.main.bounds.width * 0.7, alignment: .leading)
        }
        .padding(.leading, 8)
        .padding(.bottom, 8)
    }
    
    
    private func customButton(icon: String? = nil, systemIcon: String? = nil, title: String) -> some View {
        HStack {
            if let icon {
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.hmIndigo)
                    .padding(.leading, 8)
            } else if let systemIcon {
                Image(systemName: systemIcon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.hmIndigo)
                    .padding(.leading, 12)
            }
            Text(title)
                .font(.custom(Constants.comicFont, size: 13))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .padding(.trailing, 16)
        }
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.black09_white)
        )
    }
    
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            ZStack(alignment: .topLeading) {
                if viewModel.descriptionFieldText.isEmpty {
                    Text("what's_in_your_mind".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                        .offset(x: 10, y: 10)
                }
                
                TextEditor(text: $viewModel.descriptionFieldText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundStyle(themeManager.currentTheme.label)
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
            
            Text("edit_post".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                endEditing()
                viewModel.updatePost()
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
                    .opacity(viewModel.descriptionFieldText.isEmpty && viewModel.mediaAttachments.isEmpty ? 0.5 : 1.0)
            })
            .disabled(viewModel.descriptionFieldText.isEmpty && viewModel.mediaAttachments.isEmpty)
        }
        .padding(.top, 16)
    }
    
    
    private var imagesGrid: some View {
        LazyVGrid(columns: viewModel.imagesColumns, content: {
            ForEach(Array(viewModel.mediaAttachments.enumerated()), id: \.element.id) { index, attachment in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.hmDarkestGray.opacity(0.6))
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
                                                viewModel.removeMediaAttachment(at: index)
                                            }
                                    )
                                    
                            )
                            .offset(x: -5, y: 5)
                        , alignment: .topTrailing
                    )
                    .frame(height: (UIScreen.main.bounds.width / 2) - 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        })
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    
    private var profileHeader: some View {
        HStack (spacing: 15) {
            WebImage(url: URL(string: profilePic), content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38)
                    .clipShape(Circle())
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38)
                    .clipShape(Circle())
            })
            
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
                
                if let feeling = viewModel.feeling {
                    HStack(spacing: 2) {
                        Image("Smily")
                        Text(feeling.title)
                            .font(.custom(Constants.comicFont, size: 11))
                            .foregroundColor(.hmIndigo)
                    }
                    .onTapGesture {
                        showFeelingScreen.toggle()
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.darkGray06_darkGray008)
        )
    }
}

