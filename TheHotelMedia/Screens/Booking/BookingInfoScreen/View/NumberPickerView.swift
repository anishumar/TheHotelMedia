//
//  NumberPickerView.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import SwiftUI

struct NumberPickerView: View {
    
    var title: String
    var startNo: Int = 1
    var lastNo: Int = 17
    @State var selectedNo: Int? = nil
    var onSelectedNo: ((Int) -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .withComicFont(16, color: themeManager.currentTheme.white06_darkGray06)
                .padding(.horizontal, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(startNo...lastNo) { number in
                        ZStack {
                            Circle()
                                .fill(selectedNo == number ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.mediumGray_mediumGray08)
                            
                            Text("\(number)")
                                .withComicFont(17, color: .white)
                                .padding(3)
                        }
                        .frame(minWidth: 28, minHeight: 28)
                        .onTapGesture {
                            selectedNo = number
                            onSelectedNo?(number)
                        }
                        
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

