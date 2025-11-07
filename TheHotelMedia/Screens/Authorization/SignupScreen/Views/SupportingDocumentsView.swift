//
//  SupportingDocumentsView.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import SwiftUI
import ActivityIndicatorView

enum FieldType {
    case left
    case right
}

struct SupportingDocumentsView: View {
    // MARK: - Properties
    
    @StateObject var viewModel: SupportingDocumentsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    var body: some View {
        ZStack {
            BackgroundImageView()
            
            VStack(spacing: 37) {
                Image("Logo")
                    .resizable()
                    .frame(width: 92, height: 92)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 26) {
                    title
                    
                    VStack {
                        HStack(spacing: 21) {
                            VStack(alignment: .leading, spacing: 6) {
                                title2(string: "business_registration".localized(localizationManager.language))
                                
                                documentField(
                                    text: viewModel.leftPdfName != nil ? viewModel.leftPdfName! : "gst_certificate_incorporation_certificate".localized(localizationManager.language),
                                    image: viewModel.selectedBusinessRegistrationImage
                                )
                                .onTapGesture {
                                    viewModel.fieldType = .left
                                    viewModel.showDialogBox.toggle()
                                }
                                
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                title2(string: "address_proof".localized(localizationManager.language))
                                documentField(
                                    text: viewModel.rightPdfName != nil ? viewModel.rightPdfName! : "electricity_bill_rent_agreement".localized(localizationManager.language),
                                    image: viewModel.selectedAddressProofImage
                                )
                                .onTapGesture {
                                    viewModel.fieldType = .right
                                    viewModel.showDialogBox.toggle()
                                }
                                
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .confirmationDialog("choose_an_option".localized(localizationManager.language), isPresented: $viewModel.showDialogBox, titleVisibility: .visible) {
                            Button("photos".localized(localizationManager.language)) {
                                if viewModel.fieldType == .left {
                                    viewModel.shouldPresentImagePickerLeftField = true
                                } else {
                                    viewModel.shouldPresentImagePickerRightField = true
                                }
                                
                            }
                            Button("camera".localized(localizationManager.language)) {
                                if viewModel.fieldType == .left {
                                    viewModel.shouldPresentCameraLeftField = true
                                } else {
                                    viewModel.shouldPresentCameraRightField = true
                                }
                                
                            }
                            Button("fileManager".localized(localizationManager.language)) {
                                viewModel.showFileImporter = true
                            }
                            Button("cancel".localized(localizationManager.language), role: .cancel) {
                                viewModel.showDialogBox.toggle()
                            }
                        }
                        .sheet(isPresented: viewModel.fieldType == .left ? $viewModel.shouldPresentCameraLeftField : $viewModel.shouldPresentCameraRightField) {
                            SUImagePickerView(
                                sourceType: .camera,
                                image: viewModel.fieldType == .left ? self.$viewModel.businessRegistrationImage : self.$viewModel.addressProofImage,
                                isPresented: viewModel.fieldType == .left ? self.$viewModel.shouldPresentCameraLeftField : self.$viewModel.shouldPresentCameraRightField
                            )
                                .ignoresSafeArea()
                        }
                        .fullScreenCover(isPresented: viewModel.fieldType == .left ? $viewModel.shouldPresentImagePickerLeftField : $viewModel.shouldPresentImagePickerRightField ) {
                            SUImagePickerView(
                                sourceType: .photoLibrary,
                                image: viewModel.fieldType == .left ? self.$viewModel.businessRegistrationImage : self.$viewModel.addressProofImage,
                                isPresented: viewModel.fieldType == .left ? self.$viewModel.shouldPresentImagePickerLeftField : self.$viewModel.shouldPresentImagePickerRightField
                            )
                                .ignoresSafeArea()
                        }
                        .fileImporter(isPresented: $viewModel.showFileImporter, allowedContentTypes: [.pdf]) { result in
                            viewModel.pdfSelected(result: result)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            bottomButtonSection
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.addSubscribers()
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

struct SupportingDocumentsView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SupportingDocumentsView(viewModel: SupportingDocumentsViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components
extension SupportingDocumentsView {
    
    private var title: some View {
        Group {
            Text("supporting_documents".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 20))
                .foregroundStyle(themeManager.currentTheme.label)
        }
    }
    
    
    private func documentField(text: String, image: Image?) -> some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(themeManager.currentTheme.darkGray05_white)
            .frame(maxWidth: 200)
            .frame(height: 225)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(lineWidth: 2)
                    .foregroundStyle(Color.hmDarkerGray)
                    
            )
            .overlay(
                VStack {
                    Image("DocumentIcon2")
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    
                    Text(text)
                        .font(.custom(Constants.comicFont, size: 9))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 63)
            )
            .overlay(
                VStack {
                    if let image {
                        image
                            .resizable()
                            .scaledToFill()
                            .onTapGesture {
                                if image == viewModel.addressProofImage {
                                    viewModel.fieldType = .right
                                } else if image == viewModel.businessRegistrationImage {
                                    viewModel.fieldType = .left
                                }
                                viewModel.showDialogBox.toggle()
                            }
                            
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    private func title2(string: String) -> some View {
        Text(string)
            .font(.custom(Constants.comicFont, size: 14))
            .foregroundStyle(themeManager.currentTheme.white08_darkGray08)
    }
    
    
    private func expiryField(text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            title2(string: "date_of_expiry".localized(localizationManager.language))
            TextField(
                "",
                text: text,
                prompt: Text("date_of_expiry".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(.white.opacity(0.6))
            )
            .padding(.leading, 16)
            .frame(height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.hmDarkerGray.opacity(0.6))
            )
        }
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
                    .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                    .onTapGesture {
                        if !viewModel.nextButtonDisabled {
                            viewModel.uploadDocuments()
                            
                        } else {
                            viewModel.errorText = "please_select_documents".localized(localizationManager.language)
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: viewModel.errorText)
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
    
}
