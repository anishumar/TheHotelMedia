//
//  RoomListViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import Foundation
import Combine
import SwiftfulRouting


class RoomListViewModel: ObservableObject {
    
    let router: AnyRouter
    let profileData: ProfileData
    let bookingDetail: BookingDetail
    let checkInData: CheckInData
    var isPresentedAsSheet: Bool
    let dataManager = RoomListDataManager()
    
    @Published var rooms: [ListRoom] = []
    @Published var showLoadingindicator: Bool = false
    
    init(router: AnyRouter, profileData: ProfileData, bookingDetail: BookingDetail, checkInData: CheckInData, isPresentedAsSheet: Bool = false) {
        self.router = router
        self.profileData = profileData
        self.bookingDetail = bookingDetail
        self.checkInData = checkInData
        self.isPresentedAsSheet = isPresentedAsSheet
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showRoomDetailScreen(id: String, price: Double) {
        router.showScreen(.push) { router in
            RoomDetailView(viewModel: RoomDetailViewModel(router: router, profileData: self.profileData, bookingDetail: self.bookingDetail, checkInData: self.checkInData, roomID: id, isPresentedAsSheet: self.isPresentedAsSheet, roomPricePerNight: price))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}


// MARK: - Networking
extension RoomListViewModel {
    func getAllRooms() {
        
        showLoadingindicator = true
        Task {
            do {
                let result = try await dataManager.getRoomList()
                let range = 200...204
                await MainActor.run {
                    showLoadingindicator = false
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            rooms = data
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingindicator = false
                }
            }
        }
    }
}
