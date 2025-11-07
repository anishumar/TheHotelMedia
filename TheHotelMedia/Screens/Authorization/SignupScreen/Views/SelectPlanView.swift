//
//  SelectPlanView.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI
import ActivityIndicatorView
import ACarousel

struct SelectPlanView: View {
    // MARK: - Properties
    
    @StateObject var viewModel: SelectPlanViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    var body: some View {
        ZStack {
            BackgroundImageView()
            
            VStack(spacing: UIScreen.main.bounds.height < 670 ? 15 : 37) {
                logo
                VStack(alignment: .leading, spacing: 16) {
                    title
                    ZStack(alignment: .center) {
                        cardScrollSection2
//                            .id(viewModel.plansToShow)
                    }
                    .frame(maxWidth: .infinity)
                    dotIndicatorView
                    bottomButtonSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
//        .preferredColorScheme(.dark)
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .onAppear {
            viewModel.addSubscribers()
            viewModel.getPlans()
//            Task {
//                try? await viewModel.iapManager.fetchSubscriptions(productIds: ["individualpremium199"])
//            }
        }
        .onDisappear {
            viewModel.cancelSubscriptions()
        }
    }
}

// MARK: - Preview

struct SelectPlanView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SelectPlanView(viewModel: SelectPlanViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Functions
extension SelectPlanView {
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
extension SelectPlanView {
    
    private var logo: some View {
        Image("Logo")
            .resizable()
            .frame(width: 92, height: 92)
            .padding(.top, UIScreen.main.bounds.height < 670 ? 10 : 20)
    }
    
    
    private var title: some View {
        Text("select_your_plan".localized(localizationManager.language))
            .font(.custom(Constants.comicFont, size: 20))
            .foregroundStyle(themeManager.currentTheme.label)
            .padding(.leading, 16)
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
                    .onTapGesture {
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
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    
    private var dotIndicatorView: some View {
        HStack {
            ForEach(0..<viewModel.plans.count) { index in
                Circle()
                    .fill(viewModel.currentIndex == index ? .hmIndigo : themeManager.currentTheme.mediumGray_mediumGray05)
                    .frame(width: 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .id(viewModel.plans)
    }
    
    
    private var arrayOfPlan: [AnyView] {
        var array: [AnyView] = []
        
        for plan in viewModel.plansToShow {
            array.append(AnyView(PlanCardView(plan: plan)))
        }
        
        return array
    }
    
    
    private var cardScrollSection2: some View {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        
        return VStack {
            if !viewModel.plans.isEmpty {
                if width > 410 {
                    ACarousel(viewModel.plans, index: $viewModel.currentIndex, spacing: 30, sidesScaling: 0.8) { plan in
                        PlanCardView(plan: plan)
                            .padding(.vertical, 4)
                    }
                    .frame(height: height * 0.48)
                } else {
                    ACarousel(viewModel.plans, index: $viewModel.currentIndex, spacing: 30, sidesScaling: 0.8) { plan in
                        PlanCardView(plan: plan)
                            .padding(.vertical, 4)
                    }
                    .frame(height: height * 0.48)
                }
            }
        }
    }
    
    
    private var cardScrollSection: some View {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        
        
        if width > 410 {
          return  CarouselView(
            actaulViewCount: viewModel.plans.count,
                itemHeight: UIScreen.main.bounds.height * 0.48,
                itemWidth: UIScreen.main.bounds.width * 0.7,
                currentIndex: $viewModel.currentIndex,
                views: arrayOfPlan
            )
        } else {
            return  CarouselView(
                  actaulViewCount: viewModel.plans.count,
                  itemHeight: UIScreen.main.bounds.height * 0.5,
                  itemWidth: UIScreen.main.bounds.width * 0.75,
                  currentIndex: $viewModel.currentIndex,
                  views: arrayOfPlan
              )
        }
        
    }
    
}
