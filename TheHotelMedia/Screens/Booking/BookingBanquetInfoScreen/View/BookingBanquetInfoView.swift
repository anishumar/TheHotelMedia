//
//  BookingBanquetInfoView.swift
//  TheHotelMedia
//
//  Created by MAC on 26/03/25.
//

import SwiftUI
import SDWebImageSwiftUI
import Lottie

struct BookingBanquetInfoView: View {
    
    @StateObject var viewModel: BookingBanquetInfoViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            CustomHeaderView(title: "Book a Banquet".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    businessHeaderView
                    VStack(alignment: .leading ) {
                        Text("Type of Event".localized(localizationManager.language))
                            .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                        
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                            ForEach(viewModel.eventTypes, id: \.self) { type in
                                HStack {
//                                    ZStack {
//                                        Circle()
//                                            .fill(themeManager.currentTheme.darkGray06_darkGray008)
//                                        Circle()
//                                            .stroke(lineWidth: 1)
//                                            .fill(themeManager.currentTheme.mediumGray_mediumGray03)
//                                        Circle()
//                                            .fill(viewModel.selectedType == type ? .hmIndigo : .clear)
//                                    }
//                                    .frame(width: 18, height: 18)
                                    
                                    Image(systemName: viewModel.selectedType == type ? "checkmark.circle.fill" : "checkmark.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.hmIndigo)
                                        .frame(width: 18, height: 18)
                                    
                                    Text(type)
                                        .withComicFont(12, color: themeManager.currentTheme.white06_darkGray06)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onTapGesture {
                                    viewModel.selectedType = type
                                }
                            }
                        }
                        .padding(8)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(themeManager.currentTheme.darkGray06_white)
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(lineWidth: 1)
                                    .fill(.hmDarkerGray)
                            }
                        }
                        
                        if viewModel.selectedType == "Other Occasion" {
                            GrayTextField(textfieldText: $viewModel.otherOccasionFieldText, title: "Other Occasion".localized(localizationManager.language), placeholder: "Other Occasion".localized(localizationManager.language), leftIcon: "", rightIcon: .constant(nil))
                        }
                        
                    }
                    
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
                    
                    DropDownMenuView(viewModel: DropDownMenuViewModel(model: DropDownModel(id: "no-of-guests", answer: ["0 - 50", "51 - 100", "101 - 200", "201 - 500", "500+"], question: "Number of Guests".localized(localizationManager.language), selectedAnswer: nil)), selectedFontSize: 14, optionFontSize: 14) { range in
                        viewModel.selectedGuestCountRange = range
                    }
                    
                    Spacer(minLength: 400)
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            Button {
                viewModel.bookBanquet()
            } label: {
                Text("Submit".localized(localizationManager.language))
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
        .overlay {
            ZStack {
                CustomDatePickerView(isActive: $viewModel.showFromDatePicker, selectedDate: $viewModel.pickerFromDate, dateRange: $viewModel.fromDateRange) { date in
                    viewModel.selectedFromDate = date
                }
                
                CustomDatePickerView(isActive: $viewModel.showToDatePicker, selectedDate: $viewModel.pickerToDate, dateRange: $viewModel.toDateRange) { date in
                    viewModel.selectedToDate = date
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay(content: {
            ZStack {
                if viewModel.isBookingSuccessful {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        LottieView(animation: .named("Animation-Uploaded"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                            .animationDidFinish { completed in
                                viewModel.isBookingSuccessful = false
                                viewModel.dismissScreen()
                            }
                            .scaleEffect(1.5)
                        Spacer()
                        Text(viewModel.successMessage)
                            .withComicFont(12, color: .white)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 8)
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
            }
        })
    }
}


// MARK: - Components
extension BookingBanquetInfoView {
    private var businessHeaderView: some View {
        HStack(spacing: 15) {
            BusinessProfilePicView(stringURL: viewModel.profileData.businessProfileRef?.profilePic?.small ?? "", dimension: 41, border: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(viewModel.profileData.businessProfileRef?.name ?? "")
                        .withComicFont(16, color: .white)
                    
                    Spacer()
                    
                    Text(viewModel.profileData.businessProfileRef?.businessTypeRef?.name ?? "")
                        .withComicFont(12, color: .white)
                    WebImage(url: URL(string: viewModel.profileData.businessProfileRef?.businessTypeRef?.icon ?? ""))
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    
                    
                    if let rating = viewModel.profileData.businessProfileRef?.rating {
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
        VStack {
            DatePicker(
                "",
                selection: $viewModel.pickerFromDate,
                in: viewModel.fromDateRange,
                displayedComponents: [
                    .date
                ]
            )
            .datePickerStyle(.graphical)
            HStack {
                Button("Cancel") {
                    withAnimation(.bouncy) {
                        viewModel.showFromDatePicker = false
                    }
                }
                .buttonStyle(.bordered)
                Button("OK") {
                    withAnimation(.bouncy) {
                        viewModel.showFromDatePicker = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        
        .padding()
//        .padding(.bottom)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.currentTheme.darkGray_white)
        )
        .padding()
        .accentColor(.hmIndigo)
//        .overlay(alignment: .topTrailing) {
//            Image(systemName: "xmark.circle.fill")
//                .background(
//                    Color.white
//                        .frame(width: 14, height: 14)
//                )
//                .foregroundColor(.hmIndigo)
//                .font(.title2)
//                .clipShape(
//                    Circle()
//                )
//                .onTapGesture {
//                    withAnimation(.bouncy) {
//                        viewModel.showFromDatePicker = false
//                    }
//                }
//                .opacity(viewModel.showFromDatePicker ? 1.0 : 0.0)
//                .offset(x: -25, y: 25)
//        }
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
