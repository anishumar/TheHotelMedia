//
//  CreateJobPostViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import Combine
import SwiftfulRouting
import Foundation


class CreateJobPostViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = JobDataManager()
    @Published var titleFieldText: String = ""
    @Published var descriptionFieldText: String = ""
    @Published var selectedJoiningDate: Date = Date()
    @Published var showJoiningDatePicker: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var bottomSpacing: CGFloat = 0
    @Published var bottomSpacing2: CGFloat = 0
    @Published var successMessage: String = ""
    @Published var isBookingSuccessful: Bool = false
    let localizationManager = LocalizationManager.shared
    
    @Published var fromDateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        
        if let year = dateComponents.year,
           let month = dateComponents.month,
           let day = dateComponents.day,
           let hour = dateComponents.hour,
           let minute = dateComponents.minute,
           let second = dateComponents.second {
            
            
            let endComponents = DateComponents(year: year, month: month + 6, day: day, hour: hour, minute: minute, second: second)
            return Date()
            ...
            calendar.date(from:endComponents)!
        }
        
        return Date()...Date()
    }()
    
    var designationModel: DropDownModel2 {
        return DropDownModel2(
            id: UUID().uuidString,
            answer: [
                AnswerModel(option: "Hotel Manager", icon: ""),
                AnswerModel(option: "Front Desk Receptionist", icon: ""),
                AnswerModel(option: "Housekeeping Supervisor", icon: ""),
                AnswerModel(option: "Chef", icon: ""),
                AnswerModel(option: "Sous Chef", icon: ""),
                AnswerModel(option: "Bartender", icon: ""),
                AnswerModel(option: "Waiter/Waitress", icon: ""),
                AnswerModel(option: "Concierge", icon: ""),
                AnswerModel(option: "Event Coordinator", icon: ""),
                AnswerModel(option: "Hotel Accountant", icon: "")
            ],
            question: "Designation".localized(localizationManager.language)
        )
    }
    
    var jobTypeModel: DropDownModel2 {
        return DropDownModel2(
            id: UUID().uuidString,
            answer: [
                AnswerModel(option: "Full Time", icon: ""),
                AnswerModel(option: "Part Time", icon: ""),
                AnswerModel(option: "Internship", icon: ""),
                AnswerModel(option: "Freelance", icon: ""),
                AnswerModel(option: "Temporary", icon: ""),
                AnswerModel(option: "Volunteer", icon: "")
    //            AnswerModel(option: "Other", icon: "")
            ],
            question: "Job Type".localized(localizationManager.language)
        )
    }
    
    var experienceModel: DropDownModel2 {
        return DropDownModel2(
            id: UUID().uuidString,
            answer: [
                AnswerModel(option: "Entry Level", icon: ""),
                AnswerModel(option: "1-3 Years", icon: ""),
                AnswerModel(option: "3-5 Years", icon: ""),
                AnswerModel(option: "5-10 Years", icon: ""),
                AnswerModel(option: "10+ Years", icon: "")
            ],
            question: "Experience".localized(localizationManager.language)
        )
    }
    
    var salaryModel: DropDownModel2 {
        return DropDownModel2(
            id: UUID().uuidString,
            answer: [
                AnswerModel(option: "15,000 - 25,000", icon: ""),
                AnswerModel(option: "25,000 - 35,000", icon: ""),
                AnswerModel(option: "35,000 - 50,000", icon: ""),
                AnswerModel(option: "50,000 - 75,000", icon: ""),
                AnswerModel(option: "75,000+", icon: "")
            ],
            question: "Salary Offer".localized(localizationManager.language)
        )
    }
    
    var vacancyModel: DropDownModel2 {
        return DropDownModel2(
            id: UUID().uuidString,
            answer: [
                AnswerModel(option: "1 Vacancy", icon: ""),
                AnswerModel(option: "2-3 Vacancy", icon: ""),
                AnswerModel(option: "4-5 Vacancy", icon: ""),
                AnswerModel(option: "6+ Vacancy", icon: ""),
                AnswerModel(option: "Multiple Openings", icon: "")
            ],
            question: "Number of Vacancies".localized(localizationManager.language)
        )
    }
    
    var selectedDesignation: String = ""
    var selectedJobType: String = ""
    var selectedExperience: String = ""
    var selectedSalary: String = ""
    var selectedVacancy: String = ""
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
}


// MARK: - Networking
extension CreateJobPostViewModel {
    
    func createJobPost() {
        guard !titleFieldText.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter a title for the job.".localized(localizationManager.language))
            return
        }
        
        guard !selectedDesignation.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please select a job designation.".localized(localizationManager.language))
            return
        }
        
        guard !descriptionFieldText.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please enter a brief job description.".localized(localizationManager.language))
            return
        }
        
        guard !selectedJobType.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please select a job type.".localized(localizationManager.language))
            return
        }
        
        guard !selectedExperience.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please select a minimum required experience for the job.".localized(localizationManager.language))
            return
        }
        
        guard !selectedSalary.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please select an offered salary range for the job.".localized(localizationManager.language))
            return
        }
        
        guard !selectedVacancy.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please select number of vacancies available for the job.".localized(localizationManager.language))
            return
        }
        
        showLoadingIndicator = true
        Task {
            let parameters: [String: Any] = [
                "title": titleFieldText,
                "designation": selectedDesignation,
                "description": descriptionFieldText,
                "jobType": selectedJobType,
                "salary": selectedSalary,
                "numberOfVacancies": selectedVacancy,
                "experience": selectedExperience,
                "joiningDate": DateManager.formatDateToyyyyMMdd(selectedJoiningDate)
            ]
            
            do {
                let result = try await dataManager.createJobPost(parameters: parameters)
                let range = 200...204
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        successMessage = result.message
                        isBookingSuccessful = true
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
