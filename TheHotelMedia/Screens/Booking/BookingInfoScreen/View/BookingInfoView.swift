//
//  BookingInfoView.swift
//  TheHotelMedia
//
//  Created by MAC on 13/02/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct BookingInfoView: View {
    
    @StateObject var viewModel: BookingInfoViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 12) {
            CustomHeaderView(title: "add_details".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            
            businessHeaderView
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    fromDateField
                        .onTapGesture {
                            withAnimation(.bouncy) {
                                viewModel.showFromDatePicker = true
                            }
                        }
                    toDateField
                        .onTapGesture {
                            withAnimation(.bouncy) {
                                viewModel.showToDatePicker = true
                            }
                        }
                }
                .sheet(isPresented: $viewModel.showChildrenAgeView) {
                    ChildrenAgesView(ageArray: viewModel.childrenAges) { array in
                        viewModel.childrenAges = array
                        viewModel.checkIn()
                    }
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.height(CGFloat(viewModel.childrenAges.count * 70 + 165))])
                }
                
                
                GrayTextField(
                    textfieldText: $viewModel.guestFieldText,
                    title: "guest".localized(localizationManager.language),
                    placeholder: "guest".localized(localizationManager.language),
                    leftIcon: "PersonIcon2",
                    rightIcon: .constant(
                        nil
                    )
                )
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.001))
                        .onTapGesture {
                            viewModel.showGuestCountView = true
                            if viewModel.guestCount == 0 {
                                viewModel.guestCount = 1
                            }
                        }
                }
                .sheet(isPresented: $viewModel.showGuestCountView) {
                    GuestInfoBottomView(guestCount: viewModel.guestCount, childrenCount: viewModel.childrenCount, withPet: viewModel.withPet, onDismiss: { guest, children, withPet in
                        viewModel.guestCount = guest
                        viewModel.childrenCount = children
                        viewModel.withPet = withPet
                        
                        viewModel.updateAgeArray()
                        
                        if viewModel.childrenCount > 0 {
                            viewModel.showAgeViewSheet()
                            
                        } else if viewModel.guestCount > 0 {
                            viewModel.checkIn()
                        }
                    })
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.medium])
                }
            }
           
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay {
            ZStack {
                CustomDatePickerView(isActive: $viewModel.showFromDatePicker, selectedDate: $viewModel.pickerFromDate, dateRange: $viewModel.fromDateRange) { date in
                    viewModel.selectedFromDate = date
                }
                
                CustomDatePickerView(isActive: $viewModel.showToDatePicker, selectedDate: $viewModel.pickerToDate, dateRange: $viewModel.toDateRange) { date in
                    viewModel.selectedToDate = date
                }
//                if viewModel.showFromDatePicker {
//                    fromPickerView
//                        .transition(.push(from: .top))
//                        .onAppear {
//                            if viewModel.selectedFromDate == nil {
//                                viewModel.selectedFromDate = viewModel.fromDateRange.lowerBound
//                            }
//                        }
//                }
//                
//                if viewModel.showToDatePicker {
//                    toPickerView
//                        .transition(.push(from: .top))
//                        .onAppear {
//                            if viewModel.selectedToDate == nil {
//                                viewModel.selectedToDate = viewModel.toDateRange.lowerBound
//                            }
//                        }
//                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(
//                Color.black.opacity(0.5).ignoresSafeArea()
//                    .opacity(viewModel.showFromDatePicker || viewModel.showToDatePicker ? 1.0 : 0.0)
//            )
            
            
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}


// MARK: - Components
extension BookingInfoView {
    private var businessHeaderView: some View {
        HStack(spacing: 15) {
            BusinessProfilePicView(stringURL: viewModel.profileData?.businessProfileRef?.profilePic?.small ?? "", dimension: 41, border: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(viewModel.profileData?.businessProfileRef?.name ?? "")
                        .withComicFont(16, color: .white)
                    
                    Spacer()
                    
                    Text(viewModel.profileData?.businessProfileRef?.businessTypeRef?.name ?? "")
                        .withComicFont(12, color: .white)
                    WebImage(url: URL(string: viewModel.profileData?.businessProfileRef?.businessTypeRef?.icon ?? ""))
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    
                    
                    if let rating = viewModel.profileData?.businessProfileRef?.rating {
                        if rating > 0 {
                            HStack(spacing: 2) {
                                Text("-")
                                    .foregroundColor(.white.opacity(0.8))
                                Image("RatingStar")
                                    .renderingMode(.template)
                                    .foregroundColor(rating.getStarColor())
                                    .frame(height: 12)
                                
                                Text("\(String(format: "%.1f", rating))")
                            }
                            .font(.custom(Constants.comicFont, size: 12))
                            .foregroundColor(rating.getStarColor())
                        }
                    }
                }
                
                
                Text(viewModel.toShowAddressString)
                    .withComicFont(11, color: .white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.hmIndigo03_hmIndigo)
                
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmIndigo.opacity(0.5))
            }
        )
    }
    
    
    private var fromDateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Check-in".localized(localizationManager.language))
            HStack(spacing: 0) {
                Image("CalendarIcon")
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                Text(viewModel.fromDateString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 46)
            .background(
                ZStack {
                    CapsuleBackground(height: 46, borderColor: viewModel.selectedFromDate != nil ? .hmIndigo : .hmDarkerGray, backgroundColor: themeManager.currentTheme.darkGray05_white)
                }
            )
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var toDateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Check-out".localized(localizationManager.language))
            HStack(spacing: 0) {
                Image("CalendarIcon")
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                Text(viewModel.toDateString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 46)
            .background(
                ZStack {
                    CapsuleBackground(height: 46, borderColor: viewModel.selectedToDate != nil ? .hmIndigo : .hmDarkerGray, backgroundColor: themeManager.currentTheme.darkGray05_white)
                }
            )
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var fromPickerView: some View {
        DatePicker(
            "",
            selection: $viewModel.pickerFromDate,
            in: viewModel.fromDateRange,
            displayedComponents: [
                .date
            ]
        )
        .datePickerStyle(.graphical)
        .padding()
        .padding(.top)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.currentTheme.darkGray_white)
        )
        .padding()
        .accentColor(.hmIndigo)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "xmark.circle.fill")
                .background(
                    Color.white
                        .frame(width: 14, height: 14)
                )
                .foregroundColor(.hmIndigo)
                .font(.title2)
                .clipShape(
                    Circle()
                )
                .onTapGesture {
                    withAnimation(.bouncy) {
                        viewModel.showFromDatePicker = false
                    }
                }
                .opacity(viewModel.showFromDatePicker ? 1.0 : 0.0)
                .offset(x: -25, y: 25)
        }
    }
    
    
    private var toPickerView: some View {
        DatePicker(
            "",
            selection: $viewModel.pickerToDate,
            in: viewModel.toDateRange,
            displayedComponents: [
                .date
            ]
        )
        .id(viewModel.updateDatePickerBool)
        .datePickerStyle(.graphical)
        .padding()
        .padding(.top)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.currentTheme.darkGray_white)
        )
        .padding()
        .accentColor(.hmIndigo)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "xmark.circle.fill")
                .background(
                    Color.white
                        .frame(width: 14, height: 14)
                )
                .foregroundColor(.hmIndigo)
                .font(.title2)
                .clipShape(
                    Circle()
                )
                .onTapGesture {
                    withAnimation(.bouncy) {
                        viewModel.showToDatePicker = false
                    }
                }
                .opacity(viewModel.showToDatePicker ? 1.0 : 0.0)
                .offset(x: -25, y: 25)
        }
    }
}
