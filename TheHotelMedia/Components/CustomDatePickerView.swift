//
//  CustomDatePickerView.swift
//  TheHotelMedia
//
//  Created by MAC on 13/05/25.
//

import SwiftUI


struct CustomDatePickerView: View {
    
    @Binding var isActive: Bool
    @Binding var selectedDate: Date
    @Binding var dateRange: ClosedRange<Date>
    var pickerComponents: DatePicker<Label>.Components = [.date]
    var onSelectedDate: ((Date) -> Void)? = nil
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        VStack {
            if isActive {
                VStack {
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        in: dateRange,
                        displayedComponents: pickerComponents
                    )
                    .datePickerStyle(.graphical)
                    HStack {
                        Button("Cancel") {
                            withAnimation(.bouncy) {
                                isActive = false
                            }
                        }
                        .buttonStyle(.bordered)
                        Button("OK") {
                            withAnimation(.bouncy) {
                                isActive = false
                                onSelectedDate?(selectedDate)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeManager.currentTheme.darkGray_white)
                )
                .padding()
                .accentColor(.hmIndigo)
                .transition(.push(from: .top))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(
            Material.ultraThin
                .opacity(isActive ? 1 : 0)
        )
    }
}
