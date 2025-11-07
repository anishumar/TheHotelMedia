//
//  AddFeelingViewModel.swift
//  HotelMedia
//
//  Created by MAC on 04/09/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


class AddFeelingViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    var localizationManager = LocalizationManager.shared
    var allFeelingArray: [Feeling] {
        return [Feeling(id: "feeling_001", emoji: "😊", title: "feeling_happy".localized(localizationManager.language)),
                Feeling(id: "feeling_002", emoji: "😢", title: "feeling_sad".localized(localizationManager.language)),
                Feeling(id: "feeling_003", emoji: "😡", title: "feeling_angry".localized(localizationManager.language)),
                Feeling(id: "feeling_004", emoji: "😃", title: "feeling_excited".localized(localizationManager.language)),
                Feeling(id: "feeling_005", emoji: "😲", title: "feeling_surprised".localized(localizationManager.language)),
                Feeling(id: "feeling_006", emoji: "😱", title: "feeling_scared".localized(localizationManager.language)),
                Feeling(id: "feeling_007", emoji: "😕", title: "feeling_confused".localized(localizationManager.language)),
                Feeling(id: "feeling_008", emoji: "😴", title: "feeling_tired".localized(localizationManager.language)),
                Feeling(id: "feeling_009", emoji: "😬", title: "feeling_nervous".localized(localizationManager.language)),
                Feeling(id: "feeling_010", emoji: "😐", title: "feeling_bored".localized(localizationManager.language)),
                Feeling(id: "feeling_011", emoji: "😟", title: "feeling_anxious".localized(localizationManager.language)),
                Feeling(id: "feeling_012", emoji: "😳", title: "feeling_embarrassed".localized(localizationManager.language)),
                Feeling(id: "feeling_013", emoji: "🙏", title: "feeling_grateful".localized(localizationManager.language)),
                Feeling(id: "feeling_014", emoji: "😌", title: "feeling_proud".localized(localizationManager.language)),
                Feeling(id: "feeling_015", emoji: "😞", title: "feeling_lonely".localized(localizationManager.language)),
                Feeling(id: "feeling_016", emoji: "🤞", title: "feeling_hopeful".localized(localizationManager.language)),
                Feeling(id: "feeling_017", emoji: "❤️", title: "feeling_love".localized(localizationManager.language)),
                Feeling(id: "feeling_018", emoji: "😒", title: "feeling_jealous".localized(localizationManager.language)),
                Feeling(id: "feeling_019", emoji: "🤔", title: "feeling_curious".localized(localizationManager.language)),
                Feeling(id: "feeling_020", emoji: "😔", title: "feeling_ashamed".localized(localizationManager.language)),
                Feeling(id: "feeling_021", emoji: "😣", title: "feeling_guilty".localized(localizationManager.language)),
                Feeling(id: "feeling_022", emoji: "💪", title: "feeling_determined".localized(localizationManager.language)),
                Feeling(id: "feeling_023", emoji: "😌", title: "feeling_relieved".localized(localizationManager.language)),
                Feeling(id: "feeling_024", emoji: "😲", title: "feeling_shocked".localized(localizationManager.language)),
                Feeling(id: "feeling_025", emoji: "😞", title: "feeling_disappointed".localized(localizationManager.language)),
                Feeling(id: "feeling_026", emoji: "😤", title: "feeling_frustrated".localized(localizationManager.language)),
                Feeling(id: "feeling_027", emoji: "😯", title: "feeling_amazed".localized(localizationManager.language)),
                Feeling(id: "feeling_028", emoji: "😎", title: "feeling_confident".localized(localizationManager.language)),
                Feeling(id: "feeling_029", emoji: "😐", title: "feeling_indifferent".localized(localizationManager.language)),
                Feeling(id: "feeling_030", emoji: "😂", title: "feeling_hilarious".localized(localizationManager.language)),
                Feeling(id: "feeling_031", emoji: "🤣", title: "feeling_rolling_with_laughter".localized(localizationManager.language)),
                Feeling(id: "feeling_032", emoji: "🥰", title: "feeling_loved".localized(localizationManager.language)),
                Feeling(id: "feeling_033", emoji: "🤗", title: "feeling_caring".localized(localizationManager.language)),
                Feeling(id: "feeling_034", emoji: "😖", title: "feeling_miserable".localized(localizationManager.language)),
                Feeling(id: "feeling_035", emoji: "😩", title: "feeling_exhausted".localized(localizationManager.language)),
                Feeling(id: "feeling_036", emoji: "😵", title: "feeling_overwhelmed".localized(localizationManager.language)),
                Feeling(id: "feeling_037", emoji: "🥳", title: "feeling_celebratory".localized(localizationManager.language)),
                Feeling(id: "feeling_038", emoji: "🤯", title: "feeling_mind_blown".localized(localizationManager.language)),
                Feeling(id: "feeling_039", emoji: "😥", title: "feeling_worried".localized(localizationManager.language)),
                Feeling(id: "feeling_040", emoji: "🤤", title: "feeling_hungry".localized(localizationManager.language)),
                Feeling(id: "feeling_041", emoji: "😡", title: "feeling_angry".localized(localizationManager.language)),
                Feeling(id: "feeling_042", emoji: "😃", title: "feeling_excited".localized(localizationManager.language)),
                Feeling(id: "feeling_043", emoji: "😲", title: "feeling_surprised".localized(localizationManager.language)),
                Feeling(id: "feeling_044", emoji: "😱", title: "feeling_scared".localized(localizationManager.language)),
                Feeling(id: "feeling_045", emoji: "😕", title: "feeling_confused".localized(localizationManager.language))
]
    }
    @Published var searchFieldText: String = ""
    @Published var selectedFeeling: Feeling?
    @Published var arrayOfFeelings: [Feeling] = []
    
    init(router: AnyRouter, selectedFeeling: Feeling? = nil) {
        self.router = router
        if let selectedFeeling {
            self.selectedFeeling = selectedFeeling
        }
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $searchFieldText
            .sink { [weak self] query in
                guard let self else { return }
                var newArray: [Feeling] = []
                if query.isEmpty {
                    arrayOfFeelings = allFeelingArray
                } else {
                    for feeling in allFeelingArray {
                        if feeling.title.lowercased().contains(query.lowercased()) {
                            newArray.append(feeling)
                        }
                    }
                    arrayOfFeelings = newArray
                }
            }
            .store(in: &cancellables)
    }
}
