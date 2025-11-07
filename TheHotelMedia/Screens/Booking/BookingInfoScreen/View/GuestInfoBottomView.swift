//
//  GuestInfoBottomView.swift
//  TheHotelMedia
//
//  Created by MAC on 13/02/25.
//

import SwiftUI

struct GuestInfoBottomView: View {
    
    @State var guestCount: Int
    @State var childrenCount: Int
    @State var withPet: Bool
    var onDismiss: ((Int, Int, Bool) -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: Constants.screenWidth * 0.2, height: 4)
            
            Text("Guest and room".localized(localizationManager.language))
                .withComicFont(16, color: themeManager.currentTheme.label)
            
            RoundedRectangle(cornerRadius: 1)
                .fill(themeManager.currentTheme.white04_darkGray04)
                .frame(height: 1)
            
            
            VStack {
                CustomCounterView(count: $guestCount, icon: "PersonIcon2", title: "Guest".localized(localizationManager.language), minCount: 1)
                CustomCounterView(count: $childrenCount, icon: "Cloth", title: "Children".localized(localizationManager.language))
                CustomCheckView(bool: $withPet, icon: "Paw", title: "Traveling with pet".localized(localizationManager.language))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            Button {
                guard guestCount > 0 else { return }
                onDismiss?(guestCount, childrenCount, withPet)
                dismiss()
            } label: {
                Text(childrenCount == 0 ? "Proceed".localized(localizationManager.language) : "Next".localized(localizationManager.language))
                    .withComicFont(16, color: .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .background(
            themeManager.currentTheme.darkGray_hmwhite
        )
    }
}
