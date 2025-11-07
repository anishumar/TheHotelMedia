//
//  BookingTableInfoView.swift
//  TheHotelMedia
//
//  Created by MAC on 11/03/25.
//

import SwiftUI
import SDWebImageSwiftUI
import SSDateTimePicker
import Lottie

struct BookingTableInfoView: View {
    
    @StateObject var viewModel: BookingTableInfoViewModel
    @StateObject var bookingCalendarViewModel = BookingCalenderViewModel(calendarType: .days)
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State var selectedCalendarType: CalendarType = .week
    @Namespace var namespace
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    let rows: [GridItem] = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    
    
    var body: some View {
        VStack(spacing: 12) {
            CustomHeaderView(title: "Book a table".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            .padding(.horizontal, 12)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    businessHeaderView
                        .padding(.horizontal, 12)
                    
                    BookingCalenderView(viewModel: bookingCalendarViewModel, calendarType: $selectedCalendarType) { date in
                        viewModel.selectedDate = date
                        print(date)
                    } onTapPastDay: {
                        ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "You cannot select a past date.")
                    }
                    
                    if !viewModel.slots.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Time slot".localized(localizationManager.language))
                                .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack {
                                    if viewModel.slotCount < 4 {
                                        HStack {
                                            ForEach(viewModel.slots) { slot in
                                                slotView(slot: slot)
                                            }
                                        }
                                    } else if viewModel.slotCount <= 12 {
                                        LazyVGrid(columns: columns, spacing: 8) {
                                            ForEach(viewModel.slots) { slot in
                                                slotView(slot: slot)
                                            }
                                        }
                                    } else {
                                        LazyHGrid(rows: rows, spacing: 8) {
                                            ForEach(viewModel.slots) { slot in
                                                slotView(slot: slot)
                                            }
                                        }
                                    }
                                }
                                .padding(8)
    //                            .background(themeManager.currentTheme.darkGray06_darkGray008)
                            }
                            .background(themeManager.currentTheme.darkGray06_darkGray008)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                    }
                    
                    
                    VStack(alignment: .leading) {
                        Text("guest".localized(localizationManager.language))
                            .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                        
                        CustomCounterView(count: $viewModel.guestCount, title: "Number of guest".localized(localizationManager.language), backgroundColor: themeManager.currentTheme.darkGray06_darkGray008, allowBorder: false, minCount: 1, maxCount: 1000)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    
                }
            }
            .overlay(alignment: .bottom) {
                Button {
                    viewModel.bookTable()
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor)
        .overlay {
            SSTimePicker(showTimePicker: $viewModel.showTimePicker)
                .selectedTime(viewModel.selectedTime)
                .themeColor(pickerBackgroundColor: themeManager.currentTheme.darkGray_white, primaryColor: .hmIndigo, timeLabelBackgroundColor: .hmIndigo.opacity(0.3))
                .clockNumberStyle(color: themeManager.currentTheme.label)
                .onTimeSelection { time in
                    viewModel.selectedTime = time
                }
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
extension BookingTableInfoView {
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
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    
                    
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
    
    
    private var selectTimeSection: some View {
        VStack(alignment: .leading) {
            Text("Enter Time")
                .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
            
            let width = Constants.screenWidth * 0.26
            let height = width * 0.66
            HStack(alignment: .top) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(themeManager.currentTheme.backgroundColor)
                            Text(viewModel.hour < 10 ? "0\(viewModel.hour)" : "\(viewModel.hour)")
                        }
                        .frame(width: width, height: height)
                        Text("Hour")
                            .withComicFont(10, color: themeManager.currentTheme.white06_darkGray06)
                    }
                    .frame(width: width)
                    
                    
                    VStack(spacing: 6) {
                        Circle()
                            .fill(themeManager.currentTheme.backgroundColor)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(themeManager.currentTheme.backgroundColor)
                            .frame(width: 8, height: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(themeManager.currentTheme.backgroundColor)
                            Text(viewModel.minutes < 10 ? "0\(viewModel.minutes)" : "\(viewModel.minutes)")
                        }
                        .frame(width: width, height: height)
                        Text("Minute")
                            .withComicFont(10, color: themeManager.currentTheme.white06_darkGray06)
                    }
                    .frame(width: width)
                }
                .withComicFont(24, color: themeManager.currentTheme.label)
                
                Spacer()
                
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 1, height: height)
                
                Spacer()
                
                VStack(spacing: 0) {
                    ZStack {
                        if viewModel.currentPeriod == "AM" {
                            Rectangle()
//                                    .fill(viewModel.currentPeriod == "AM" ? .hmIndigo : themeManager.currentTheme.backgroundColor)
                                .fill(.hmIndigo)
                                .matchedGeometryEffect(id: "period", in: namespace)
                        }
                        Text("AM")
                            .withComicFont(14, color: viewModel.currentPeriod == "AM" ? .white : themeManager.currentTheme.white06_darkGray06)
                    }
                    .frame(width: width/2)
                    .frame(maxHeight: .infinity)
                    .onTapGesture {
                        viewModel.currentPeriod = "AM"
                    }
                    
                    ZStack {
                        if viewModel.currentPeriod == "PM" {
                            Rectangle()
//                                    .fill(viewModel.currentPeriod == "AM" ? .hmIndigo : themeManager.currentTheme.backgroundColor)
                                .fill(.hmIndigo)
                                .matchedGeometryEffect(id: "period", in: namespace)
                        }
                        Text("PM")
                            .withComicFont(14, color: viewModel.currentPeriod == "PM" ? .white : themeManager.currentTheme.white06_darkGray06)
                    }
                    .frame(width: width/2)
                    .frame(maxHeight: .infinity)
                    .onTapGesture {
                        viewModel.currentPeriod = "PM"
                    }
                }
                .frame(height: height)
                .background(themeManager.currentTheme.backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .animation(.bouncy, value: viewModel.currentPeriod)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.currentTheme.darkGray06_darkGray008)
            )
            .onTapGesture {
                withAnimation(.easeInOut) {
                    viewModel.showTimePicker.toggle()
                }
            }
        }
    }
    
    
    private func slotView(slot: Slot) -> some View {
        Text(slot.time)
            .minimumScaleFactor(0.9)
            .lineLimit(1)
            .withComicFont(14, color: viewModel.selectedSlot?.id == slot.id ? .white : themeManager.currentTheme.label)
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(viewModel.selectedSlot?.id == slot.id ? themeManager.currentTheme.hmIndigo07_hmIndigo : themeManager.currentTheme.backgroundColor)
            )
            .onTapGesture {
                viewModel.selectedSlot = slot
            }
    }
}
