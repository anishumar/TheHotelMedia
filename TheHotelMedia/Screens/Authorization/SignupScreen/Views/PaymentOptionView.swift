//
//  PaymentOptionView.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI

enum PaymentOption {
    case creditCard
    case googlePay
    case paypal
}

struct PaymentOptionView: View {
    // MARK: - Properties
    
    @StateObject var viewModel: PaymentOptionViewModel
    
    
    // MARK: - Body
    var body: some View {
        ZStack {
            BackgroundImageView()
            
            ScrollView(.vertical) {
                VStack(spacing: 37) {
                    logo
                    VStack(alignment: .leading, spacing: 26) {
                        title
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Credit & Debit Card")
                                .font(.custom(Constants.comicFont, size: 18))
                            
                            creditCardOption
                            
                            if viewModel.selectedOption == .creditCard {
                                creditCardDetailSection
                            }
                            
                            Text("More Payment Options")
                                .font(.custom(Constants.comicFont, size: 18))
                            
                            morePaymentsSection
                            
                        }
                        .font(.custom(Constants.comicFont, size: 16))
                        .foregroundStyle(.white.opacity(0.6))
                        .animation(.smooth, value: viewModel.selectedOption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    bottomSpacer
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }

            .clipped()
            
            bottomButtonSection
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

struct PaymentOptionView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        PaymentOptionView(viewModel: PaymentOptionViewModel(router: router))
    }
}


// MARK: - Components
extension PaymentOptionView {
    
    private var logo: some View {
        Image("Logo")
            .resizable()
            .frame(width: 92, height: 92)
            .padding(.top, UIScreen.main.bounds.height < 670 ? 10 : 20)
    }
    
    
    private var title: some View {
        Text("Select Payment method")
            .font(.custom(Constants.comicFont, size: 20))
            .foregroundStyle(.white)
    }
    
    
    private func creditDetailField(placeholder: String, text: Binding<String>) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(placeholder)
                .font(.custom(Constants.rubikLight, size: 16))
                .foregroundColor(.white.opacity(0.6))
        )
        .font(.custom(Constants.rubikLight, size: 16))
        .foregroundStyle(.white)
        .frame(height: 54)
        .padding(.horizontal)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.hmDarkestGray.opacity(0.5))
                RoundedRectangle(cornerRadius: 20)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            }
        )
    }
    
    
    private var bottomSpacer: some View {
        Rectangle()
            .fill(.black.opacity(0.001))
            .frame(maxWidth: .infinity)
            .frame(height: 100)
    }
    
    
    private var creditCardOption: some View {
        ZStack {
            Capsule()
                .fill(.hmDarkestGray.opacity(0.5))
                .frame(height: 46)
            Capsule()
                .stroke(lineWidth: 1)
                .fill(.hmDarkerGray)
                .frame(height: 46)
            
            HStack {
                Image("CreditCard")
                Text("Credit & Debit Card")
                    .frame(maxWidth: .infinity, alignment: .leading)
                circleButton(option: .creditCard)
            }
            .padding(.horizontal, 16)
        }
    }
    
    
    private var creditCardDetailSection: some View {
        VStack(spacing: 16){
            creditDetailField(placeholder: "Card Number", text: $viewModel.cardNumberText)
            HStack(spacing: 24) {
                creditDetailField(placeholder: "Expire Date", text: $viewModel.expiryDateFieldText)
                creditDetailField(placeholder: "CVV", text: $viewModel.cvvFieldText)
            }
            HStack {
                Image(systemName: viewModel.cardDetailSaved ? "checkmark.square.fill" : "checkmark.square")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.hmIndigo)
                    .frame(width: 24, height: 24)
                    .background(.black.opacity(0.001))
                    .onTapGesture {
                        viewModel.cardDetailSaved.toggle()
                    }
                Text("Save Card Details")
                    .font(.custom(Constants.rubikLight, size: 16))
                    .foregroundStyle(.white.opacity(viewModel.cardDetailSaved ? 1 : 0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    
    private var morePaymentsSection: some View {
        VStack {
            HStack {
                Image("GooglePay")
                Text("Google Pay")
                    .frame(maxWidth: .infinity, alignment: .leading)
                circleButton(option: .googlePay)
            }
            
            HStack {
                Image("Paypal")
                Text("Paypal")
                    .frame(maxWidth: .infinity, alignment: .leading)
                circleButton(option: .paypal)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.hmDarkestGray.opacity(0.5))
                RoundedRectangle(cornerRadius: 20)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
                Rectangle()
                    .fill(.hmDarkerGray)
                    .frame(height: 2)
            }
        )
    }
    
    
    private func circleButton(option: PaymentOption) -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 1)
                .frame(width: 20)
            
            Circle()
                .fill(viewModel.selectedOption == option ? .hmIndigo : .clear)
                .frame(width: 16)
            
        }
        .padding(.vertical,8)
        .padding(.leading, 16)
        .background(.black.opacity(0.001))
        .onTapGesture {
            viewModel.selectedOption = option
        }
        .animation(.smooth, value: viewModel.selectedOption)
    }
    
    
    private var bottomButtonSection: some View {
        ZStack {
            VStack {
                Button(action: {
                    viewModel.dismissScreen()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(.hmIndigo.opacity(0.4))
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
                        viewModel.showNextScreen()
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}
