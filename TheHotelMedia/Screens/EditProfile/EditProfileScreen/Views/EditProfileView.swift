//
//  EditProfileView.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct EditProfileView: View {
    
    @StateObject var viewModel: EditProfileViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("locationString") var locationString: String = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                VStack(spacing: 40) {
                    if isIndividual {
                        individualProfileImage
                    } else {
                        businessProfileImage
                    }
                    
                    VStack( alignment: .leading, spacing: 6) {
                        Text("about_me".localized(localizationManager.language))
                            .foregroundColor(themeManager.currentTheme.label)
                        option(
                            title: "name".localized(localizationManager.language),
                            value: isIndividual ? viewModel.profileData.name ?? "" : viewModel.profileData.businessProfileRef?.name ?? "",
                            icon: "PersonIcon2"
                        )
                        .onTapGesture {
                            viewModel.showEditNameScreen()
                        }
                        option(
                            title: "email".localized(localizationManager.language),
                            value: viewModel.profileData.email ?? "",
                            icon: "MessageIcon2"
                        )
                        .onTapGesture {
                            viewModel.showEditEmailScreen()
                        }
                        
                        let phoneNumber = isIndividual ? viewModel.profileData.phoneNumber : viewModel.profileData.businessProfileRef?.phoneNumber
                        if let phoneNumber, !phoneNumber.isEmpty {
                            option(
                                title: "contact_number".localized(localizationManager.language),
                                value: isIndividual ? "\(viewModel.profileData.dialCode ?? "") \(viewModel.profileData.phoneNumber ?? "")" : "\(viewModel.profileData.businessProfileRef?.dialCode ?? "") \(viewModel.profileData.businessProfileRef?.phoneNumber ?? "")"
                                ,
                                icon: "PhoneIcon2"
                            )
                            .onTapGesture {
                                viewModel.showEditContactScreen()
                            }
                        }
                        
                        if !isIndividual {
                            option(
                                title: "category".localized(localizationManager.language),
                                value: viewModel.businessType,
                                icon: "CategoryIcon"
                            )
                            .onTapGesture {
                                viewModel.showEditCategoryScreen()
                            }
                        }
                        
                        option(
                            title: "password".localized(localizationManager.language),
                            value: "Change Password",
                            icon: "LockIcon2",
                            valueTextColor: .hmIndigo
                        )
                        .onTapGesture {
                            viewModel.showPasswordView()
                        }
                        .fullScreenCover(isPresented: $viewModel.showCropView ) {
                            CropView(crop: .square, image: viewModel.selectedImage, hideDismissButton: false) { returnedImage, isCropped in
                                guard isCropped else { return }
                                if let returnedImage {
                                    viewModel.croppedImage = returnedImage
                                }
                            }
                            .environmentObject(ThemeManager.shared)
                        }
                        
                        
                        option(
                            title: "bio".localized(localizationManager.language),
                            value: isIndividual ? viewModel.profileData.bio ?? "" : viewModel.profileData.businessProfileRef?.bio ?? "",
                            icon: "AboutUs"
                        )
                        .onTapGesture {
                            viewModel.showEditBioScreen()
                        }
                        .confirmationDialog("choose_an_option".localized(localizationManager.language), isPresented: $viewModel.showOptionDialog, titleVisibility: .visible) {
                            Button("photos".localized(localizationManager.language)) {
                                viewModel.showImagePicker.toggle()
                                
                            }
                            Button("camera".localized(localizationManager.language)) {
                                viewModel.showCameraPicker.toggle()
                                
                            }
                            Button("fileManager".localized(localizationManager.language)) {
                                viewModel.showFileImporter = true
                            }
                            
                            Button("cancel".localized(localizationManager.language), role: .cancel) {
                                viewModel.showOptionDialog.toggle()
                            }
                        }
                        .fullScreenCover(isPresented: $viewModel.showCameraPicker) {
                            SUImagePickerView(sourceType: .camera, image: $viewModel.selectedImage, isPresented: $viewModel.showCameraPicker)
                        }
                        .fileImporter(isPresented: $viewModel.showFileImporter, allowedContentTypes: [.jpeg]) { result in
                            viewModel.imageSelectedFromFileImporter(result: result)
                        }
                        .sheet(isPresented: $viewModel.showImagePicker) {
                            SUImagePickerView(sourceType: .photoLibrary, image: $viewModel.selectedImage, isPresented: $viewModel.showImagePicker)
                        }
                        
                        if !isIndividual {
                            amenitiesOption
                                .padding(.top, 12)
                                .onTapGesture {
                                    viewModel.showAmenitiesQuestionsScreen()
                                }
                        }
                        
                        if isIndividual {
                            option(title: "billing_address".localized(localizationManager.language), value: locationString.isEmpty ? "billing_address".localized(localizationManager.language) : locationString, icon: "PinWithMap")
                                .onTapGesture {
                                    viewModel.showEditBillingAddressScreen()
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .font(.custom(Constants.comicFont, size: 14))
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.top, 50)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .clipped()
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay(
            header
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .background(themeManager.currentTheme.backgroundColor)
            , alignment: .top
        )
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}


// MARK: - Preview

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditProfileView(viewModel: EditProfileViewModel(router: router, profileData: ProfileData(posts: nil, follower: nil, following: nil, profileCompleted: nil, id: nil, bio: nil, accountType: nil, type: nil, booking: nil, isVerified: nil, isApproved: nil, isActivated: nil, isDeleted: nil, hasProfilePicture: nil, acceptedTerms: nil, email: nil, username: nil, name: nil, dialCode: nil, role: nil, phoneNumber: nil, businessProfileID: nil, businessProfileRef: nil, profilePic: nil, reviewQuestions: [], privateAccount: nil, notificationEnabled: nil, inMyFollowing: nil, isConnected: nil, isRequested: nil, address: nil, weather: nil)))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension EditProfileView {
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
            
            Text("edit_profile".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
        }
        .padding(.top, 16)
    }
    
    
    private var businessProfileImage: some View {
        ZStack {
            Circle()
                .fill(.hmPeach)
                .frame(width: 140)
            
            Circle()
                .fill(themeManager.currentTheme.backgroundColor)
                .frame(width: 130)
            
            WebImage(url: URL(string: viewModel.profilePic), content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Image(themeManager.currentTheme.EditIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .onTapGesture {
                                viewModel.showOptionDialog.toggle()
                            }
                        , alignment: .bottomTrailing
                    )
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Image(themeManager.currentTheme.EditIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .onTapGesture {
                                viewModel.showOptionDialog.toggle()
                            }
                        , alignment: .bottomTrailing
                    )
            })
        }
    }
    
    
    private var individualProfileImage: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.backgroundColor)
                .frame(width: 140)
            
            WebImage(url: URL(string: viewModel.profilePic), content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .overlay(
                        Image("EditIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .onTapGesture {
                                viewModel.showOptionDialog.toggle()
                            }
                            .offset(x: -5, y: -5)
                        , alignment: .bottomTrailing
                    )
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .overlay(
                        Image("EditIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .onTapGesture {
                                viewModel.showOptionDialog.toggle()
                            }
                        , alignment: .bottomTrailing
                    )
            })
        }
    }
    
    
    private func option(title: String, value: String, icon: String, valueTextColor: Color? = nil) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 22))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .scaledToFit()
                .frame(width: 22, height: 22)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .background(themeManager.currentTheme.backgroundColor)
            Text(value)
                .lineLimit(1)
                .foregroundColor(valueTextColor ?? themeManager.currentTheme.white06_darkGray06)
            Image(themeManager.currentTheme.Chevron_right)
                .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
    }
    
    
    private var amenitiesOption: some View {
        HStack(alignment: .top) {
            Image("Amenity")
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 22))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .scaledToFit()
                .frame(width: 22, height: 22)
            Text("amenities".localized(localizationManager.language))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .background(themeManager.currentTheme.backgroundColor)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(viewModel.amenitiesRef) { amenity in
                    Text(amenity.name ?? "")
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                }
            }
            
            Image(themeManager.currentTheme.Chevron_right)
                .padding(.leading, 8)
                .padding(.top, 4)
            
        }
        .frame(maxWidth: .infinity)
    }
}
