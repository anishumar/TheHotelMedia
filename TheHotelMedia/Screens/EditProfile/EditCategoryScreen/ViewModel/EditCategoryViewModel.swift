//
//  EditCategoryViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 30/09/24.
//

import SwiftfulRouting
import Combine
import SwiftUI


class EditCategoryViewModel: ObservableObject {
    
    var router: AnyRouter
    var selectedAnswers: [AmenityAnswer]
    let dataManager = EditCategoryManager()
    var cancellables = Set<AnyCancellable>()
    var oneTimeCancellables = Set<AnyCancellable>()
    @Published var nextButtonDisabled: Bool = true
    @Published var showLoadingIndicator: Bool = false
    @Published var errorText: String = ""
    @Published var typesArray: [TypeModel] = []
    @Published var subTypesArray: [SubTypeModel] = []
    @Published var selectedType: TypeModel? = nil
    @Published var selectedSubType: SubTypeModel? = nil
    @Published var typeDropDownOpen: Bool = false
    @Published var subTypeDropDownOpen: Bool = false
    
    @AppStorage("businessTypeID") var businessTypeID: String = ""
    @AppStorage("businessSubTypeID") var businessSubTypeID: String = ""
    
    init(router: AnyRouter, selectedAnswers: [AmenityAnswer]) {
        self.router = router
        self.selectedAnswers = selectedAnswers
        addSubscribers()
        addOneTimeSubscribers()
        getTypes()
        getSubTypes(id: businessSubTypeID)
    }
    
    
    func addSubscribers() {
        $selectedType
            .sink { [weak self] type in
                guard let self else { return }
                if let type {
                    selectedSubType = nil
                    getSubTypes(id: type.id ?? "")
                }
            }
            .store(in: &cancellables)
    }
    
    
    func addOneTimeSubscribers() {
        $typesArray
            .sink { [weak self] array in
                guard let self else { return }
                for type in array {
                    if type.id == businessTypeID {
                        selectedType = type
                        if selectedSubType != nil {
                            cancelOneTimeSubscriptions()
                        }
                        break
                    }
                }
            }
            .store(in: &oneTimeCancellables)
        
        $subTypesArray
            .sink { [weak self] array in
                guard let self else { return }
                
                for subType in array {
                    if subType.id == businessSubTypeID {
                        selectedSubType = subType
                        if selectedType != nil {
                            cancelOneTimeSubscriptions()
                        }
                        break
                    }
                }
            }
            .store(in: &oneTimeCancellables)
    }
    
    
    func cancelOneTimeSubscriptions() {
        for cancellable in oneTimeCancellables {
            cancellable.cancel()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showAmenitiesQuestionsScreen() {
        router.showScreen(.push) { router in
            EditAmenitiesView(viewModel: EditAmenitiesViewModel(router: router, selectedAnswers: self.selectedAnswers))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}


// MARK: - Networking
extension EditCategoryViewModel {
    func getTypes() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getBusinessType()
                
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
                if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                    if let data = result.data {
                        await MainActor.run {
                            typesArray = data
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
    
    
    func getSubTypes(id: String) {
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getBusinessSubType(id: id)
                
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
                if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                    if let data = result.data {
                        await MainActor.run {
                            subTypesArray = data
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
    
    
    func changeBusinessType() {
        
        guard let typeID = selectedType?.id,
              let subTypeID = selectedSubType?.id else {
            return
        }
        
        let parameters: [String: Any] = [
            "businessTypeID" : typeID,
            "businessSubTypeID" : subTypeID
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.changeBusinessType(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        businessTypeID = typeID
                        businessSubTypeID = subTypeID
                        showAmenitiesQuestionsScreen()
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
}
