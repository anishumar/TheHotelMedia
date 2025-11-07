//
//  DocumentsView.swift
//  TheHotelMedia
//
//  Created by MAC on 06/12/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct DocumentsView: View {
    
    @StateObject var viewModel: DocumentsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            CustomHeaderView(title: "documents".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            HStack(spacing: 21) {
                VStack(alignment: .leading, spacing: 6) {
                    title2(string: "business_registration".localized(localizationManager.language))
                    
                    if let urlString = viewModel.documentData?.businessRegistration{
                        
                        if urlString.contains(".pdf") {
                            pdfView(urlString: urlString, documentName: "BusinessRegistration.pdf")
                        } else {
                            imageView(urlString: urlString)
                        }
                        
                    }
                    
                }
                .fullScreenCover(isPresented: $viewModel.showImagePreview, onDismiss: {
                    modifyOrientation(.portrait)
                }, content: {
                    MediaPreviewView(media: viewModel.selectedMedia, image: viewModel.selectedImage)
                        .background(BackgroundClearView())
                })
                
                VStack(alignment: .leading, spacing: 6) {
                    title2(string: "address_proof".localized(localizationManager.language))
                    
                    if let urlString = viewModel.documentData?.addressProof {
                        
                        if urlString.contains(".pdf") {
                            pdfView(urlString: urlString, documentName: "AddressProof.pdf")
                        } else {
                            imageView(urlString: urlString)
                        }
                    }
                }
                .fullScreenCover(isPresented: $viewModel.showPdfView) {
                    PDFViewer(pdfURL: $viewModel.selectedPdfURL, pdfData: $viewModel.pdfData, isRemoteURL: .constant(false), downloadURL: $viewModel.toDownloadPdfUrl)
                        .id(viewModel.selectedPdfURL)
                        .environmentObject(themeManager)
                }
            }
            .padding(.top)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
                .frame(minHeight: Constants.screenHeight)
        }
    }
}



// MARK: - Preview
struct DocumentsView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        DocumentsView(viewModel: DocumentsViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}



// MARK: - Components
extension DocumentsView {
    private func documentField(text: String, image: Image?) -> some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color.hmDarkerGray.opacity(0.6))
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
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    
                    Text(text)
                        .font(.custom(Constants.comicFont, size: 9))
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
                                
                            }
                            
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    
    private func pdfView(urlString: String, documentName: String) -> some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(themeManager.currentTheme.darkGray06_darkGray008)
            .frame(maxWidth: 200)
            .frame(height: 225)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(lineWidth: 2)
                    .foregroundStyle(Color.hmDarkerGray)
                    
            )
            .overlay(
                VStack {
                    Image(themeManager.currentTheme.DocumentIcon2)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    
                    Text(documentName)
                        .font(.custom(Constants.comicFont, size: 9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 63)
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .onTapGesture {
                if let url = URL(string: urlString) {
                    viewModel.showLoadingIndicator = true
                    Task {
                        do {
                            let data = try await PDFDownloader.shared.downloadPDF(from: urlString)
                            
                            await MainActor.run {
                                viewModel.pdfData = data
                                viewModel.toDownloadPdfUrl = url
                                viewModel.showLoadingIndicator = false
                                viewModel.showPdfView = true
                            }
                        } catch {
                            await MainActor.run {
                                viewModel.showLoadingIndicator = false
                                ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "Failed to load the PDF!")
                            }
                        }
                    }
                }
            }
    }
    
    
    private func imageView(urlString: String) -> some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(themeManager.currentTheme.darkGray06_darkGray008)
            .frame(maxWidth: 200)
            .frame(height: 225)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(lineWidth: 2)
                    .foregroundStyle(Color.hmDarkerGray)
                    
            )
            .overlay(
                VStack {
                    if let url = URL(string: urlString) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .onTapGesture {
                                viewModel.selectedMedia = .image(urlString: urlString)
                                viewModel.showImagePreview = true
                            }
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    private func title2(string: String) -> some View {
        Text(string)
            .font(.custom(Constants.comicFont, size: 14))
            .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
    }
}
