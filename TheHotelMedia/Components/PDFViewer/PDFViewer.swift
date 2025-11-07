//
//  PDFViewer.swift
//  TheHotelMedia
//
//  Created by MAC on 28/11/24.
//

import SwiftUI

struct PDFViewer: View {
    
    @Binding var pdfURL: URL
    @Binding var pdfData: Data
    @Binding var isRemoteURL: Bool
    @Binding var downloadURL: URL?
    var pdfTitle: String = "PDF Viewer"
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel = PDFViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            headerView
            if isRemoteURL {
                PDFKitViewRepresentable(url: $pdfURL)
            } else {
                PDFKitViewFromData(pdfData: $pdfData)
            }
        }
        
        
//        PDFKitViewRepresentable(url: $pdfURL)
//            .overlay(alignment: .top) {
//                headerView
//            }
    }
}

#Preview {
//    PDFViewer(pdfURL: .constant(URL(string: "")!))
    PDFViewer(pdfURL: .constant(URL(string: "")!), pdfData: .constant(Data()), isRemoteURL: .constant(true), downloadURL: .constant(nil))
}

// MARK: - Components
extension PDFViewer {
    private var headerView: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    dismiss()
                }
            
            Text(pdfTitle)
                .font(.custom(Constants.comicBold, size: 18))
                .lineLimit(2)
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            if let downloadURL {
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 40)
                    .overlay {
                        Image(systemName: "square.and.arrow.up" )
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.label)
                    }
                    .overlay(content: {
                        CustomProgressView(showIndicator: $viewModel.downloadingMedia, dimension: 40, lineWidth: 2, backgroundColor: .clear, type: "growingArc")
                            .allowsHitTesting(false)
                    })
                    .onTapGesture {
                        viewModel.downloadPDF(url: downloadURL, pdfTitle: pdfTitle)
                    }
                    .sheet(isPresented: $viewModel.isSharePresented, content: {
                        ActivityViewController(activityItems: [viewModel.shareURL])
                            .id(viewModel.shareURL)
                            .presentationDetents([.medium, .large])
                    })
            }
            
            
        }
        .padding(.top, 4)
        .padding(.horizontal, 12)
        .background(themeManager.currentTheme.backgroundColor)
    }
}
