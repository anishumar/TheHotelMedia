//
//  IntroSlideView.swift
//  HotelMedia
//
//  Created by MAC on 26/07/24.
//

import SwiftUI
import SwiftfulRouting

struct OnboardingView: View {
    // MARK: - Properties
    
    
    @StateObject var viewModel: OnboardingViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundImageView
            
            VStack {
                Spacer()
                headlineTextView
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 20) {
                        CircleProgressButton(progress: $viewModel.progress, applyTheme: false)
                            .animation(.spring(), value: viewModel.progress)
                            .onTapGesture {
                                viewModel.changePage()
                            }
                        dotProgressView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .overlay(alignment: .topTrailing, content: {
            Button {
                viewModel.hasOnboarded = true
            } label: {
                Text("Skip".localized(viewModel.localizationManager.language))
                    .withComicFont(16, color: .white)
            }
            .padding(.trailing, 16)
            
        })
        .onAppear {
            withAnimation(.linear(duration: 0.3)) {
                viewModel.animateLogo.toggle()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 0 {
                        viewModel.previousPage()
                    } else {
                        viewModel.changePage()
                    }
                    
                }
        )
        
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        OnboardingView(viewModel: OnboardingViewModel(router: router))
    }
}


// MARK: - Components
extension OnboardingView {
    
    private var backgroundImageView: some View {
        Rectangle()
            .overlay(
                Image("IntroImage\(viewModel.pageCounter + 1)")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .animation(.easeIn, value: viewModel.pageCounter)
            )
            .clipped()
            .ignoresSafeArea()
            
    }
    
    
    private var logoImage: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .scaleEffect(viewModel.animateLogo ? 1 : 3)
            .opacity(viewModel.animateLogo ? 1 : 0.6)
            .frame(width: 34, height: 34)
            .offset(y: viewModel.animateLogo ? 100 : (UIScreen.main.bounds.height / 2) - 100)
    }
    
    
    private var dotProgressView: some View {
        HStack(spacing: 4 ) {
            ForEach(0..<4) { index in
                Circle()
                    .foregroundStyle(index == viewModel.pageCounter ? .hmIndigo : .hmDarkGray)
                    .frame(width: 8)
            }
        }
    }
    
    
    private var headlineTextView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.headlines[viewModel.pageCounter])
                .font(.custom(Constants.comicFont, size: 28))
            Text(viewModel.subheadlines[viewModel.pageCounter])
                .font(.custom(Constants.comicFont, size: 12))
            
        }
        .foregroundStyle(.white)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
        .animation(.easeIn, value: viewModel.pageCounter)
        .frame(width: 260, height: 124, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}
