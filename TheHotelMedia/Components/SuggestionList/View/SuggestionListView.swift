//
//  SuggestionListView.swift
//  TheHotelMedia
//
//  Created by MAC on 15/01/25.
//

import SwiftUI

struct SuggestionListView: View {
    
    
    @StateObject var viewModel: SuggestionListViewModel
    var onPressedProfile: ((String) -> Void)? = nil
    var onPressedCross: ((String) -> Void)? = nil
    var onViewAll: (() -> Void)? = nil
    @State var refresh: Bool = false
    @State var suggestionData: [ReviewedBusinessProfileRef] = []
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            if !suggestionData.isEmpty {
                VStack(spacing: 10) {
                    HStack {
                        Text("Suggested for You")
                            .withComicFont(14, color: themeManager.currentTheme.label)
                        Spacer()
                        Text("View all")
                            .withComicFont(12, color: themeManager.currentTheme.label)
                            .onTapGesture {
                                onViewAll?()
                            }
                    }
                    .padding(.horizontal, 12)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(suggestionData) { suggestion in
                                SuggestionCard(suggestion: suggestion) { id in
                                    onPressedProfile?(id)
                                } onPressedCross: { id in
                                    if let index = suggestionData.firstIndex(where: {$0.id == id}) {
                                        suggestionData.remove(at: index)
                                    }
                                    onPressedCross?(id)
    //                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    //                                    refresh.toggle()
    //                                    if !refresh {
    //                                        refresh.toggle()
    //                                    }
    //                                }
                                }
    //                                suggestionCardView(suggestion: suggestion)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Constants.screenHeight * 0.25)
                .scaleEffect(y: suggestionData.isEmpty ? 0 : 1.0)
            }
        }
//        .id(suggestionData)
        .onReceive(viewModel.$postData, perform: { newValue in
            suggestionData = newValue.data ?? []
        })
        .onAppear {
            suggestionData = viewModel.postData.data ?? []
        }
    }
        
}

#Preview {
    SuggestionListView(viewModel: SuggestionListViewModel(postData: DummyData.post))
}


// MARK: - Components
extension SuggestionListView {
    private func suggestionCardView(suggestion: ReviewedBusinessProfileRef) -> some View {
        VStack(spacing: 10) {
            BusinessProfilePicView(stringURL: suggestion.profilePic?.medium ?? "", dimension: 72, border: 6)
            VStack(spacing: 2) {
                Text(suggestion.name ?? "")
                    .withComicFont(14, color: .white)
                    .lineLimit(1)
                
                BusinessTypeAndRatingView(rating: suggestion.rating ?? 0, type: suggestion.businessTypeRef?.name ?? "")
                    .withComicFont(11, color: .white.opacity(0.4))
                
                Text("\(suggestion.address?.city ?? ""), \(suggestion.address?.state ?? ""), \(suggestion.address?.country ?? "") ")
                    .withComicFont(11, color: .white.opacity(0.4))
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
        .frame(width: Constants.screenWidth * 0.65)
        .background(
            CustomShape4()
                .fill(.black.opacity(0.9))
                .drawingGroup()
                
        )
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.hmIndigo.opacity(0.5))
                .drawingGroup()
        )
        .onTapGesture {
            onPressedProfile?(suggestion.userID ?? "")
        }
        .overlay(
            crossButton(suggestionID: suggestion.id ?? "")
                .drawingGroup()
            , alignment: .topTrailing
        )
    }
    
    private func crossButton(suggestionID: String) -> some View {
        Button(action: {
//            if let index = postData.data?.firstIndex(where: {$0.id == suggestionID}) {
//                postData.data?.remove(at: index)
//            }
            onPressedCross?(suggestionID)
            refresh.toggle()
        }, label: {
            Circle()
                .fill(.black.opacity(0.9))
                .frame(width: 28)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                )
        })
        .padding(.top, 8)
        .padding(.trailing, 8)
    }
}
