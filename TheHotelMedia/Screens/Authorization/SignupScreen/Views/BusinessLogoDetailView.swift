//
//  BusinessLogoDetailView.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI
import ActivityIndicatorView

struct BusinessLogoDetailView: View {
    
    @StateObject var viewModel: BusinessLogoDetailViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            BackgroundImageView()
            
            ScrollView (.vertical, showsIndicators: false){
                VStack( spacing: 37) {
                    logo
                    
                    VStack(alignment: .leading, spacing: 20) {
                        title
                            .fullScreenCover(isPresented: $viewModel.shouldOpenImagePicker){
                                PHPickerSwiftUI(config: viewModel.pickerConfig) { results in
                                    viewModel.handlePickedImages(results)
                                }
                                .ignoresSafeArea()
                            }
                        logoField3
                            .fullScreenCover(isPresented: $viewModel.shouldOpenLogoImagePicker){
                                PHPickerSwiftUI(config: viewModel.logoPickerConfig) { results in
                                    viewModel.handlePickedLogoImage(results)
                                }
                                .ignoresSafeArea()
                            }
                            .onTapGesture {
                                viewModel.shouldOpenLogoImagePicker = true
//                                viewModel.showLogoPickerOptions = true
                            }
                        propertyImagesSection
                            .fullScreenCover(isPresented: $viewModel.shouldOpenLogoCameraPicker) {
                                SUImagePickerView(sourceType: .camera, image: self.$viewModel.logoCameraImage, isPresented: self.$viewModel.shouldOpenLogoCameraPicker)
                                    .ignoresSafeArea()
                            }
                            .confirmationDialog("choose_an_option".localized(localizationManager.language), isPresented: $viewModel.showLogoPickerOptions, titleVisibility: .visible) {
                                Button("photos".localized(localizationManager.language)) {
                                    viewModel.shouldOpenLogoImagePicker = true
                                    
                                }
                                Button("camera".localized(localizationManager.language)) {
                                    viewModel.shouldOpenLogoCameraPicker = true
                                    
                                }
                                
                                Button("cancel".localized(localizationManager.language), role: .cancel) {
                                    viewModel.showLogoPickerOptions.toggle()
                                }
                            }
                        
                        
                        bottomButtonSection
                            .padding(.top, UIScreen.main.bounds.height < 670 ? 20 : 30)
                            .fullScreenCover(isPresented: $viewModel.shouldOpenCameraPicker) {
                                SUImagePickerView(sourceType: .camera, image: self.$viewModel.cameraImage, isPresented: self.$viewModel.shouldOpenCameraPicker)
                                    .ignoresSafeArea()
                            }
                            .confirmationDialog("choose_an_option".localized(localizationManager.language), isPresented: $viewModel.showPickerOptions, titleVisibility: .visible) {
                                Button("photos".localized(localizationManager.language)) {
                                    viewModel.shouldOpenImagePicker = true
                                    
                                }
                                Button("camera".localized(localizationManager.language)) {
                                    viewModel.shouldOpenCameraPicker = true
                                    
                                }
                                
                                Button("cancel".localized(localizationManager.language), role: .cancel) {
                                    viewModel.showPickerOptions.toggle()
                                }
                            }
                        
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .clipped()
            
            
            
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.addSubscribers()
            if viewModel.wentToNextScreen {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    viewModel.wentToNextScreen = false
                }
            }
        }
        .onDisappear {
            viewModel.cancelSubcriptions()
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}


// MARK: - Preview

struct BusinessLogoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        BusinessLogoDetailView(viewModel: BusinessLogoDetailViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension BusinessLogoDetailView {
    
    private var propertyImagesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("property_pictures".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            LazyVGrid(columns: viewModel.columns,spacing: 20, content: {
                ForEach(0..<viewModel.images.count, id: \.self) { index in
                    pickedPhoto(image: viewModel.images[index], index: index)
                }
                if viewModel.images.count < 10 {
                    photoField(icon: "PlusBold")
                }
            })
            .animation(.smooth, value: viewModel.images)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var logo: some View {
        Image("Logo")
            .resizable()
            .frame(width: 92, height: 92)
            .padding(.top, UIScreen.main.bounds.height < 670 ? 10 : 20)
    }
    
    
    private var title: some View {
        Text("business_type".localized(localizationManager.language))
            .font(.custom(Constants.comicFont, size: 20))
            .foregroundStyle(themeManager.currentTheme.label)
    }
    
    
    private var logoField2: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("hotel_logo".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(Color.white.opacity(0.6))
            RoundedRectangle(cornerRadius: 30)
                .fill(.hmDarkestGray.opacity(0.5))
                .frame(height: UIScreen.main.bounds.height * 0.25)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                )
                .overlay(
                    Image("PhotoIcon2")
                        .resizable()
                        .frame(width: 60, height: 60)
                )
        }
    }
    
    
    private var logoField3: some View {
        VStack(alignment: .leading, spacing: 6) {
            let dimension = UIScreen.main.bounds.height * 0.25
            
            Text("hotel_logo".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            HStack {
                RoundedRectangle(cornerRadius: dimension / 2)
                    .fill(themeManager.currentTheme.darkGray05_white)
                    .frame(width: dimension, height: dimension)
                    .overlay(
                        RoundedRectangle(cornerRadius: dimension / 2)
                            .stroke(lineWidth: 1)
                            .fill(.hmDarkerGray)
                    )
                    .overlay(
                        VStack {
                            if let image = viewModel.selectedLogoImage {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            } else {
                                Image("PhotoIcon2")
                                    .resizable()
                                    .renderingMode(.template)
                                    .font(.system(size: 60))
                                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
                    )
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    
    private var photoFieldSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("property_pictures".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(Color.white.opacity(0.6))
            VStack(spacing: 21) {
                HStack(spacing: 21) {
                    photoField(icon: "PhotoIcon2")
                    photoField(icon: "PlusBold")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private func photoField(icon: String) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(themeManager.currentTheme.darkGray05_white)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.hmDarkerGray)
                    
            )
            .overlay(
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            )
            .onTapGesture {
                viewModel.pickerConfig.filter = .any(of: [.images])
                viewModel.pickerConfig.selectionLimit = min(6, 10 - viewModel.images.count)
                viewModel.pickerConfig.preferredAssetRepresentationMode = .current
//                viewModel.shouldOpenImagePicker = true
                viewModel.showPickerOptions = true
            }
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
                                viewModel.images.remove(at: index)
                            }
                    )
                    .offset(x: -10, y: 10)
                , alignment: .topTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    
    private var bottomButtonSection: some View {
        ZStack {
            VStack {
                Button(action: {
                    viewModel.dismissScreen()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo04_hmIndigo08)
                            .frame(width: 48)
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .tint(.white)
                    }
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            
            VStack {
                CircleProgressButton(progress: .constant(100))
                    .opacity(viewModel.nextButtonDisabled ? 0.5 : 1.0)
                    .onTapGesture {
                        if !viewModel.nextButtonDisabled {
                            viewModel.uploadBusinessProfilePic()
                        } else {
                            if viewModel.selectedLogoImage == nil {
                                ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "Please choose a logo image from gallery.".localized(localizationManager.language))
                            } else {
                                ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "please_choose_an_image_from_gallery_or_camera".localized(localizationManager.language))
                            }
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
}
