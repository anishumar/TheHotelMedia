//
//  ReviewSummaryView.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI
import ActivityIndicatorView
import SDWebImageSwiftUI
import StoreKit

struct ReviewSummaryView: View {
    // MARK: - Properties
    
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    @StateObject var viewModel: ReviewSummaryViewModel
    @State var showRedeemSheet: Bool = false
    @State var showOptionDialog: Bool = false
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    var body: some View {
        ZStack {
            BackgroundImageView()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 37) {
                    logo
                    VStack(alignment: .leading, spacing: 26) {
                        title
                        billingAddressSection
                        planSection
//                        promoSection
                        billSection
                        bottomButtonSection
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .clipped()
        }
//        .preferredColorScheme(.dark)
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .alert("Already Subscribed!", isPresented: $viewModel.showActiveSubAlert) {
            
        } message: {
            Text("The apple ID associated to your device already has an active subscription. You can buy or update to a new plan only after your current plan has been expired and cancelled.")
        }

//        .onReceive(viewModel.iapManager.$jwsToken) { token in
//            if let token {
//                viewModel.showPurchaseLoading = false
//                viewModel.buyPlan2(token: token)
//            }
//        }
//        .onAppear {
//            viewModel.addSubscribers()
//            viewModel.getCheckouDetails()
//        }
        .onDisappear {
            viewModel.cancelPurchaseTask()
        }
    }
    
    private func addPromoCode() {
        if viewModel.promoFieldText.isEmpty {
            viewModel.getCheckouDetails()
        } else {
            if viewModel.checkoutData?.payment?.promoCode != nil {
                viewModel.getCheckouDetails()
            } else {
                viewModel.getCheckouDetails(addPromoCode: true, promoCode: viewModel.promoFieldText)
            }
        }
    }
}

// MARK: - Preview
struct ReviewSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        ReviewSummaryView(viewModel: ReviewSummaryViewModel(router: router, subscriptionPlanID: ""))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Functions
extension ReviewSummaryView {
    private func showRazorpay(name: String, app_name: String, description: String, image: String, themeColor: String, currency: String, order_id: String, amount: String) {
//        let razorpayView = RazorpayView(
//            name: name,
//            app_name: app_name,
//            description: description,
//            image: image,
//            themeColor: themeColor,
//            currency: currency,
//            order_id: order_id,
//            amount: amount,
//            onPaymentSuccess: {
//                paymentSuccessModel in
//                if let orderID = viewModel.orderID {
//                    viewModel.buySubcription(
//                        paymentID: paymentSuccessModel.paymentID,
//                        signature: paymentSuccessModel.signature,
//                        orderID: orderID
//                    )
//                }
//                
//            },
//            onPaymentError: { error in
//                ErrorModalManager.showErrorModal(router: viewModel.router, errorText: error)
//            }
//        )
//        
//        let hostingController = UIHostingController(rootView: razorpayView)
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//            windowScene.windows.first?.rootViewController?.present(hostingController, animated: true, completion: nil)
//        }
    }
}


// MARK: - Components
extension ReviewSummaryView {
    
