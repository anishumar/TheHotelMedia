//
//  ChildrenAgesView.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import SwiftUI

struct ChildrenAgesView: View {
    
    @State var ageArray: [Int?] = []
    @State var showAlert: Bool = false
    var doneSelectingAge: (([Int]) -> Void)? = nil
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Group {
                RoundedRectangle(cornerRadius: 2)
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    .frame(width: Constants.screenWidth * 0.2, height: 4)
                
                Text("Select Age".localized(localizationManager.language))
                    .withComicFont(16, color: themeManager.currentTheme.label)
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(themeManager.currentTheme.white04_darkGray04)
                    .frame(height: 1)
            }
            .padding(.horizontal, 12)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    ForEach(0..<ageArray.count) { index in
                        NumberPickerView(title: "Child \(index + 1) Age", selectedNo: ageArray[index]) { number in
                            ageArray[index] = number
                        }
                    }
                }
            }
            
            Button {
                var array: [Int] = []
                for age in ageArray {
                    if let age {
                        array.append(age)
                    } else {
                        showMessage()
                        return
                    }
                }
                
                doneSelectingAge?(array)
                dismiss()
            } label: {
                Text("Proceed".localized(localizationManager.language))
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
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            if showAlert {
                BottomAlert(message: "Please select all the children ages before proceeding.".localized(localizationManager.language))
                    .transition(.move(edge: .bottom))
                    .shadow(color: .black.opacity(0.3), radius: 5)
            }
        }
        .background(
            themeManager.currentTheme.darkGray_hmwhite
        )
    }
}


// MARK: - Functions
extension ChildrenAgesView {
    func showMessage() {
        withAnimation(.easeInOut(duration: 0.8)) {
            showAlert = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut) {
                showAlert = false
            }
        }
    }
}
