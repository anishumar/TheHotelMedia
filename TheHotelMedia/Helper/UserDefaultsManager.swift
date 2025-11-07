//
//  UserDefaultsManager.swift
//  TheHotelMedia
//
//  Created by MAC on 20/01/25.
//
import Foundation

class UserDefaultsManager {
    
    static let shared = UserDefaultsManager()
    
    private let key = "viewIDsArray"
    private let muteKey = "isMute"
    private let navigationStartedKey = "navigationStartedKey"
    private let userDefaults = UserDefaults.standard

    // Retrieve the array from UserDefaults
    func retrieveArray() -> [String] {
        return userDefaults.array(forKey: key) as? [String] ?? []
    }

    // Update the array by appending a new item
    func updateArray(with newID: String) {
        var existingArray = retrieveArray()
        existingArray.append(newID)
        userDefaults.set(existingArray, forKey: key)
//        print("Updated viewIDsArray:", existingArray)
    }

    // Clear the array in UserDefaults
    func clearArray() {
        userDefaults.removeObject(forKey: key)
//        print("viewIDsArray cleared.")
    }
    
    
    func setMuteStatus(_ isMute: Bool) {
        userDefaults.set(isMute, forKey: muteKey)
    }
    
    
    func getMuteStatus() -> Bool {
        if let bool = userDefaults.value(forKey: muteKey) as? Bool {
            return bool
        } else {
            userDefaults.set(true, forKey: muteKey)
            return true
        }
    }
    
    
    func navigationStarted(_ bool: Bool) {
        userDefaults.set(bool, forKey: navigationStartedKey)
    }
    
    
    func getNaviationStatus() -> Bool {
        if let bool = userDefaults.value(forKey: navigationStartedKey) as? Bool {
            return bool
        } else {
            userDefaults.set(false, forKey: navigationStartedKey)
            return false
        }
    }
}

