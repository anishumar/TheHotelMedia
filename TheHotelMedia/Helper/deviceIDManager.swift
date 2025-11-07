//
//  DeviceIDManager.swift
//  TheHotelMedia
//
//  Created by MAC on 20/09/24.
//

import UIKit
import KeychainAccess

class DeviceIDManager {
    
    static let shared = DeviceIDManager()
    
    private let keychain = Keychain(service: "com.TheHotelMedia")
    private let deviceIDKey = "deviceID"
    
    func getDeviceID() -> String {
        do {
            // Check if the device ID is already saved in the Keychain
            if let savedDeviceID = try keychain.get(deviceIDKey) {
                return savedDeviceID
            }
            
            // Fetch the identifierForVendor
            let newDeviceID: String
            if let vendorID = UIDevice.current.identifierForVendor?.uuidString {
                newDeviceID = vendorID
            } else {
                // If identifierForVendor is nil, generate a new UUID
                newDeviceID = UUID().uuidString
            }
            
            // Save to the Keychain
            try keychain.set(newDeviceID, key: deviceIDKey)
            
            return newDeviceID
            
        } catch {
            print("Failed to retrieve or save device ID: \(error.localizedDescription)")
            
            // Return a fallback UUID and save it for future use
            let fallbackID = UUID().uuidString
            try? keychain.set(fallbackID, key: deviceIDKey)
            return fallbackID
        }
    }
}
