//
//  BusinessQuestionsViewModel.swift
//  HotelMedia
//
//  Created by MAC on 23/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import SwiftyJSON


final class BusinessQuestionsViewModel: ObservableObject {
    
    
    var router: AnyRouter
    let dataManager = BusinessQuestionsManager()
    var cancellables = Set<AnyCancellable>()
    @Published var dataArray: [BusinessQuestion] = []
    @Published var questionArray: [DropDownModel] = []
    @Published var answersArray: [BusinessQuestionPost] = []
    @Published var counter: Double = 0
    @Published var spacing: CGFloat = 100
    @Published var showLoadingIndicator: Bool = false
    @Published var nextButtonDisabled: Bool = true
    @Published var errorText: String = ""
    
    @AppStorage("businessTypeID") var businessTypeID: String = ""
    @AppStorage("businessSubTypeID") var businessSubTypeID: String = ""
    
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func addSubscribers() {
        $dataArray
            .sink { questionArray in
                guard !questionArray.isEmpty else { return }
                
                var anotherArray: [DropDownModel] = []
                var nilArray: [BusinessQuestionPost] = []
                
                for question in questionArray {
                    let model = DropDownModel(id: question.id, answer: question.answer ?? [], question: question.question)
                    let answerModel = BusinessQuestionPost(questionID: question.id, answer: nil)
                    anotherArray.append(model)
                    nilArray.append(answerModel)
                }
                
                self.answersArray = nilArray
                self.questionArray = anotherArray
            }
            .store(in: &cancellables)
        
        $answersArray
            .sink { [weak self] answers in
                guard let self else { return }
                for answer in answers {
                    nextButtonDisabled = answer.answer == nil
                    if answer.answer == nil {
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    
    func cancelSubscriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    
    func decreaseCounter() {
        counter -= 1
    }
    
    
    func showBusinessLogoScreen() {
        router.showScreen(.push) { router in
            BusinessLogoDetailView(viewModel: BusinessLogoDetailViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showErrorModal() {
        router.showModal(transition: .move(edge: .bottom)) {
            BottomAlert(message: self.errorText)
        }
        print(self.errorText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) {
            self.router.dismissModal()
            self.errorText = ""
        }
    }
}


// MARK: - Networking
extension BusinessQuestionsViewModel {
    
    func getQuestions() {
//        guard networkMonitor.isConnected else {
//            errorText = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
        showLoadingIndicator = true
        
        let parameters: [String: Any] = [
            "businessTypeID": businessTypeID,
            "businessSubtypeID": businessSubTypeID
        ]
        
        Task {
            do {
                let result = try await dataManager.getBusinessQuestions(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
                if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                    if let data = result.data {
                        await MainActor.run {
                            dataArray = data
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
    
    
    func postAnswers() {
        var jsonData: Data? = nil
        do {
            jsonData = try JSONEncoder().encode(answersArray)
            
        } catch {
            print(error)
            return
        }
        
        guard let jsonData else { return }
        
//        guard networkMonitor.isConnected else {
//            errorText = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.postBusinessAnswers(data: jsonData)
                
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
                if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                    await MainActor.run {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                            guard let self else { return }
                            showBusinessLogoScreen()
                        }
                    }
                } else {
                    errorText = result.message
                    ErrorModalManager.showErrorModal(router: router, errorText: errorText)
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
}
