//
//  BookingHistoryView.swift
//  TheHotelMedia
//
//  Created by MAC on 04/03/25.
//

import SwiftUI

struct BookingHistoryView: View {
    
    @StateObject var viewModel: BookingHistoryViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let horizontalPadding: CGFloat = 12
    
    var body: some View {
        VStack(spacing: 12) {
            CustomHeaderView(title: "Booking History".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
//            .padding(.bottom, 4)
            .background(themeManager.currentTheme.backgroundColor)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.historyData) { booking in
                        if let index = viewModel.historyData.firstIndex(where: {$0.id == booking.id}) {
                            historyRowView(booking: booking)
                                .onTapGesture {
                                    if booking.type == "book-banquet" {
                                        viewModel.showTableSummaryScreen(id: booking.id ?? "")
                                        
                                    } else if booking.type == "book-table" {
                                        viewModel.showTableSummaryScreen(id: booking.id ?? "")
                                        
                                    } else {
                                        viewModel.showSummaryScreen(id: booking.id ?? "")
                                    }
                                }
                                .onAppear {
                                    if viewModel.historyData.count - 1 <= index {
                                        guard viewModel.pageNo < viewModel.totalPages else { return }
                                        
                                        viewModel.pageNo += 1
                                        viewModel.getHistoryData(pageNo: viewModel.pageNo)
                                    }
                                }
                        }
                        
                    }
                }
            }
            .overlay {
                VStack {
                    if viewModel.historyData.isEmpty, !viewModel.showLoadingIndicator {
                        EmptyScreenView(image: "Booking-History", title: "No booking history".localized(localizationManager.language), height: UIScreen.main.bounds.height)
                    }
                }
                .allowsHitTesting(false)
            }
            .clipped()
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor)
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .onAppear {
            if viewModel.refreshData {
                viewModel.getHistoryData(pageNo: 1)
            }
            viewModel.refreshData = false
        }
    }
}


// MARK: - Helper Functions
extension BookingHistoryView {
    func getAmountString(double: Double, format: String = "%.0f") -> String {
        String(format: format, double)
    }
}


// MARK: - Components
extension BookingHistoryView {
    
    private func historyRowView(booking: BookingHistory) -> some View {
        let paddingH: CGFloat = 8
        let paddingV: CGFloat = 5
        let paddingBorder: CGFloat = 2
        
        return VStack {
            HStack(alignment: .top, spacing: 12) {
                ImageLoaderView(urlString: booking.businessProfileRef?.profilePic?.small ?? "")
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.businessProfileRef?.name ?? "")
                        .withComicFont(16, color: themeManager.currentTheme.label)
                    
                    if let businessProfileRef = booking.businessProfileRef,
                       let address = businessProfileRef.address,
                       let street = address.street,
                       let city = address.city,
                       let state = address.state,
                       let zipCode = address.zipCode,
                       let country = address.country {
                        
                        Text("\(street), \(city), \(state), \(zipCode), \(country)")
                            .withComicFont(11, color: themeManager.currentTheme.white04_darkGray04)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    
                }
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            let internalPadding: CGFloat = 6.5
            HStack(spacing: 0) {
                let maxWidth = Constants.screenWidth - horizontalPadding - (paddingH * 2) - (paddingBorder * 2) - 2 - (internalPadding * 2)
                
                let roomType = booking.roomsRef?.roomType ?? ""
                let adults = booking.adults ?? 0
                
                if booking.type == "book-banquet" {
                    Text("\(adults) \(adults > 1 ? "Guests" : "Guest")")
                        .padding(.horizontal, 3)
                        .frame(maxWidth: maxWidth * 0.3)
                    
                } else if booking.type == "book-table" {
                    Text("\(adults) \(adults > 1 ? "Guests" : "Guest")")
                        .padding(.horizontal, 3)
                        .frame(maxWidth: maxWidth * 0.3)
                    
                } else {
                    Text("\(booking.bookedRoom?.quantity ?? 1) * \(roomType.capitalized) \("Room".localized(localizationManager.language))")
                        .padding(.horizontal, 3)
                        .frame(maxWidth: maxWidth * 0.3, alignment: .leading)
                    
                }
                
                Rectangle()
                    .fill(themeManager.currentTheme.white06_darkGray06)
                    .frame(width: 1)
                
                if booking.type == "book-banquet" {
                    Text(booking.metadata?.typeOfEvent ?? "")
                        .padding(.horizontal, 3)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: maxWidth * 0.4)
                    
                } else if booking.type == "book-table" {
                    Text("Table Booking")
                        .padding(.horizontal, 3)
                        .frame(maxWidth: maxWidth * 0.4)
                    
                } else {
                    let nights = booking.bookedRoom?.nights ?? 1
                    Text(nights <= 1 ? "\(nights) * \("Night".localized(localizationManager.language))" : "\(nights) * \("Nights".localized(localizationManager.language))")
                        .frame(maxWidth: maxWidth * 0.4)
                    
                }
                
                Rectangle()
                    .fill(themeManager.currentTheme.white06_darkGray06)
                    .frame(width: 1)
                
                Text("₹" + getAmountString(double: booking.grandTotal ?? 0))
                    .padding(.horizontal, 3)
                    .frame(maxWidth: maxWidth * 0.3, alignment: .trailing)
            }
            .lineLimit(1)
            .withComicFont(11, color: themeManager.currentTheme.label)
            .padding(internalPadding)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.currentTheme.darkGray06_darkGray008)
            )
            
            HStack {
                Text("Booked on ".localized(localizationManager.language) + (DateManager.formatISODateToBookedOn(from: booking.createdAt ?? "") ?? ""))
                    .withComicFont(11, color: themeManager.currentTheme.white04_darkGray04)
                
                Spacer()
                
                let status = booking.status ?? ""
                let canCancel: Bool = {
                    let lower = status.lowercased()
                    let type = (booking.type ?? "").lowercased()
                    guard type != "book-table", type != "book-banquet" else { return false }
                    // Allow cancel only for cancellable states; server enforces 24h rule anyway.
                    guard lower.contains("pending") || lower.contains("confirmed") else { return false }
                    guard !lower.contains("cancel") else { return false }
                    return true
                }()
                
                HStack(spacing: 8) {
                    if canCancel, let bookingID = booking.id {
                        Button {
                            viewModel.showCancelBookingModal(id: bookingID)
                        } label: {
                            Text("Cancel")
                                .withComicFont(11, color: .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.hmRed)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(status.capitalized)
                        .withComicFont(11, color: .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(updateBookingStatusColor(status: status.lowercased()))
                        )
                }
            }
            
        }
        .padding(.horizontal, paddingH)
        .padding(.vertical, paddingV)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.black09_white)
        )
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
        )
    }
    
}