    private var logo: some View {
        Image("Logo")
            .resizable()
            .frame(width: 92, height: 92)
            .padding(.top, UIScreen.main.bounds.height < 670 ? 10 : 20)
    }
    
    
    private var title: some View {
        Text("review_summary".localized(localizationManager.language))
            .font(.custom(Constants.comicFont, size: 20))
            .foregroundStyle(themeManager.currentTheme.label)
    }
    
    
    private var planSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("SignBoard")
                Text("you_plan".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundStyle(themeManager.currentTheme.label)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray05_white)
                    .frame(height: 46)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
                    .frame(height: 46)
                planView
            }
            
        }
    }
    
    
    private var billingAddressSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("BillingAddress")
                Text("billing_address".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundStyle(themeManager.currentTheme.label)
            }
            
            
            VStack(spacing: 8) {
                HStack {
                    Text("name".localized(localizationManager.language) + ":")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(viewModel.checkoutData?.billingAddress?.name ?? "")
                }
                
                HStack(alignment: .top) {
                    Text("address".localized(localizationManager.language) + ":")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(viewModel.addressString)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("phone_number".localized(localizationManager.language) + ":")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(viewModel.checkoutData?.billingAddress?.dialCode ?? "")\(viewModel.checkoutData?.billingAddress?.phoneNumber ?? "")")
                }
                
                if let gstn = viewModel.checkoutData?.billingAddress?.gstn, !gstn.isEmpty {
                    HStack {
                        Text("gstn".localized(localizationManager.language) + ":")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(gstn)
                    }
                }
                 
            }
            .font(.custom(Constants.comicFont, size: 13))
            .foregroundStyle(themeManager.currentTheme.label)
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.darkGray05_white)
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                }
            )
        }
    }
    
    
    private var promoSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("PromoCode2")
                Text("promo_code".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundStyle(themeManager.currentTheme.label)
            }
            
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.darkGray05_white)
                        .frame(height: 46)
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                        .frame(height: 46)
                    
                    HStack {
                        TextField(
                            "",
                            text: $viewModel.promoFieldText,
                            prompt: Text("promocode".localized(localizationManager.language))
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        )
                        .textInputAutocapitalization(.characters)
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundStyle(themeManager.currentTheme.label)
                        .padding(.horizontal)
                        .overlay {
                            if viewModel.checkoutData?.payment?.promoCode != nil {
                                Rectangle()
                                    .fill(.black.opacity(0.001))
                            }
                        }
                        
                        Text(viewModel.checkoutData?.payment?.promoCode == nil ? "apply".localized(localizationManager.language).capitalized : "remove".localized(localizationManager.language).capitalized)
                            .withComicFont(16, color: viewModel.checkoutData?.payment?.promoCode == nil ? .hmIndigo : .hmDarkGray)
                            .fontWeight(.bold)
                            .onTapGesture {
                                endEditing()
                                addPromoCode()
                            }
                            .padding(.trailing)
                            
                    }
                }
            }
        }
    }
    
    
    private var planView: some View {
        HStack {
            WebImage(url: URL(string: viewModel.checkoutData?.plan?.image ?? ""))
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 30))
                .foregroundColor(themeManager.currentTheme.label)
                .scaledToFit()
                .frame(width: 30, height: 30)
            Text(viewModel.checkoutData?.plan?.name ?? "")
                .font(.custom(Constants.comicBold, size: 16))
                .foregroundStyle(themeManager.currentTheme.label)
            
            HStack {
                Text("₹\(viewModel.checkoutData?.plan?.price ?? 0)")
                    .font(.custom(Constants.comicFont, size: 20))
                +
                Text("/")
                    .font(.custom(Constants.comicFont, size: 16))
                +
                Text("\(viewModel.checkoutData?.plan?.duration ?? "")")
                    .font(.custom(Constants.comicFont, size: 16))
            }
            .foregroundStyle(themeManager.currentTheme.label)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            
        }
        .padding(.horizontal)
    }
    
    
    private var billSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("BillIcon2")
                Text("bill_details".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundStyle(themeManager.currentTheme.label)
            }
            
            
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    HStack {
                        Text("plan_charges".localized(localizationManager.language))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("₹\(String(format: "%.2f", viewModel.checkoutData?.payment?.total ?? 0))")
                        
                        
                    }
                    
                    if let promoCode = viewModel.checkoutData?.payment?.promoCode {
                        HStack {
                            Text("discount".localized(localizationManager.language))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if promoCode.priceType == "percent" {
                                Text("-\(Int(promoCode.value))%")
                                    .foregroundStyle(.red)
                            } else {
                                Text("-\(promoCode.value)")
                                    .foregroundStyle(.red)
                            }
                            
                            Text("(\(promoCode.code))")
                        }
                    }
                    
                    Text("(Including applicable taxes)")
                        .font(.custom(Constants.comicFont, size: 12.5))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                
