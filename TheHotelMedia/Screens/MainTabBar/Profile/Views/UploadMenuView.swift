//
//  UploadMenuView.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import SwiftUI
import PhotosUI

struct UploadMenuView: View {
    @StateObject var viewModel: UploadMenuViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showFilePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(spacing: 24) {
                    uploadOptions
                    
                    if !viewModel.selectedFiles.isEmpty {
                        selectedFilesList
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .padding()
                    }
                    
                    uploadButton
                }
                .padding()
            }
        }
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .onChange(of: selectedItems) { newValue in
            Task {
                var urls: [URL] = []
                for item in newValue {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                        try? data.write(to: tempURL)
                        urls.append(tempURL)
                    }
                }
                await MainActor.run {
                    viewModel.addFiles(urls: urls)
                    selectedItems = []
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                viewModel.addFiles(urls: urls)
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button {
                viewModel.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.label)
            }
            
            Spacer()
            
            Text("Upload Menu")
                .font(.custom(Constants.comicFont, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
            
            Spacer()
            
            Spacer()
                .frame(width: 24)
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    private var uploadOptions: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $selectedItems, matching: .images, photoLibrary: .shared()) {
                VStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 30))
                    Text("Images")
                        .font(.custom(Constants.comicFont, size: 14))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(themeManager.currentTheme.darkGray05_hmIndigo)
                .cornerRadius(12)
                .foregroundColor(.hmIndigo)
            }
            
            Button {
                showFilePicker = true
            } label: {
                VStack {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 30))
                    Text("PDF")
                        .font(.custom(Constants.comicFont, size: 14))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(themeManager.currentTheme.darkGray05_hmIndigo)
                .cornerRadius(12)
                .foregroundColor(.hmIndigo)
            }
        }
    }
    
    private var selectedFilesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Files (\(viewModel.selectedFiles.count))")
                .font(.custom(Constants.comicFont, size: 16))
                .foregroundColor(themeManager.currentTheme.label)
            
            ForEach(viewModel.selectedFiles, id: \.self) { url in
                HStack {
                    Image(systemName: url.pathExtension.lowercased() == "pdf" ? "doc.pdf" : "photo")
                        .foregroundColor(.hmIndigo)
                    Text(url.lastPathComponent)
                        .font(.system(size: 14))
                        .lineLimit(1)
                    Spacer()
                    Button {
                        viewModel.selectedFiles.removeAll(where: { $0 == url })
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(themeManager.currentTheme.darkGray05_hmIndigo.opacity(0.5))
                .cornerRadius(8)
            }
        }
    }
    
    private var uploadButton: some View {
        Button {
            viewModel.uploadMenu()
        } label: {
            if viewModel.isUploading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Start Upload")
                    .font(.custom(Constants.comicFont, size: 16))
                    .bold()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Capsule().fill(viewModel.selectedFiles.isEmpty ? Color.gray : Color.hmIndigo))
        .foregroundColor(.white)
        .disabled(viewModel.selectedFiles.isEmpty || viewModel.isUploading)
        .padding(.top, 16)
    }
}
