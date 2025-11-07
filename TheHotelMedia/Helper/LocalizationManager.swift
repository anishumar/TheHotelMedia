//
//  LocalizationManager.swift
//  HotelMedia
//
//  Created by MAC on 08/08/24.
//

import SwiftUI

public enum SelectedLanguage: String {
    case hindi = "hi"
    case english = "en"
    case marathi = "mr-IN"
    case gujarati = "gu-IN"
    case kannada = "kn-IN"
    case telugu = "te-IN"
}


public class LocalizationManager: ObservableObject { // Mark the class as ObservableObject
    // MARK: - Variables
    public static let shared = LocalizationManager()
    @AppStorage("selectedLanguage") var languageString: String = SelectedLanguage.english.rawValue
    @Published public var language: SelectedLanguage = .english { // Match the initial language with languageString
        didSet {
            languageString = language.rawValue // We save the updated language's code into storage
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages") // Set the device's app language
            UserDefaults.standard.synchronize() // Optional as Apple does not recommend doing this
        }
    }
    
    // MARK: - Init
    public init() {
        // Added selected language initialization
        if let selectedLanguage = SelectedLanguage(rawValue: languageString) {
            language = selectedLanguage
        }
    }
}
