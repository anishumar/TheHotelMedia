//
//  ReportViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 04/12/24.
//

import Foundation


class ReportViewModel: ObservableObject {
    
    let reportID: String
    var reportType: String = "post"
    let localizationManager = LocalizationManager.shared
    var postReasonList: [String] {
        [
            "I just don't like it".localized(localizationManager.language),
            "Bullying or unwanted contact".localized(localizationManager.language),
            "Suicide, self-injury or eating disorders".localized(localizationManager.language),
            "Violence, hate or exploitation".localized(localizationManager.language),
            "Selling or promoting restricted items".localized(localizationManager.language),
            "Nudity or sexual activity".localized(localizationManager.language),
            "Scam, fraud or spam".localized(localizationManager.language),
            "False information".localized(localizationManager.language)
        ]
    }
    
    var userReasonList: [String] {
        [
            "Fake account".localized(localizationManager.language),
            "Impersonation".localized(localizationManager.language),
            "Harassment or bullying".localized(localizationManager.language),
            "Hate speech or symbols".localized(localizationManager.language),
            "Scam or fraud".localized(localizationManager.language),
            "Posting inappropriate content".localized(localizationManager.language),
            "Violating community guidelines".localized(localizationManager.language)
        ]
    }
    
    var commentReasons: [String] {
        [
            "offensive_language".localized(localizationManager.language),
            "spam".localized(localizationManager.language),
            "hate_speech".localized(localizationManager.language),
            "harassment".localized(localizationManager.language),
            "bullying".localized(localizationManager.language),
            "personal_attacks".localized(localizationManager.language),
            "false_information".localized(localizationManager.language),
            "misinformation".localized(localizationManager.language),
            "promoting_violence".localized(localizationManager.language),
            "inappropriate_content".localized(localizationManager.language),
            "self_harm_or_suicide".localized(localizationManager.language),
            "scam_or_fraud".localized(localizationManager.language),
            "irrelevant_content".localized(localizationManager.language),
            "threatening_behavior".localized(localizationManager.language),
            "graphic_content".localized(localizationManager.language)
        ]
    }

    
    var onReport: ((String) -> Void)?
    @Published var dismiss: Bool = false
    
    let dataManager = ReportDataManager()
    
    init(reportID: String, reportType: String = "post", onReport: ((String) -> Void)? = nil) {
        self.reportID = reportID
        self.reportType = reportType
        self.onReport = onReport
        
        print(reportID, reportType)
    }
    
    
}


// MARK: - Networking
extension ReportViewModel {
    func reportUser(id: String, reason: String) {
        guard !id.isEmpty && !reason.isEmpty else { return }
        
        let parameter: [String: Any] = ["reason" : reason]
        
        Task {
            do {
                let result = try await dataManager.reportProfile(id: id, parameters: parameter)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        onReport?(result.message)
                        dismiss = true
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    func reportPost(id: String, reason: String) {
        guard !id.isEmpty && !reason.isEmpty else { return }
        
        let parameter: [String: Any] = ["reason" : reason]
        
        Task {
            do {
                let result = try await dataManager.reportPost(id: id, parameters: parameter)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        onReport?(result.message)
                        dismiss = true
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    
    func reportComment(id: String, reason: String) {
        guard !id.isEmpty && !reason.isEmpty else { return }
        
        let parameter: [String: Any] = ["reason" : reason]
        
        Task {
            do {
                let result = try await dataManager.reportComment(id: id, parameters: parameter)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        onReport?(result.message)
                        dismiss = true
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
