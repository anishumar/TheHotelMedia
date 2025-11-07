//
//  KeychainManager.swift
//  TheHotelMedia
//
//  Created by MAC on 30/01/25.
//

import Foundation
import KeychainAccess


class KeychainManager {
    
    static let shared = KeychainManager()
    
    private let keychain = Keychain(service: "com.thehotelmedia.ios")
    
    func saveEmailToKeychain(key: String, email: String) {
        do {
            if retrieveEmailFromKeychain(key: key) == nil {
                try keychain.set(email, key: key)
            }
        } catch {
            print("Failed to save email to Keychain: \(error.localizedDescription)")
        }
    }
    
    func retrieveEmailFromKeychain(key: String) -> String? {
        do {
            return try keychain.get(key)
        } catch {
            print("Failed to retrieve email from Keychain: \(error.localizedDescription)")
            return nil
        }
    }
}
