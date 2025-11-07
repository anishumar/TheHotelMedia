//
//  String + Ext.swift
//  HotelMedia
//
//  Created by MAC on 08/08/24.
//

import Foundation


extension String {
    public func localized(_ language: SelectedLanguage) -> String {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            print("Failed to find path for language: \(language.rawValue)")
            return self
        }
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
    
    
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
}
