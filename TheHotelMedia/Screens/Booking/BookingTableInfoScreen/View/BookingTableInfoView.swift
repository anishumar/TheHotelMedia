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
    @State private var showMonthPicker = false
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeaderView(title: "Book a table".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    businessInfoCard
                        .padding(.horizontal, 16)
                    
                    dateSelectionSection
                    
                    if !viewModel.slots.isEmpty {
                        timeSlotSection
                            .padding(.horizontal, 16)
                    }
                    
                    guestSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
        .overlay(alignment: .bottom) {
            submitButton
        }
        .overlay {
            if showMonthPicker {
                monthPickerOverlay
            }
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay {
            successOverlay
        }
    }
}


// MARK: - Components
extension BookingTableInfoView {
    
    // MARK: Header Card
    private var businessInfoCard: some View {
        HStack(spacing: 12) {
            BusinessProfilePicView(stringURL: viewModel.profileData.businessProfileRef?.profilePic?.small ?? "", dimension: 50, border: 0)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(viewModel.profileData.businessProfileRef?.name ?? "")
                        .withComicFont(18, color: .white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(viewModel.profileData.businessProfileRef?.businessTypeRef?.name ?? "Restaurant")
                            .withComicFont(12, color: .white.opacity(0.7))
                        
                        WebImage(url: URL(string: viewModel.profileData.businessProfileRef?.businessTypeRef?.icon ?? ""))
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white.opacity(0.7))
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                }
                
                Text(viewModel.toShowAddressString)
                    .withComicFont(12, color: .white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "2E3A59")) // Dark Blue card background
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: Date Selection
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Date")
                    .withComicFont(16, color: .white)
                
                Spacer()
                
                Button {
                    withAnimation {
                        showMonthPicker.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(monthYearString(viewModel.currentMonthDate))
                            .withComicFont(14, color: .white.opacity(0.8))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.daysInMonth, id: \.self) { date in
                        dayCell(date: date)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func dayCell(date: Date) -> some View {
        let isSelected = viewModel.isSelectedDate(date)
        let isToday = Calendar.current.isDateInToday(date)
        
        return VStack(spacing: 6) {
            Text(date.dayName().uppercased())
                .withComicFont(10, color: isSelected ? .white : .white.opacity(0.4))
            
            Text("\(Calendar.current.component(.day, from: date))")
                .withComicFont(16, color: isSelected ? .black : .white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? .white : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(isToday && !isSelected ? .hmIndigo : Color.clear, lineWidth: 1)
                        )
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Color.hmIndigo : Color(hex: "1C1C1E"))
        )
        .onTapGesture {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            viewModel.selectedDate = formatter.string(from: date)
        }
    }
    
    // MARK: Time Slots
    private var timeSlotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time slot")
                .withComicFont(16, color: .white)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.slots) { slot in
                    Text(slot.time)
                        .withComicFont(14, color: .white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedSlot?.id == slot.id ? Color.black : Color(hex: "1C1C1E"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.selectedSlot?.id == slot.id ? Color.white : Color.clear, lineWidth: 1)
                                )
                        )
                        .onTapGesture {
                            viewModel.selectedSlot = slot
                        }
                }
            }
        }
    }
    
    // MARK: Guest Section
    private var guestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guest")
                .withComicFont(16, color: .white)
            
            HStack {
                Text("Number of guest")
                    .withComicFont(14, color: .white.opacity(0.7))
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        if viewModel.guestCount > 1 { viewModel.guestCount -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.hmIndigo.opacity(0.6)))
                    }
                    
                    Text("\(viewModel.guestCount)")
                        .withComicFont(16, color: .white)
                        .frame(minWidth: 20)
                    
                    Button {
                        if viewModel.guestCount < 100 { viewModel.guestCount += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.hmIndigo))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1C1C1E"))
            )
        }
    }
    
    // MARK: Submit Button
    private var submitButton: some View {
        Button {
            viewModel.bookTable()
        } label: {
            Text("Submit")
                .withComicFont(16, color: .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.hmIndigo)
                )
        }
        .padding(16)
        .background(
            LinearGradient(colors: [themeManager.currentTheme.backgroundColor.opacity(0), themeManager.currentTheme.backgroundColor], startPoint: .top, endPoint: .bottom)
        )
    }
    
    // MARK: Month Picker Overlay
    private var monthPickerOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showMonthPicker = false } }
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { viewModel.changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(monthYearString(viewModel.currentMonthDate))
                        .withComicFont(16, color: .white)
                    
                    Spacer()
                    
                    Button(action: { viewModel.changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(.vertical, 8)
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(12)
                .padding(.top, 120) // Adjust based on header position
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: Success Overlay
    private var successOverlay: some View {
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
    }
    
    // MARK: Helpers
    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

extension Date {
    func dayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
