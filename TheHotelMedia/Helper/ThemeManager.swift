//
//  ThemeManager.swift
//  TheHotelMedia
//
//  Created by MAC on 04/02/25.
//

import SwiftUI

/// Enum for different themes
enum Theme: String, CaseIterable {
    case light, dark // Future themes can be added here, like `blue`, `green`, etc.

    /// Returns the corresponding color scheme
    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Background color based on theme
    var backgroundColor: Color {
        switch self {
        case .light: return Color.hmWhite
        case .dark: return Color.black
        }
    }
    
    var label: Color {
        switch self {
        case .dark: return Color.white
        case .light: return Color.hmBlack2
        }
    }

    var label_06: Color {
        switch self {
        case .dark: return Color.white.opacity(0.6)
        case .light: return Color.hmBlack2
        }
    }
    
    var darkGray06_black008: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.6)
        case .light: return Color.hmBlack2.opacity(0.08)
        }
    }
    
    var darkGray05_white: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.5)
        case .light: return Color.hmWhite
        }
    }
    
    var darkGray05_hmIndigo02: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.5)
        case .light: return Color.hmIndigo.opacity(0.2)
        }
    }
    
    var mediumGray_black: Color {
        switch self {
        case .dark: return Color.hmDarkerGray
        case .light: return Color.hmBlack2
        }
    }
    
    var mediumGray_white: Color {
        switch self {
        case .dark: return Color.hmDarkerGray
        case .light: return Color.hmWhite
        }
    }
    
    var mediumGray_hmIndigo05: Color {
        switch self {
        case .dark: return Color.hmDarkerGray
        case .light: return Color.hmIndigo.opacity(0.5)
        }
    }
    
    var mediumGray_hmIndigo08: Color {
        switch self {
        case .dark: return Color.hmDarkerGray
        case .light: return Color.hmIndigo.opacity(0.8)
        }
    }
    
    var darkGray08_hmIndigo08: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.8)
        case .light: return Color.hmIndigo.opacity(0.8)
        }
    }
    
    var mediumGray_hmIndigo: Color {
        switch self {
        case .dark: return Color.hmDarkerGray
        case .light: return Color.hmIndigo
        }
    }
    
    var darkGray_white: Color {
        switch self {
        case .dark: return Color.hmDarkestGray
        case .light: return Color.hmWhite
        }
    }
    
    var darkGray06_hmIndigo09: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.6)
        case .light: return Color.hmIndigo.opacity(0.9)
        }
    }
    
    var hmIndigo_hmIndigo05: Color {
        switch self {
        case .dark: return Color.hmIndigo.opacity(0.5)
        case .light: return Color.hmIndigo
        }
    }
    
    var hmIndigo03_hmIndigo: Color {
        switch self {
        case .dark: return Color.hmIndigo.opacity(0.3)
        case .light: return Color.hmIndigo
        }
    }
    
    var hmIndigo04_hmIndigo08: Color {
        switch self {
        case .dark: return Color.hmIndigo.opacity(0.4)
        case .light: return Color.hmIndigo.opacity(0.8)
        }
    }
    
    var hmIndigo02_hmIndigo08: Color {
        switch self {
        case .dark: return Color.hmIndigo.opacity(0.2)
        case .light: return Color.hmIndigo.opacity(0.8)
        }
    }
    
    var hmIndigo07_hmIndigo: Color {
        switch self {
        case .dark: return Color.hmIndigo.opacity(0.7)
        case .light: return Color.hmIndigo
        }
    }
    
    var black09_white: Color {
        switch self {
        case .dark: return Color.black.opacity(0.9)
        case .light: return Color.hmWhite
        }
    }
    
    var black03_white03: Color {
        switch self {
        case .dark: return Color.black.opacity(0.3)
        case .light: return Color.hmWhite.opacity(0.3)
        }
    }
    
    var black75_white75: Color {
        switch self {
        case .dark: return Color.black.opacity(0.75)
        case .light: return Color.hmWhite.opacity(0.75)
        }
    }

    var white04_darkGray07: Color {
        switch self {
        case .dark: return Color.white.opacity(0.4)
        case .light: return Color.hmDarkestGray.opacity(0.7)
        }
    }
    
    var white07_darkGray: Color {
        switch self {
        case .dark: return Color.white.opacity(0.7)
        case .light: return Color.hmDarkestGray
        }
    }
    
    var white_darkGray: Color {
        switch self {
        case .dark: return Color.white
        case .light: return Color.hmDarkestGray
        }
    }
    
    var white08_darkGray08: Color {
        switch self {
        case .dark: return Color.white.opacity(0.8)
        case .light: return Color.hmDarkestGray.opacity(0.8)
        }
    }

    var white_hmIndigo: Color {
        switch self {
        case .dark: return Color.white
        case .light: return Color.hmIndigo
        }
    }
    
    var hmIndigo_white: Color {
        switch self {
        case .dark: return Color.hmIndigo
        case .light: return Color.white
        }
    }
    
    var hmIndigo_white05: Color {
        switch self {
        case .dark: return Color.hmIndigo
        case .light: return Color.white.opacity(0.5)
        }
    }
    
    var hmIndigo05_white: Color {
        switch self {
        case .dark: return Color.hmIndigo.opacity(0.5)
        case .light: return Color.white
        }
    }

    var lightGray_mediumGray: Color {
        switch self {
        case .dark: return Color.hmLightGray
        case .light: return Color.hmDarkGray
        }
    }
    
    var white03_darkGray03: Color {
        switch self {
        case .dark: return Color.white.opacity(0.3)
        case .light: return Color.hmDarkestGray.opacity(0.3)
        }
    }

    var black05_white05: Color {
        switch self {
        case .dark: return Color.black.opacity(0.5)
        case .light: return Color.white.opacity(0.5)
        }
    }
    
    var black_hmIndigo: Color {
        switch self {
        case .dark: return Color.black
        case .light: return Color.hmIndigo
        }
    }
    
    var black08_white05: Color {
        switch self {
        case .dark: return Color.black.opacity(0.8)
        case .light: return Color.white.opacity(0.5)
        }
    }
    
    var black08_white08: Color {
        switch self {
        case .dark: return Color.black.opacity(0.8)
        case .light: return Color.white.opacity(0.8)
        }
    }
    
    var white06_darkGray06: Color {
        switch self {
        case .dark: return Color.white.opacity(0.6)
        case .light: return Color.hmDarkestGray.opacity(0.6)
        }
    }
    
    var white04_darkGray04: Color {
        switch self {
        case .dark: return Color.white.opacity(0.4)
        case .light: return Color.hmDarkestGray.opacity(0.4)
        }
    }
    
    var white06_darkGray: Color {
        switch self {
        case .dark: return Color.white.opacity(0.6)
        case .light: return Color.hmDarkestGray
        }
    }
    
    var darkGray06_white06: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.6)
        case .light: return Color.white.opacity(0.6)
        }
    }
    
    var darkGray06_white: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.6)
        case .light: return Color.hmWhite
        }
    }
    
    var darkGray_hmIndigo09: Color {
        switch self {
        case .dark: return Color.hmDarkestGray
        case .light: return Color.hmIndigo.opacity(0.9)
        }
    }
    
    var white02_darkGray02: Color {
        switch self {
        case .dark: return Color.white.opacity(0.2)
        case .light: return Color.hmDarkestGray.opacity(0.2)
        }
    }
    
    var white06_hmwhite08: Color {
        switch self {
        case .dark: return Color.white.opacity(0.6)
        case .light: return Color.hmWhite.opacity(0.8)
        }
    }

    var darkGray06_mediumGray03: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.6)
        case .light: return Color.hmDarkerGray.opacity(0.3)
        }
    }
    
    var mediumGray05_darkGray05: Color {
        switch self {
        case .dark: return Color.hmDarkerGray.opacity(0.5)
        case .light: return Color.hmDarkestGray.opacity(0.5)
        }
    }
    
    var darkGray_mediumGray03: Color {
        switch self {
        case .dark: return Color.hmDarkestGray
        case .light: return Color.hmDarkerGray.opacity(0.3)
        }
    }
    
    var mediumGray_mediumGray03: Color {
        switch self {
        case .dark: return Color.hmDarkerGray
        case .light: return Color.hmDarkerGray.opacity(0.3)
        }
    }
    
    var mediumGray_mediumGray012: Color {
        switch self {
        case .dark: return Color.hmDarkerGray
        case .light: return Color.hmDarkerGray.opacity(0.12)
        }
    }
    
    var mediumGray_mediumGray05: Color {
        switch self {
        case .dark: return Color.hmDarkerGray
        case .light: return Color.hmDarkerGray.opacity(0.5)
        }
    }
    
    var darkGray06_darkGray008: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.6)
        case .light: return Color.hmDarkestGray.opacity(0.08)
        }
    }

    var darkGray05_hmIndigo: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.5)
        case .light: return Color.hmIndigo
        }
    }
    
    var darkGray05_hmIndigo05: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.5)
        case .light: return Color.hmIndigo.opacity(0.5)
        }
    }
    
    var hmIndigo05_darkGray05: Color {
        switch self {
        case .dark: return Color.hmIndigo.opacity(0.5)
        case .light: return Color.hmDarkestGray.opacity(0.5)
        }
    }
    
    var hmIndigo05_darkGray08: Color {
        switch self {
        case .dark: return Color.hmIndigo.opacity(0.5)
        case .light: return Color.hmDarkestGray.opacity(0.8)
        }
    }
    
    var hmgreen_hmgreen06: Color {
        switch self {
        case .dark: return Color.hmGreen
        case .light: return Color.hmGreen.opacity(0.6)
        }
    }
    
    var mediumGray05_mediumGray: Color {
        switch self {
        case .dark: return Color.hmDarkerGray.opacity(0.5)
        case .light: return Color.hmDarkerGray
        }
    }
    
    var mediumGray_mediumGray08: Color {
        switch self {
        case .dark: return Color.hmDarkerGray
        case .light: return Color.hmDarkerGray.opacity(0.8)
        }
    }

    var darkGray_hmwhite: Color {
        switch self {
        case .dark: return Color.hmDarkestGray
        case .light: return Color.hmWhite
        }
    }
    
    var darkGray_hmIndigo03: Color {
        switch self {
        case .dark: return Color.hmDarkestGray
        case .light: return Color.hmIndigo.opacity(0.3)
        }
    }
    
    var darkGray05_mediumGray_2: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.5)
        case .light: return Color.hmMediumGray
        }
    }
    
    var darkGray05_mediumGray3: Color {
        switch self {
        case .dark: return Color.hmDarkestGray.opacity(0.5)
        case .light: return Color.hmMediumGray3
        }
    }
    
    var hmred2_05_hmred2_08: Color {
        switch self {
        case .dark: return Color.hmRed2.opacity(0.5)
        case .light: return Color.hmRed2.opacity(0.8)
        }
    }
    
    
    // MARK: - Icons
    
    // settings
    var AboutUs: String {
        switch self {
        case .light: return "AboutUs-Black"
        case .dark: return "AboutUs"
        }
    }
    
    var BillIcon3: String {
        switch self {
        case .light: return "BillIcon3-Black"
        case .dark: return "BillIcon3"
        }
    }
    
    var BellIcon2: String {
        switch self {
        case .light: return "BellIcon2-Black"
        case .dark: return "BellIcon2"
        }
    }
    
    var BlockIcon: String {
        switch self {
        case .light: return "BlockIcon-Black"
        case .dark: return "BlockIcon"
        }
    }
    
    var Chevron_right: String {
        switch self {
        case .light: return "Chevron-right-Black"
        case .dark: return "Chevron-right"
        }
    }
    
    var CustomerSupport: String {
        switch self {
        case .light: return "CustomerSupport-Black"
        case .dark: return "CustomerSupport"
        }
    }
    
    var DocumentLock: String {
        switch self {
        case .light: return "DocumentLock-Black"
        case .dark: return "DocumentLock"
        }
    }
    
    var DocumentPencil: String {
        switch self {
        case .light: return "DocumentPencil-Black"
        case .dark: return "DocumentPencil"
        }
    }
    
    var EyeFill: String {
        switch self {
        case .light: return "EyeFill-Black"
        case .dark: return "EyeFill"
        }
    }
    
    var LanguageIcon: String {
        switch self {
        case .light: return "LanguageIcon-Black"
        case .dark: return "LanguageIcon"
        }
    }
    
    var Logout: String {
        switch self {
        case .light: return "Logout-Black"
        case .dark: return "Logout"
        }
    }
    
    var RemoveAccount: String {
        switch self {
        case .light: return "RemoveAccount-Black"
        case .dark: return "RemoveAccount"
        }
    }
    
    var SignBoard2: String {
        switch self {
        case .light: return "SignBoard2-Black"
        case .dark: return "SignBoard2"
        }
    }
    
    var DocumentIcon2: String {
        switch self {
        case .light: return "DocumentIcon2-Black"
        case .dark: return "DocumentIcon2"
        }
    }
    
    var bookmark3: String {
        switch self {
        case .light: return "bookmark3-Black"
        case .dark: return "bookmark3"
        }
    }
    
    var BinIcon: String {
        switch self {
        case .light: return "BinIcon-Black"
        case .dark: return "BinIcon"
        }
    }
    
    var SheetIndicator: String {
        switch self {
        case .light: return "SheetIndicator-White"
        case .dark: return "SheetIndicator"
        }
    }
    
    var BellIcon: String {
        switch self {
        case .light: return "BellIcon-Black"
        case .dark: return "BellIcon"
        }
    }
    
    var Title: String {
        switch self {
        case .light: return "Title-Black"
        case .dark: return "Title"
        }
    }
    
    // Interaction icons
    var comment: String {
        switch self {
        case .light: return "comment-Black"
        case .dark: return "comment"
        }
    }
    
    var heart: String {
        switch self {
        case .light: return "heart-Black"
        case .dark: return "heart"
        }
    }
    
    var share: String {
        switch self {
        case .light: return "share-Black"
        case .dark: return "share"
        }
    }
    
    var bookmark: String {
        switch self {
        case .light: return "bookmark-Black"
        case .dark: return "bookmark"
        }
    }
    
    var eye3: String {
        switch self {
        case .light: return "eye3-Black"
        case .dark: return "eye3"
        }
    }
    
    var LocationPin4: String {
        switch self {
        case .light: return "LocationPin4-Black"
        case .dark: return "LocationPin4"
        }
    }
    
    var Clock: String {
        switch self {
        case .light: return "Clock-Black"
        case .dark: return "Clock"
        }
    }
    
    var BorderStar: String {
        switch self {
        case .light: return "BorderStar-Black"
        case .dark: return "BorderStar"
        }
    }
    
    var SettingIcon: String {
        switch self {
        case .light: return "SettingIcon-Dark"
        case .dark: return "SettingIcon"
        }
    }
    
    var AddComment: String {
        switch self {
        case .light: return "AddComment-Dark"
        case .dark: return "AddComment"
        }
    }
    
    var SearchIcon3: String {
        switch self {
        case .light: return "SearchIcon3-Dark"
        case .dark: return "SearchIcon3"
        }
    }
    
    var eye2: String {
        switch self {
        case .light: return "eye2-Dark"
        case .dark: return "eye2"
        }
    }
    
    var EditIcon: String {
        switch self {
        case .light: return "EditIcon-Light"
        case .dark: return "EditIcon"
        }
    }
    
    var SignInBackground: String {
        switch self {
        case .light: return "SignInBackground-White"
        case .dark: return "SignInBackground"
        }
    }
    
    var IndividualType2: String {
        switch self {
        case .light: return "IndividualType2-Dark"
        case .dark: return "IndividualType2"
        }
    }
    
    var BusinessType2: String {
        switch self {
        case .light: return "BusinessType2-Dark"
        case .dark: return "BusinessType2"
        }
    }
    
    var BusinessSelected2: String {
        switch self {
        case .light: return "BusinessSelected2-Light"
        case .dark: return "BusinessSelected2"
        }
    }
    
    var IndividualSelected2: String {
        switch self {
        case .light: return "IndividualSelected2-Light"
        case .dark: return "IndividualSelected2"
        }
    }
    
    var CircleTick: String {
        switch self {
        case .light: return "CircleTick-Dark"
        case .dark: return "CircleTick"
        }
    }
    
    var PhotoIcon3: String {
        switch self {
        case .light: return "PhotoIcon3-Dark"
        case .dark: return "PhotoIcon3"
        }
    }
    
    var TagIcon: String {
        switch self {
        case .light: return "TagIcon-Dark"
        case .dark: return "TagIcon"
        }
    }
    
    var HappyIcon: String {
        switch self {
        case .light: return "HappyIcon-Dark"
        case .dark: return "HappyIcon"
        }
    }
    
    var CheckIn: String {
        switch self {
        case .light: return "CheckIn-Dark"
        case .dark: return "CheckIn"
        }
    }
    
    var CameraIcon2: String {
        switch self {
        case .light: return "CameraIcon2-Dark"
        case .dark: return "CameraIcon2"
        }
    }
    
    var RatingStar: String {
        switch self {
        case .light: return "RatingStar-Dark"
        case .dark: return "RatingStar"
        }
    }
    
    var bookmarkfill: String {
        switch self {
        case .light: return "bookmarkfill-White"
        case .dark: return "bookmarkfill"
        }
    }
    
    var BookingHistory: String {
        switch self {
        case .light: return "Booking-History-Dark"
        case .dark: return "Booking-History"
        }
    }
    
    var Moon: String {
        switch self {
        case .light: return "Moon-dark"
        case .dark: return "Moon"
        }
    }
    
    var Moon2: String {
        switch self {
        case .light: return "Moon2-dark"
        case .dark: return "Moon2"
        }
    }
    
    var Compass: String {
        switch self {
        case .light: return "Compass-dark"
        case .dark: return "Compass"
        }
    }
    
    var Briefcase: String {
        switch self {
        case .light: return "Brief-case-dark"
        case .dark: return "Brief-case"
        }
    }
    
    
}

/// ThemeManager to manage the current theme
class ThemeManager: ObservableObject {
    
    static let shared = ThemeManager()
    
    @AppStorage("currentStoredTheme") var currentStoredTheme: String = ""
    @Published var currentTheme: Theme = .dark {
        didSet {
            darkThemeActive = currentTheme == .dark
        }
    }
    @Published var darkThemeActive: Bool = true

    init() {
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        if currentStoredTheme == "" {
            currentTheme = isDarkMode ? .dark : .light
            currentStoredTheme = isDarkMode ? "dark" : "light"
            
        } else if currentStoredTheme == "dark" {
            currentTheme = .dark
            
        } else if currentStoredTheme == "light" {
            currentTheme = .light
        }
    }
    /// Toggle between themes
    func toggleTheme() {
        switch currentTheme {
        case .dark:
            currentTheme = .light
            currentStoredTheme = "light"
        case .light:
            currentTheme = .dark
            currentStoredTheme = "dark"
        }
    }
}
