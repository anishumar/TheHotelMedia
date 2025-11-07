//
//  TableSummaryView.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct TableSummaryView: View {
    
    @StateObject var viewModel: TableSummaryViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @AppStorage("isIndividual") var isIndividual: Bool = false
    
    var body: some View {
        VStack {
            CustomHeaderView(title: "Booking Summary".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            .background(themeManager.currentTheme.backgroundColor)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    if let status = viewModel.bookingSummary?.status, status != "pending" {
                        HStack {
                            if status != "confirmed" {
                                Image("Cancel")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                            Text(status.capitalized)
                                .withComicFont(16, color: .white)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(status == "confirmed" ? .hmGreen : .hmRed)
                        )
                    }
                    
                    businessHeaderView
                    bookingDetailSection
                    if let type = viewModel.bookingSummary?.type {
                        if type == "book-table" {
                            tableDetailSection
                        } else if type == "book-banquet" {
                            banquetDetailSection
                        }
                    }
                   
                }
            }
            .overlay(alignment: .bottom) {
                HStack {
                    if viewModel.showButtons && !isIndividual && viewModel.bookingSummary?.status == "pending" {
                        Button {
                            viewModel.bookingAction(isAccepted: false)
                        } label: {
                            Text("reject".localized(localizationManager.language))
                                .withComicFont(14, color: .white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Capsule()
                                        .fill(.hmRed)
                                )
                        }
                        
                        Button {
                            viewModel.bookingAction(isAccepted: true)
                        } label: {
                            Text("accept".localized(localizationManager.language))
                                .withComicFont(14, color: .white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Capsule()
                                        .fill(.hmIndigo)
                                )
                        }
                    }
                }
                .padding(.bottom, UIApplication.bottomSafeAreaHeightTHM > 0 ? UIApplication.bottomSafeAreaHeightTHM : 10)
            }
        }
        .padding(.horizontal, 12)
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}


// MARK: - Functions
extension TableSummaryView {
    func getEventIconName(for occasion: String) -> String {
        switch occasion {
        case "Birthday Party": return "birthday_party"
        case "Wedding Ceremony": return "wedding_ceremony"
        case "Anniversary Celebration": return "anniversary_celebration"
        case "Corporate Event": return "corporate_event"
        case "Baby Shower": return "baby_shower"
        case "Engagement Party": return "engagement_party"
        case "Farewell Party": return "farewell_party"
        case "Reunion": return "reunion"
        case "Festival Celebration": return "festival_celebration"
        case "Charity Event": return "charity_event"
        case "Other Occasion": return "other_occasion"
        case "Breakfast": return "ic_breakfast"
        case "Lunch": return "ic_lunch"
        case "Dinner": return "ic_dinner"
        default: return "other_occasion"
        }
    }
}


