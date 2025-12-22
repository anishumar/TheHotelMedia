//
//  SceneDelegate.swift
//  TheHotelMedia
//
//  Created by MAC on 19/03/25.
//

import UIKit
import SwiftUI
import FirebaseAuth
import FacebookLogin
import GoogleSignIn

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    let downloadManager = FileDownloadManager.shared
    
    @AppStorage("hasReadChat") var hasReadChat: Bool = true
    @AppStorage("hasReadNotifcation") var hasReadNotifcation: Bool = true
    @AppStorage("viaMessage") var viaMessage: Bool = false
    @AppStorage("viaOtherNotification") var viaOtherNotification: Bool = false
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        print("🎬 SceneDelegate - willConnectTo")
        
        let contentView = ContentView()
        
        if let response = connectionOptions.notificationResponse {
            print(response.notification.request.content.userInfo)
            let userInfo = response.notification.request.content.userInfo
            
            if let type = userInfo["screen"] as? String {
                if type == "messaging" {
                    hasReadChat = false
                    viaMessage = true
                } else {
                    hasReadNotifcation = false
                    viaOtherNotification = true
                }
            } else if let fileURLString = userInfo["fileURL"] as? String {
                if let url = URL(string: fileURLString) {
                    downloadManager.openFile(at: url)
                }
            }
        } else {
            viaMessage = false
            viaOtherNotification = false
        }
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        
        
    }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        print("🔗 SceneDelegate received URL: \(url.absoluteString)")
        
        // Prioritize Firebase Auth handling
        if Auth.auth().canHandle(url) {
            print("✅ Firebase Auth handled the URL")
            return
        }
        
        if GIDSignIn.sharedInstance.handle(url) {
            print("✅ Google Sign-In handled the URL")
            return
        }
        
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }

