//
//  SubscriptionView.swift
//  TheHotelMedia
//
//  Created by MAC on 18/11/24.
//

import SwiftUI
import SDWebImageSwiftUI
import ACarousel

struct SubscriptionView: View {
    
    @StateObject var viewModel: SubscriptionViewModel
    @State var showAlert: Bool = false
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CustomHeaderView(title: "subscription".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            .padding(.horizontal, 16)
            
            VStack {
                Text("active_subscription".localized(localizationManager.language))
                    .withComicFont(16, color: themeManager.currentTheme.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("current_subscription".localized(localizationManager.language))
                            .font(.custom(Constants.comicBold, size: 14))
                            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        Spacer()
                        
                        Text("\(viewModel.subscription?.remainingDays ?? 0) " + "days_remaining".localized(localizationManager.language))
                            .withComicFont(14, color: themeManager.currentTheme.label)
                            .opacity(viewModel.subscription == nil ? 0.0 : 1.0)
                    }
                    
                    HStack {
                        HStack {
                            WebImage(url: URL(string: viewModel.subscription?.image ?? "")) { image in
                                image
                                    .resizable()
                                    .renderingMode(.template)
                                    .font(.system(size: 20))
                                    .foregroundColor(themeManager.currentTheme.white_hmIndigo)
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            } placeholder: {
                                
                            }

                            Text(viewModel.subscription?.name ?? "Free Plan")
                                .withComicFont(16, color: themeManager.currentTheme.label)
                        }
                        
                        Spacer()
                        
                        if viewModel.subscription != nil {
                            Text("cancel_subscription".localized(localizationManager.language))
                                .withComicFont(11, color: themeManager.currentTheme.label)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(lineWidth: 1)
                                        .fill(themeManager.currentTheme.white_hmIndigo)
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
//                                        viewModel.showCancelSubscriptionModel.toggle()
                                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                }
                        }
                        
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray05_white)
                        
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(lineWidth: 1)
                            .fill(themeManager.currentTheme.white_hmIndigo)
                    }
                )
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 16) {
                title
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                ZStack(alignment: .center) {
                    cardScrollSection2
//                        .id(viewModel.plansToShow)
                }
                .frame(maxWidth: .infinity)
                dotIndicatorView
            }
            .frame(maxHeight: .infinity, alignment: .center)
            
            bottomButtonSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .preferredColorScheme(.dark)
        .overlay {
            ZStack {
                if viewModel.showCancelSubscriptionModel {
                    Color.black.opacity(0.5).ignoresSafeArea()
                }
                
                
                if viewModel.showCancelSubscriptionModel {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(.hmRed)
                                    .frame(width: 28, height: 28)
                                
                                Circle()
                                    .fill(.white)
                                    .frame(width: 16, height: 16)
                                
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(.hmRed)
                            }
                            
                            
                            Text("sure_you_want_to_cancel_subscription".localized(localizationManager.language))
                                .withComicFont(12, color: .white)
                        }
                        
                        HStack {
                            Text("no_cancel".localized(localizationManager.language))
                                .withComicFont(11, color: .white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(lineWidth: 1)
                                        .fill(.white)
                                )
                                .onTapGesture {
                                    viewModel.showCancelSubscriptionModel.toggle()
                                }
                            
                            Text("yes_confirm".localized(localizationManager.language))
                                .withComicFont(11, color: .white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 13)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.hmRed)
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(lineWidth: 1)
                                            .fill(.white)
                                    }
                                )
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .onTapGesture {
                                    viewModel.showCancelSubscriptionModel.toggle()
                                    viewModel.cancelUserPlanSubscription()
                                }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 21)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.hmDarkestGray)
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(lineWidth: 1)
                                .fill(.white)
                        }
                    )
                    .frame(width: 296)
                    .transition(.scale)
                }
            }
        }
        .alert("Already Subscribed!", isPresented: $showAlert, actions: {
            
        }, message: {
            Text("You already have an active subscription. You can buy or update to a new plan only after your current plan has been expired and cancelled.")
        })
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .onAppear {
            viewModel.addSubscribers()
            viewModel.getActiveSubscription()
            viewModel.getPlans()
        }
        .onDisappear {
            viewModel.cancelSubscriptions()
        }
    }
}

// MARK: - Preview
struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SubscriptionView(viewModel: SubscriptionViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Functions
extension SubscriptionView {
    func showPlanError() {
        if viewModel.plans[viewModel.currentIndex].price == 0 {
            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "this_is_a_free_plan".localized(localizationManager.language))
        } else {
//            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "there_is_an_error_performing_your_request".localized(localizationManager.language))
            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "This plan is currently not available. Please try again later.".localized(localizationManager.language))
        }
    }
}


// MARK: - Components
extension SubscriptionView {
    
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(.white)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    viewModel.dismissScreen()
                }
            
            Text("subscription".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
        }
        .padding(.top, 12)
    }
    
    
    private var logo: some View {
        Image("Logo")
            .resizable()
            .frame(width: 92, height: 92)
            .padding(.top, UIScreen.main.bounds.height < 670 ? 10 : 20)
    }
    
    
    private var title: some View {
        Text("select_your_plan".localized(localizationManager.language))
            .withComicFont(20, color: themeManager.currentTheme.label)
            .padding(.leading, 16)
    }
    
    
    private var bottomButtonSection: some View {
        VStack {
            CircleProgressButton(progress: .constant(100))
                .onTapGesture {
                    guard viewModel.subscription == nil else {
                        showAlert = true
                        return
                    }
                    
                    guard !viewModel.plans.isEmpty else { return }
                    
                    guard let id = viewModel.plans[viewModel.currentIndex].appleSubscriptionID, !id.isEmpty else {
                        showPlanError()
                        return
                    }
                    
                    if let product = viewModel.subscriptionProducts.first(where: { $0.id == id}) {
                        viewModel.showNextScreen(product: product)
                    } else {
                        showPlanError()
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 16)
    }
    
    
    private var dotIndicatorView: some View {
        VStack {
            HStack {
                ForEach(0..<viewModel.plans.count) { index in
                    Circle()
                        .fill(viewModel.currentIndex == index ? .hmIndigo : themeManager.currentTheme.mediumGray_mediumGray05)
                        .frame(width: 14)
                }
            }
            .id(viewModel.plans)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .frame(height: 14)
        
    }
    
    
    private var arrayOfPlan: [AnyView] {
        var array: [AnyView] = []
        
        for plan in viewModel.plansToShow {
            array.append(AnyView(PlanCardView(plan: plan)))
        }
        
        return array
    }
    
    
    private var cardScrollSection2: some View {
        var cardHeight = Constants.screenHeight - 350 - UIApplication.topSafeAreaHeightTHM - UIApplication.bottomSafeAreaHeightTHM
        return VStack {
            if !viewModel.plans.isEmpty {
                ACarousel(viewModel.plans, index: $viewModel.currentIndex, spacing: 30, sidesScaling: 0.8) { plan in
                    PlanCardView(plan: plan)
                        .padding(.vertical, 4)
                }
                .frame(height: cardHeight)
            }
        }
        .frame(height: cardHeight)
    }
    
    
    private var cardScrollSection: some View {
        
        var cardHeight = Constants.screenHeight - 350 - UIApplication.topSafeAreaHeightTHM - UIApplication.bottomSafeAreaHeightTHM
        
        if Constants.screenWidth > 410 {
            let cardWidth = Constants.screenWidth * 0.7
            
            if cardHeight/cardWidth > 1.5 {
                cardHeight = cardWidth * 1.5
            }
        } else {
            let cardWidth = Constants.screenWidth * 0.75
            
            if cardHeight/cardWidth > 1.5 {
                cardHeight = cardWidth * 1.5
            }
        }
        
        
        if Constants.screenWidth > 410 {
          return  CarouselView(
            actaulViewCount: viewModel.plans.count,
                itemHeight: cardHeight,
                itemWidth: Constants.screenWidth * 0.7,
                currentIndex: $viewModel.currentIndex,
                views: arrayOfPlan
            )
        } else {
            return  CarouselView(
                  actaulViewCount: viewModel.plans.count,
                  itemHeight: cardHeight,
                  itemWidth: Constants.screenWidth * 0.75,
                  currentIndex: $viewModel.currentIndex,
                  views: arrayOfPlan
              )
        }
        
    }
    
}