//                if let gstAmount = viewModel.checkoutData?.payment?.gst, gstAmount != 0 {
//                    HStack {
//                        if let gstRate = viewModel.checkoutData?.payment?.gstRate {
//                            Text("gst".localized(localizationManager.language).uppercased() + "(\(Int(gstRate))%)")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                        } else {
//                            Text("gst".localized(localizationManager.language).uppercased())
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                        }
//                        
//                        
//                        Text("₹\(String(format: "%.2f", arguments: [gstAmount]))")
//                    }
//                }
               
                
                DottedLine()
                    .stroke(style: .init(lineWidth: 1, dash: [3]))
                    .foregroundStyle(themeManager.currentTheme.white03_darkGray03)
                    .frame(height: 1)
                
                HStack {
                    Text("Payable amount")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("₹\(String(format: "%.2f", arguments: [viewModel.checkoutData?.payment?.total ?? 0]))")
                }
            }
            .font(.custom(Constants.comicFont, size: 14))
            .foregroundStyle(themeManager.currentTheme.label)
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.darkGray05_white)
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                }
            )
            
            HStack(alignment: .bottom) {
                Text("Have a promocode")
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundStyle(themeManager.currentTheme.label)
                
                Spacer()
                Button {
                    initiatePurchase {
                        showRedeemSheet = true
                    }
                } label: {
                    Text("Redeem Now")
                        .font(.custom(Constants.comicBold, size: 16))
                        .foregroundStyle(.hmIndigo)
                        
                }

            }
