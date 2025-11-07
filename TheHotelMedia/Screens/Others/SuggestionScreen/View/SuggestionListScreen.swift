//
//  SuggestionListScreen.swift
//  TheHotelMedia
//
//  Created by MAC on 17/01/25.
//

import SwiftUI

struct SuggestionListScreen: View {
    
    @StateObject var viewModel: SuggestionScreenViewModel
    @State var isSheet: Bool = false
    @State var showing: Bool = false
    @State var offset: CGFloat = 0.0
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            if isSheet {
                VStack {
                    if showing {
                        mainComponent
                            .background(themeManager.currentTheme.backgroundColor)
                            .transition(.move(edge: .trailing))
                    }
                }
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            withAnimation(.interactiveSpring) {
                                if value.translation.width >= 0 {
                                    offset = value.translation.width
                                }
                            }
                        })
                        .onEnded { value in
                            if value.translation.width > Constants.screenWidth * 0.25 {
                                dismissScreen()
                            } else {
                                withAnimation(.interactiveSpring) {
                                    offset = 0
                                }
                            }
                        }
                )
                .onAppear {
                    withAnimation(.smooth(duration: 0.2)) {
                        showing = true
                    }
                }
            } else {
                mainComponent
                    .background(themeManager.currentTheme.backgroundColor)
            }
        }
        
    }
}


// MARK: - Functions
extension SuggestionListScreen {
    func dismissScreen() {
        withAnimation(.smooth(duration: 0.2)) {
            showing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}


// MARK: - Main Component
extension SuggestionListScreen {
    private var mainComponent: some View {
        VStack {
            header
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(viewModel.suggestionsData) { suggestion in
                        let index = viewModel.suggestionsData.firstIndex(where: {$0.id == suggestion.id })
                        
                        SuggestionProfile(viewModel: SuggestionProfileViewModel(suggestion: suggestion), onEllipsisButtonPressed: { profileID in
                            
                            if let index {
                                viewModel.reportID = profileID
                                viewModel.reportType = "user"
                                viewModel.profileOptionYoffset = viewModel.suggestionListYOffset[index]
                                viewModel.showProfileOptions.toggle()
                            }
                            
                        })
                            .onTapGesture {
                                viewModel.showUserProfileScreen(id: suggestion.userID ?? "")
                            }
                            .overlay(
                                GeometryReader { geo in
                                    Color.black.opacity(0.0001)
                                        .preference(key: VisibleRectanglePreferenceKey.self, value: geo.frame(in: .global))
                                        .allowsHitTesting(false)
                                }
                            )
                            .onPreferenceChange(VisibleRectanglePreferenceKey.self) { frame in
                                if let index {
                                    viewModel.suggestionListYOffset[index] = frame.minY
                                }
                            }
                            .onAppear {
                                if let lastProfile = viewModel.suggestionsData.last {
                                    if lastProfile.id == suggestion.id {
                                        viewModel.suggestionsPageNo += 1
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .overlay {
            ZStack(alignment: .topTrailing) {
                if viewModel.showProfileOptions {
                    themeManager.currentTheme.black05_white05
                        .onTapGesture {
                            viewModel.showProfileOptions.toggle()
                        }
                    VStack(spacing: 6) {
                        capsuleButtonView(title: "report".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showReportScreen = true
                                viewModel.showProfileOptions.toggle()
                            }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                    )
                    .offset(x: -16, y: viewModel.profileOptionYoffset - UIApplication.topSafeAreaHeightTHM + 40)
                }
            }
            .sheet(isPresented: $viewModel.showReportScreen, content: {
                ReportView(viewModel: ReportViewModel(reportID: viewModel.reportID, reportType: viewModel.reportType, onReport: { message in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                        ErrorModalManager.showErrorModal(router: viewModel.router, errorText: message)
                    }
                }))
                .environmentObject(themeManager)
                .id(viewModel.reportID)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.fraction(Constants.getReportSheetHeight())])
            })
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}


// MARK: - Components
extension SuggestionListScreen {
    private func capsuleButtonView(title: String) -> some View {
        Text(title)
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundColor(themeManager.currentTheme.label)
            .frame(width: 74, height: 26, alignment: .center)
            .background(
                ZStack {
                    Capsule()
                        .fill(themeManager.currentTheme.darkGray05_white)
                    Capsule()
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                }
            )
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
                    if isSheet {
                        dismissScreen()
                    } else {
                        viewModel.dismissScreen()
                    }
                }
            
            Text("suggested_for_you".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
    }
}
