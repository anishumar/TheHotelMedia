//
//  RestaurantMenuViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import SwiftUI
import SDWebImageSwiftUI
import Combine
import SwiftfulRouting

class RestaurantMenuViewModel: ObservableObject {
    @Published var menuItems: [MenuItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let dataManager = RestaurantMenuDataManager()
    let businessProfileID: String
    let isAdmin: Bool
    var router: AnyRouter
    
    init(router: AnyRouter, businessProfileID: String, isAdmin: Bool) {
        self.router = router
        self.businessProfileID = businessProfileID
        self.isAdmin = isAdmin
        fetchMenu()
    }
    
    func fetchMenu() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await dataManager.getRestaurantMenu(businessProfileID: businessProfileID)
                await MainActor.run {
                    self.isLoading = false
                    if response.status {
                        self.menuItems = response.data ?? []
                    } else {
                        self.errorMessage = response.message
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteMenuItem(id: String) {
        Task {
            do {
                let response = try await dataManager.deleteRestaurantMenuItem(id: id)
                await MainActor.run {
                    if response.status {
                        self.menuItems.removeAll(where: { $0.id == id })
                    } else {
                        self.errorMessage = response.message
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func showMenuItem(_ item: MenuItem) {
        if item.media?.mediaType == "pdf", let sourceUrl = item.media?.sourceUrl, let url = URL(string: sourceUrl) {
            router.showScreen(.fullScreenCover) { router in
                PDFViewer(pdfURL: .constant(url), pdfData: .constant(Data()), isRemoteURL: .constant(true), downloadURL: .constant(url), pdfTitle: "Menu PDF")
                    .environmentObject(ThemeManager.shared)
            }
        } else if let sourceUrl = item.media?.sourceUrl, let url = URL(string: sourceUrl) {
            router.showScreen(.fullScreenCover) { router in
                ZStack {
                    Color.black.ignoresSafeArea()
                    WebImage(url: url)
                        .resizable()
                        .scaledToFit()
                    
                    VStack {
                        HStack {
                            Button {
                                router.dismissScreen()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    func dismiss() {
        router.dismissScreen()
    }
    
    func showUploadMenu() {
        router.showScreen(.push) { router in
            UploadMenuView(viewModel: UploadMenuViewModel(router: router, onUploadSuccess: { [weak self] in
                self?.fetchMenu()
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
}
