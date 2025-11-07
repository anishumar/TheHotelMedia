//
//  SettingTermsConditionView.swift
//  HotelMedia
//
//  Created by MAC on 03/09/24.
//

import SwiftUI

struct SettingTermsConditionView: View {
    @StateObject var viewModel: SettingTermsConditionViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                Text(
                    "Hotel Media (\"we,\" \"our,\" \"us\") respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the \"App\").Please read this Privacy Policy carefully. If you do not agree with the terms of this Privacy Policy, please do not access the App.\n \n 1. Information We CollectPersonal InformationWe may collect personal information that you provide to us, including:\n \nContact Information: Name, email address, phone number.\nAccount Information: Username, password, profile picture, and other profile details.\nPayment Information: Credit card information, billing address (for subscription payments).\nNon-Personal Information\nWe may collect non-personal information about your use of the App, such as:\nDevice Information: Device type, operating system, unique device identifiers.\nUsage Information: Pages viewed, features used, time spent on the App, and other usage statistics.\nLocation Information: General location information based on your IP address or device settings.\n\n2. How We Use Your Information\nWe use the information we collect for various purposes, including:\nTo Provide and Maintain the App: To deliver and improve our services, manage user accounts, and provide customer support.\nTo Process Transactions: To process payments for subscriptions and other purchases.\nTo Communicate with You: To send you updates, newsletters, and other information related to the App.\nTo Personalize Your Experience: To tailor content and features based on your preferences and usage patterns.\nTo Improve Our Services: To conduct research and analysis to understand user behavior and improve the App.\nTo Ensure Security: To detect, prevent, and address technical issues and protect against fraud.\n\n3. Sharing Your Information\nWe may share your information in the following circumstances:\nWith Service Providers: We may share your information with third-party service providers who perform services on our behalf, such as payment processing, data analysis, and email delivery.\nWith Business Partners: We may share your information with business partners to offer you certain products, services, or promotions.\nFor Legal Reasons: We may disclose your information if required by law or in response to valid requests by public authorities (e.g., court orders, subpoenas).\nIn Business Transfers: If we are involved in a merger, acquisition, or asset sale, your information may be transferred as part of that transaction.\n\n4. Your Choices and RightsYou have certain choices and rights regarding your information:\nAccess and Update: You can access and update your personal information through your account settings.\nOpt-Out: You can opt-out of receiving promotional emails by following the unsubscribe instructions in those emails.\nDelete Account: You can delete your account by contacting us at [insert contact email].\nData Protection Rights: Depending on your location, you may have the right to request access to, correction, or deletion of your personal information, as well as the right to restrict or object to certain data processing activities. Please contact us at [insert contact email] to exercise these rights.\n\n5. Security of Your Information\nWe use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse.\n\n6. Children’s Privacy\nOur App is not intended for use by children under the age of 13. We do not knowingly collect personal information from children under 13. If we learn that we have collected personal information from a child under 13, we will delete that information as quickly as possible. If you believe we might have any information from or about a child under 13, please contact us at [insert contact email].\n\n7. Changes to This Privacy Policy\nWe may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the effective date. You are advised to review this Privacy Policy periodically for any changes.\n\n8. Contact Us\nIf you have any questions about this Privacy Policy, please contact us:\nEmail: ----------\nAddress: ----------"
                    )
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.top, 50)
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(
            header
            , alignment: .top
        )
    }
}

// MARK: - Preview
struct SettingTermsConditionView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SettingTermsConditionView(viewModel: SettingTermsConditionViewModel(router: router))
    }
}


// MARK: - Components

extension SettingTermsConditionView {
    
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
            
            Text("Terms and Conditions")
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .background(.black)
    }
}