// MARK: - Components
extension TableSummaryView {
    private var businessHeaderView: some View {
        HStack(spacing: 15) {
            BusinessProfilePicView(stringURL: viewModel.bookingSummary?.businessProfileRef?.profilePic?.small ?? "", dimension: 41, border: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(viewModel.bookingSummary?.businessProfileRef?.name ?? "")
                        .withComicFont(16, color: .white)
                    
                    Spacer()
                    
                    Text(viewModel.bookingSummary?.businessProfileRef?.businessTypeRef?.name ?? "")
                        .withComicFont(12, color: .white)
                    WebImage(url: URL(string: viewModel.bookingSummary?.businessProfileRef?.businessTypeRef?.icon ?? ""))
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    
                    let rating: Double? = viewModel.bookingSummary?.businessProfileRef?.rating
                    if let rating = rating {
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
                
                if let businessProfileRef = viewModel.bookingSummary?.businessProfileRef,
                   let address = businessProfileRef.address,
                   let street = address.street,
                   let city = address.city,
                   let state = address.state,
                   let zipCode = address.zipCode,
                   let country = address.country {
                    
                    Text("\(street), \(city), \(state), \(zipCode), \(country)")
                        .withComicFont(11, color: .white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
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
    
    
    private var bookingDetailSection: some View {
        VStack (spacing: 10){
            headerTitleView(icon: "Guest-Detail", title: "Booking Details".localized(localizationManager.language))
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 12) {
                
                if let user = viewModel.bookingSummary?.usersRef,
                   let email = user.email,
                   let name = user.name,
                   let dialCode = user.dialCode,
                   let phoneNumber = user.phoneNumber {
                    detailLineView(title: "Name".localized(localizationManager.language), value: name)
                    detailLineView(title: "Email".localized(localizationManager.language), value: email)
                    detailLineView(title: "Phone Number".localized(localizationManager.language), value: "\(dialCode) \(phoneNumber)")
                }
               
                detailLineView(title: "Booking Date".localized(localizationManager.language), value: (DateManager.formatISODateToTableBookedOn( viewModel.bookingSummary?.createdAt ?? "") ?? ""))
                
                if viewModel.bookingSummary?.type == "book-banquet" {
                    detailLineView(title: "Number of guests".localized(localizationManager.language), value: "\(viewModel.bookingSummary?.adults ?? 0)")
                }
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
        }
    }
    
    
    private func headerTitleView(icon: String, title: String) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            Text(title)
                .withComicFont(16, color: themeManager.currentTheme.white_darkGray)
        }
    }
    
    
    private func detailLineView(title: String, value: String, addColon: Bool = true) -> some View {
        HStack {
            Text(addColon ? title + ":" : title)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .withComicFont(13, color: themeManager.currentTheme.white_darkGray)
    }
    
    
    private var roundedBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.darkGray06_darkGray008)
            RoundedRectangle(cornerRadius: 14)
                .stroke(lineWidth: 1)
                .fill(.hmDarkerGray)
        }
    }
    
    
    private var tableDetailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerTitleView(icon: "Table", title: "Table Booking Details".localized(localizationManager.language))
            
            if let mealType = DateManager.mealType(from: viewModel.bookingSummary?.checkIn ?? "") {
                iconDetailView(title: mealType, icon: mealType)
                    .padding(2)
            }
            
            VStack {
                detailLineView(title: "Booking For".localized(localizationManager.language), value: DateManager.formatISODateAsIs(viewModel.bookingSummary?.checkIn ?? "") ?? "")
                detailLineView(title: "Number of guests".localized(localizationManager.language), value: "\(viewModel.bookingSummary?.adults ?? 0)")
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
        }
    }
    
    
    private var banquetDetailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerTitleView(icon: "Calendar-Blue", title: "Type of Event".localized(localizationManager.language))
            
            if let eventType = viewModel.bookingSummary?.metadata?.typeOfEvent {
                iconDetailView(title: eventType, icon: getEventIconName(for: eventType))
                    .padding(2)
            }
            
            HStack {
                checkInTimeView(title: "Check-in".localized(localizationManager.language), icon: "Open-Door", value: (DateManager.convertISOToDateAndMonth(from: viewModel.bookingSummary?.checkIn ?? "") ?? ""))
                Spacer()
                checkInTimeView(title: "Check-out".localized(localizationManager.language), icon: "Open-Door", value: (DateManager.convertISOToDateAndMonth(from: viewModel.bookingSummary?.checkOut ?? "") ?? ""))
            }
            .padding(10)
            .background(roundedBackground)
            .padding(2)
        }
    }
    
    
    private func iconDetailView(title: String, icon: String) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(6)
                .background(
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.darkGray06_darkGray008)
                        Circle()
                            .stroke(lineWidth: 1)
                            .fill(.hmDarkerGray)
                    }
                )
            
            Text(title)
                .withComicFont(16, color: themeManager.currentTheme.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray06_white)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            }
        )
    }
    
    
    private func checkInTimeView(title: String, icon: String, value: String) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding(4)
                .background(
                    Circle()
                        .fill(.mediumBlue)
                )
                .padding(5)
                .background(
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.darkGray06_white)
                        if themeManager.darkThemeActive {
                            Circle()
                                .stroke(lineWidth: 1)
                                .fill(.hmDarkerGray)
                            
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .withComicFont(14, color: themeManager.currentTheme.white08_darkGray08)
                
                Text(value)
                    .withComicFont(14, color: themeManager.currentTheme.hmIndigo_hmIndigo05)
            }
        }
    }
}
