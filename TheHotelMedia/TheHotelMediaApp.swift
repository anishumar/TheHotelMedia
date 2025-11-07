//
//  HotelMediaApp.swift
//  HotelMedia
//
//  Created by MAC on 26/07/24.
//

import SwiftUI
import SwiftfulRouting
import AVFoundation

//import FBSDKCoreKit

@main
struct TheHotelMediaApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    
    init() {
        UINavigationBar.appearance().tintColor = UIColor.white
        UITextView.appearance().backgroundColor = UIColor.clear
        hideTabBar()
        let thumbImage = UIImage(imageLiteralResourceName: "SliderThumb")
                UISlider.appearance().setThumbImage(thumbImage, for: .normal)
        
//        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
//            RouterView { router in
//                BusinessLogoDetailView(viewModel: BusinessLogoDetailViewModel(router: router))
//                    .navigationBarBackButtonHidden()
//                    .environmentObject(LocalizationManager.shared)
//                    .environmentObject(ThemeManager.shared)
//            }
        }
    }
    
    func hideTabBar() {
        UITabBar.appearance().isHidden = true
    }
    
    
    private func handleIncomingURL(_ url: URL) {
        // Parse the URL
        if url.host == "thehotelmedia.com" {
            let path = url.path // e.g., "/share/users"
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            
            if path.contains("/share/users") {
                if let id = queryItems?.first(where: { $0.name == "id" })?.value,
                   let userID = queryItems?.first(where: { $0.name == "userID" })?.value {
                    if let decryptedID = EncryptionHelper.decrypt(id),
                       let decryptedUserID = EncryptionHelper.decrypt(userID) {
                        print(decryptedID, decryptedUserID)
                    }
                }
            }
        }
    }


}

func configureAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        print("Failed to set audio session category:", error)
    }
}
