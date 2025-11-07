//
//  TagPeopleViewModel.swift
//  HotelMedia
//
//  Created by MAC on 03/09/24.
//

import SwiftUI
import SwiftfulRouting
import Combine

class TagPeopleViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = TagPeopleDataManager()
    var cancellables = Set<AnyCancellable>()
    var task: Task<(), Never>? = nil
    @Published var searchFieldText: String = ""
    @Published var profiles: [SearchProfile] = []
    @Published var newProfiles: [SearchProfile] = []
    @Published var isPagination: Bool = false
    @Published var selectedProfiles: [SearchProfile] = []
    @Published var showLoadingIndicator: Bool = false
    @Published var pageNumber: Int = 1
    @Published var totalPageNumber: Int = 1
    @Published var recentQuery: String = ""
    
    
    
    init(router: AnyRouter, selectedProfiles: [SearchProfile]? = nil) {
        self.router = router
        if let selectedProfiles {
            self.selectedProfiles = selectedProfiles
            print(selectedProfiles)
        }
        addSubcribers()
        getProfiles(pageNo: 1)
//        addDummyProfiles()
    }
    
    
    func addSubcribers() {
        $searchFieldText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                
                guard recentQuery != query else { return }
                recentQuery = query
                
                isPagination = false
                
                // Fetch search data
                pageNumber = 1
                totalPageNumber = 1
                
                getProfiles(query: query, pageNo: pageNumber)
            }
            .store(in: &cancellables)
        
        
        $newProfiles
            .map({ [weak self] (profiles) -> [SearchProfile] in
                guard let self else { return []}
                
                var array: [SearchProfile] = []
                for profile in profiles {
                    var mutableProfile = profile
                    if selectedProfiles.contains(where: {$0.id == profile.id}) {
                        mutableProfile.isSelected = true
                        array.append(mutableProfile)
                    } else {
                        mutableProfile.isSelected = false
                        array.append(mutableProfile)
                    }
                }
                
                return array
            })
            .sink { [weak self] profiles in
                guard let self else { return }
                
                if isPagination {
                    self.profiles += profiles
                } else {
                    self.profiles = profiles
                }
            }
            .store(in: &cancellables)        
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func didTapProfileView(profile: SearchProfile) {
        if let index = profiles.firstIndex(where: {$0.id == profile.id}) {
            
            guard let isSelected = profiles[index].isSelected else {
                
                profiles[index].isSelected = true
                selectedProfiles.append(profile)
                return
            }
            
            profiles[index].isSelected = !isSelected
            
            if let isSelected = profiles[index].isSelected {
                
                if isSelected {
                    selectedProfiles.append(profile)
                    
                } else {
                    selectedProfiles.removeAll(where: {$0.id == profile.id})
                }
            }
        }
    }
    
    
    func didDeselectProfile(profile: SearchProfile) {
        selectedProfiles.removeAll(where: {$0.id == profile.id})
        
        if let index = profiles.firstIndex(where: {$0.id == profile.id}) {
            profiles[index].isSelected = false
        }
    }
    
    
    func addDummyProfiles() {
        newProfiles.append(contentsOf: [
            SearchProfile(id: "profile_001", name: "John Doe", username: "john_doe", image: "ProfilePic1", accountType: "Individual"),
            SearchProfile(id: "profile_002", name: "Jane Smith", username: "jane_smith", image: "ProfilePic1", accountType: "Individual"),
            SearchProfile(id: "profile_003", name: "Michael Johnson", username: "michael_j", image: "ProfilePic1", accountType: "Individual"),
            SearchProfile(id: "profile_004", name: "Grand Imperial", username: "imperial_grand", image: "HotelPic", accountType: "Business", businessType: "Marriage Banquet"),
            SearchProfile(id: "profile_005", name: "Emily Davis", username: "emily_d", image: "ProfilePic1", accountType: "Individual"),
            SearchProfile(id: "profile_006", name: "David Martinez", username: "david_m", image: "ProfilePic1", accountType: "Individual"),
            SearchProfile(id: "profile_007", name: "Grand Imperial", username: "imperial_grand2", image: "HotelPic", accountType: "Business", businessType: "Hotel"),
            SearchProfile(id: "profile_008", name: "Sophia Brown", username: "sophia_b", image: "ProfilePic1", accountType: "Individual"),
            SearchProfile(id: "profile_009", name: "Imperial Palace", username: "palace_imperial", image: "HotelPic", accountType: "Business", businessType: "Bar/Club")

        ])
    }
}


// MARK: - Networking
extension TagPeopleViewModel {
    
    func getProfiles(query: String = "", pageNo: Int) {
        
        guard pageNumber <= totalPageNumber else { return }
        
        showLoadingIndicator = true
        
        task = Task {
            do {
                let result = try await dataManager.getTagPeople(pageNo: pageNo, query: query )
                
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            newProfiles = data
                        }
                        pageNumber = result.pageNo ?? 1
                        totalPageNumber = result.totalPages ?? 1
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
}