//            Text("*The price includes the GST.")
//                .font(.custom(Constants.comicFont, size: 12))
//                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
//                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    
    private var bottomButtonSection: some View {
        ZStack {
            VStack {
                Button(action: {
//                    if viewModel.showPurchaseLoading {
//                        ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "Please wait while we are fetching your purchased subscription!")
//                    } else {
//                        viewModel.dismissScreen()
//                    }
                    viewModel.showDismissAlert = true
                    
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
            
            VStack {
                CircleProgressButton(progress: .constant(100), hideProgress: viewModel.showPurchaseLoading)
                    .onTapGesture {
                        initiatePurchase {
                            startNormalPurchase()
                        }
                    }
                    .offerCodeRedemption(isPresented: $showRedeemSheet) { result in
                        viewModel.showAlert = true
                        switch result {
                        case .success:
                            startRedeemPurchase()
                            
                        case .failure(let error):
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: error.localizedDescription)
                        }
                    }
                    .confirmationDialog("Choose an option", isPresented: $showOptionDialog, titleVisibility: .visible, actions: {
                        Button("Redeem Code") {
                            showRedeemSheet.toggle()
                        }
                        Button("Subscribe") {
                            startNormalPurchase()
                        }
                    })
                    .alert("Alert!", isPresented: $viewModel.showAlert, actions: {
                        Button("OK") {
                            viewModel.showAlert = false
                        }
                    }, message: {
                        Text("⏳ Please wait if you have subscribed, while we fetch your subscription...")
                    })
                    .alert("Do you want to exit?", isPresented: $viewModel.showDismissAlert, actions: {
                        Button(role: .destructive) {
                            viewModel.dismissScreen()
                        } label: {
                            Text("Exit")
                        }
                        
//                        Button("Cancel") {
//                            viewModel.showDismissAlert = false
//                        }

                    }, message: {
                        Text("If Just Subscribed! please wait while we fetch you subscription or exit.")
                    })
                    .alert("Fetching Subscription!", isPresented: $viewModel.showFetchingSubscriptionAlert, actions: {
                        Button("Yes") {
                            viewModel.showFetchingSubscriptionAlert = false
                            viewModel.cancelPurchaseTask()
                            viewModel.startedPurchase = false
                            initiatePurchase {
                                startNormalPurchase()
                            }
                        }
                        Button("No") {
                            viewModel.showFetchingSubscriptionAlert = false
                        }
                    }, message: {
                        Text("Are you sure you want to start a new purchase and cancel current subscription fetching?")
                    })
                    .overlay {
                        ActivityIndicatorView(isVisible: $viewModel.showPurchaseLoading, type: .growingArc(.hmIndigo, lineWidth: 3.5))
                            .frame(width: 58, height: 58)
                    }
//                    .overlay {
//                        if !viewModel.amount.isEmpty {
//                            RazorpayView(
//                                name: .constant("The Hotel Media"),
//                                app_name: .constant("The Hotel Media"),
//                                description: .constant("Business Subscription"),
//                                image: .constant("https://s3.amazonaws.com/rzp-mobile/images/rzp.jpg"),
//                                themeColor: .constant("#082C50"),
//                                currency: $viewModel.currency,
//                                order_id: $viewModel.razorID,
//                                amount: $viewModel.amount,
//                                phoneNumber: $viewModel.phoneNumber,
//                                email: .constant("-------")) { paymentSuccessModel in
//                                    
//                                    guard let orderID = viewModel.orderID else { return }
//                                    
//                                    print(paymentSuccessModel.paymentID, paymentSuccessModel.signature, orderID )
//                                    
//                                    viewModel.buySubcription(
//                                        paymentID: paymentSuccessModel.paymentID,
//                                        signature: paymentSuccessModel.signature,
//                                        orderID: orderID
//                                    )
//                                    
//                                } onPaymentError: { error in
//    //                                ErrorModalManager.showErrorModal(router: viewModel.router, errorText: error)
//                                }
//                                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        } else {
//                            Color.black.opacity(0.001)
//                                .onTapGesture {
//                                    ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "Failed to fetch checkout data. Please reselect a plan again.")
//                                }
//                        }
//                    }
            }
            
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}


// MARK: - Functions
extension ReviewSummaryView {
    func initiatePurchase(onNoActiveSubFound: (() -> Void)? = nil) {
        
        guard let orderID = viewModel.orderID, orderID.isNotEmpty else {
            viewModel.getCheckouDetails()
            return
        }
        
        guard !viewModel.startedPurchase else { return }
        viewModel.startedPurchase = true
        if let product = viewModel.product {
            Task {
                await MainActor.run {
                    viewModel.showPurchaseLoading = true
                }
                
                guard await !viewModel.iapManager.fetchActiveSubscriptions() else {
                    await MainActor.run {
                        viewModel.showActiveSubAlert = true
                        viewModel.startedPurchase = false
                        viewModel.showPurchaseLoading = false
                    }
                    return
                }
                
                await MainActor.run {
//                    viewModel.startedPurchase = false
//                    viewModel.showPurchaseLoading = false
//                    showOptionDialog.toggle()
//                    startNormalPurchase()
                    onNoActiveSubFound?()
                }
            }
        }
    }
    
    
    func startRedeemPurchase() {
        viewModel.startedPurchase = true
        viewModel.showPurchaseLoading = true
        viewModel.purchaseTask = Task {
            if let jwsToken = await viewModel.iapManager.getJwsToken(retries: 1000) {
                await MainActor.run {
                    viewModel.showPurchaseLoading = false
                    viewModel.startedPurchase = false
                }
                viewModel.buyPlan2(token: jwsToken, type: "success")
            } else {
                await MainActor.run {
                    viewModel.showPurchaseLoading = false
                    viewModel.startedPurchase = false
                }
            }
        }
    }
    
    
    func startNormalPurchase() {
        viewModel.startedPurchase = true
        viewModel.showPurchaseLoading = true
        viewModel.purchaseTask = Task {
            if let product = viewModel.product {
                let (jwsToken, type) = await viewModel.iapManager.purchaseSubscription(subscription: product)
                
                if let jwsToken  {
                    await MainActor.run {
                        viewModel.showPurchaseLoading = false
                        viewModel.startedPurchase = false
                    }
                    viewModel.buyPlan2(token: jwsToken, type: type)
                } else {
                    await MainActor.run {
                        viewModel.showPurchaseLoading = false
                        viewModel.startedPurchase = false
                    }
                }
            }
        }
    }
}
