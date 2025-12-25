//
//  RestaurantMenuView.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import SwiftUI
import SDWebImageSwiftUI
import SwiftfulRouting

struct RestaurantMenuView: View {
    @StateObject var viewModel: RestaurantMenuViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if viewModel.isLoading && viewModel.menuItems.isEmpty {
                Spacer()
                ProgressView()
                    .tint(.hmIndigo)
                Spacer()
            } else if viewModel.menuItems.isEmpty {
                emptyView
            } else {
                menuContent
            }
        }
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
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
            
            Text("Restaurant Menu")
                .font(.custom(Constants.comicFont, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
            
            Spacer()
            
            if viewModel.isAdmin {
                Button {
                    viewModel.showUploadMenu()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.hmIndigo)
                }
            } else {
                Spacer()
                    .frame(width: 24)
            }
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    private var menuContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.menuItems) { item in
                    menuItemView(item: item)
                }
            }
            .padding(16)
        }
    }
    
    private func menuItemView(item: MenuItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if item.media?.mediaType == "pdf" {
                        pdfThumbnail(url: item.media?.thumbnailUrl ?? "")
                            .frame(maxWidth: .infinity)
                    } else {
                        WebImage(url: URL(string: item.media?.sourceUrl ?? ""), content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(12)
                        }, placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.2))
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                        })
                        .frame(maxWidth: .infinity)
                    }
                }
                
                if viewModel.isAdmin {
                    Button {
                        viewModel.deleteMenuItem(id: item.id)
                    } label: {
                        Image(systemName: "trash.fill")
                            .padding(8)
                            .background(Circle().fill(.red.opacity(0.8)))
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                    }
                    .padding(8)
                }
            }
            .onTapGesture {
                viewModel.showMenuItem(item)
            }
        }
        .background(themeManager.currentTheme.darkGray05_hmIndigo)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func pdfThumbnail(url: String) -> some View {
        VStack {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text("PDF Menu")
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "menucard")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No menu items found.")
                .font(.custom(Constants.comicFont, size: 16))
                .foregroundColor(.gray)
            
            if viewModel.isAdmin {
                Button {
                    viewModel.showUploadMenu()
                } label: {
                    Text("Upload Menu")
                        .font(.custom(Constants.comicFont, size: 14))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.hmIndigo))
                        .foregroundColor(.white)
                }
            }
            Spacer()
        }
    }
}
