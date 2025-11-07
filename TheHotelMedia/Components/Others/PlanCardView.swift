//
//  PlanCardView.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI
import SDWebImageSwiftUI

enum PlanType: String {
    case basic = "Basic"
    case standard = "Standard"
    case premium = "Premium"
}

struct PlanCardView: View {
    
    var plan: SubscriptionPlan
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(themeManager.currentTheme.darkGray05_white)
            RoundedRectangle(cornerRadius: 15)
                .stroke(lineWidth: 1)
                .fill(themeManager.currentTheme.white_hmIndigo)
            
            VStack {
                cardHeader
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(plan.description ?? "")
                            
                        
                        Text("What's Included:")
                            .font(.custom(Constants.comicBold, size: 12))
                           
                        featuresSection
                    }
                    .font(.custom(Constants.comicFont, size: 12))
                    .foregroundStyle(themeManager.currentTheme.label)
                    .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    func printNamesOfFont() {
        for family in UIFont.familyNames {
            for fontName in UIFont.fontNames(forFamilyName: family) {
                print(fontName)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PlanCardView(plan: SubscriptionPlan(id: "", features: [], businessSubtypeID: [], businessTypeID: [], name: "", description: "", appleSubscriptionID: "", price: 0, duration: "", image: "", type: "", level: "", currency: "", createdAt: "", updatedAt: ""))
            .frame(width: 300, height: 450, alignment: .top)
    }
    
}

// MARK: - Functions
extension PlanCardView {
    func getDurationShortForm(fullForm: String) -> String {
        if fullForm == "monthly" {
            return "M"
            
        } else if fullForm == "half-yearly" {
            return "6M"
            
        } else if fullForm == "quarterly" {
            return "3M"
            
        } else {
            return "Y"
        }
    }
}


extension PlanCardView {
    
    private func planFeature(text: String) -> some View {
        HStack(spacing: 10) {
            Image(themeManager.currentTheme.CircleTick)
            Text(text)
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundStyle(themeManager.currentTheme.label)
                .multilineTextAlignment(.leading)
        }
    }
    
    
    private var featuresSection: some View {
        Group {
            ForEach(plan.features ?? [], id: \.self) { feature in
                planFeature(text: feature)
            }
        }
    }
    
    
    private var cardHeader: some View {
        HStack {
            WebImage(url: URL(string: plan.image ?? ""))
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 36))
                .foregroundColor(themeManager.currentTheme.white_hmIndigo)
                .scaledToFit()
                .frame(width: 36, height: 36)
            Text(plan.name ?? "")
                .font(.custom(Constants.comicBold, size: 20))
                .foregroundStyle(themeManager.currentTheme.white_hmIndigo)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack {
                Text("₹\(plan.price ?? 0)")
                    .font(.custom(Constants.comicFont, size: 24))
                +
                Text("/")
                    .font(.custom(Constants.comicFont, size: 16))
                +
                Text("\(getDurationShortForm(fullForm: plan.duration ?? ""))")
                    .font(.custom(Constants.comicFont, size: 16))
                    
            }
            .foregroundStyle(themeManager.currentTheme.white_hmIndigo)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .multilineTextAlignment(.trailing)
            
            
        }
        .padding()
    }
}
