//
//  IndividualSignupLogoView.swift
//  HotelMedia
//
//  Created by MAC on 06/08/24.
//

import SwiftUI
import PhotosUI
import ActivityIndicatorView

struct SUImagePickerView: UIViewControllerRepresentable {
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary  
    @Binding var image: Image?
    @Binding var isPresented: Bool
    
    func makeCoordinator() -> ImagePickerViewCoordinator {
        return ImagePickerViewCoordinator(image: $image, isPresented: $isPresented)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = sourceType
        pickerController.delegate = context.coordinator
        return pickerController
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Nothing to update here
    }

}

class ImagePickerViewCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @Binding var image: Image?
    @Binding var isPresented: Bool
    
    init(image: Binding<Image?>, isPresented: Binding<Bool>) {
        self._image = image
        self._isPresented = isPresented
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.image = Image(uiImage: image)
        }
        self.isPresented = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.isPresented = false
    }
    
}

struct IndividualSignupLogoView: View {
    
    @StateObject var viewModel: IndividualSignupLogoViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            BackgroundImageView()
                
            
            VStack( spacing: 37) {
                logo
                
                VStack(alignment: .leading, spacing: 20) {
                    title
                    logoField2
                    photoFieldSection
                    bottomButtonSection
                }
                
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
                
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
        }
//        .preferredColorScheme(.dark)
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

struct IndividualSignupLogoView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        IndividualSignupLogoView(viewModel: IndividualSignupLogoViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}

// MARK: - Components

extension IndividualSignupLogoView {
    
    private var logo: some View {
        Image("Logo")
            .resizable()
            .frame(width: 92, height: 92)
            .padding(.top, UIScreen.main.bounds.height < 670 ? 10 : 20)
    }
    
    
    private var title: some View {
        Text("individual_sign_up".localized(localizationManager.language))
            .font(.custom(Constants.comicFont, size: 20))
            .foregroundStyle(themeManager.currentTheme.label)
    }
    
    
    private var logoField2: some View {
        VStack(alignment: .leading, spacing: 6) {
            let dimension = UIScreen.main.bounds.height * 0.25
            
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
                            if let image = viewModel.croppedImage {
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
            Text("upload_from".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
            VStack(spacing: 21) {
                HStack(spacing: 21) {
                    photoField(icon: "Camera", text: "camera".localized(localizationManager.language))
                        .onTapGesture {
                            viewModel.shouldPresentCamera = true
                        }
                        .sheet(isPresented: $viewModel.shouldPresentCamera) {
                            SUImagePickerView(sourceType: self.viewModel.shouldPresentCamera ? .camera : .photoLibrary, image: self.$viewModel.image, isPresented: self.$viewModel.shouldPresentCamera)
                                .ignoresSafeArea()
                        }
                    photoField(icon: "PhotoIcon2", text: "gallery".localized(localizationManager.language))
                        .onTapGesture {
                            viewModel.shouldPresentImagePicker = true
                        }
                        .fullScreenCover(isPresented: $viewModel.shouldPresentImagePicker) {
                            SUImagePickerView(sourceType: self.viewModel.shouldPresentCamera ? .camera : .photoLibrary, image: self.$viewModel.image, isPresented: self.$viewModel.shouldPresentImagePicker)
                                .ignoresSafeArea()
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private func photoField(icon: String, text: String) -> some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(themeManager.currentTheme.darkGray05_white)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.hmDarkerGray)
                    
            )
            .overlay(
                VStack {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Text(text)
                        .font(.custom(Constants.comicFont, size: 9))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                }
            )
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
                    .opacity(viewModel.image == nil ? 0.7 : 1.0)
                    .onTapGesture {
                        if viewModel.image != nil {
                            haptics(.medium)
                            viewModel.uploadProfilePic()
                        } else {
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "please_choose_an_image_from_gallery_or_camera".localized(localizationManager.language))
                        }
                    }
            }
            
            Button(action: {
                viewModel.showNextScreen()
            }, label: {
                Capsule()
                    .fill(themeManager.currentTheme.darkGray05_white)
                    .frame(width: 50, height: 32)
                    .overlay {
                        Capsule()
                            .stroke(lineWidth: 1)
                            .fill(.hmIndigo)
                    }
                    .overlay {
                        Text("skip".localized(localizationManager.language))
                            .foregroundColor(.hmIndigo)
                            .font(.custom(Constants.comicFont, size: 12))
                    }
            })
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
}

