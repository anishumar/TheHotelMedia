//
//  JobDetailViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import Foundation
import Combine
import SwiftfulRouting


class JobDetailViewModel: ObservableObject {
    
    let router: AnyRouter
    let jobID: String
    let dataManager = JobDetailDataManager()
    @Published var jobdata: JobData? = nil
    @Published var showLoadingIndicator: Bool = false
    
    init(router: AnyRouter, jobID: String) {
        self.router = router
        self.jobID = jobID
        getJobDetail(id: jobID)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func applyForJob() {
        if let username = jobdata?.postedBy?.username,
           let name = jobdata?.postedBy?.name,
           let id = jobdata?.postedBy?.id {
            router.showScreen(.push) { router in
                ChatView(viewModel: ChatViewModel(router: router, username: username, userID: id, profilePic: self.jobdata?.postedBy?.businessProfileRef?.profilePic?.small ?? "", name: name, lastScreen: "job-post", message: "Hi, I'd like to apply for the job you shared. Let me know the next steps!".localized(LocalizationManager.shared.language), openKeyboard: true)) { returnedUsername in
                    SocketIOViewModel.shared.leavePrivateChatEmit(user: returnedUsername)
                }
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()

            }
        }
        
    }
}


// MARK: - Networking
extension JobDetailViewModel {
    
    func getJobDetail(id: String) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.getJobDetailData(jobID: id)
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            jobdata = data
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
}
