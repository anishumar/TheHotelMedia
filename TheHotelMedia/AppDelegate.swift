//
//  AppDelegate.swift
//  TheHotelMedia
//
//  Created by MAC on 24/09/24.
//

import SwiftUI
import GooglePlaces
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import UserNotifications
import AVFoundation
import FacebookLogin



let googlePlacesKey = "AIzaSyCoDc7bhRp94TgvpG00jafqzyqo2ljh2IM"

class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    @AppStorage("fcmtoken") var fcmtoken: String = ""
    @AppStorage("hasReadNotifcation") var hasReadNotifcation: Bool = true
    @AppStorage("username") var username: String = ""
    @AppStorage("launchViaNotification") var launchViaNotification: Bool = false
    @AppStorage("hasReadChat") var hasReadChat: Bool = true
    @AppStorage("viaMessage") var viaMessage: Bool = false
    @AppStorage("viaOtherNotification") var viaOtherNotification: Bool = false
    
    let downloadManager = FileDownloadManager.shared
    let backgroundNetworkManager = BackgroundNetworkManager.shared
    var backgroundCompletionHandler: (() -> Void)?
    
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        GMSServices.provideAPIKey(googlePlacesKey)
        GMSPlacesClient.provideAPIKey(googlePlacesKey)
        
        let expectedClientID = "156125638721-eeh3s3mk2te4g38d3emuif6mqnlb7e15.apps.googleusercontent.com"
        
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            print("🔑 Google Sign-In configured with CLIENT_ID from GoogleService-Info.plist: \(clientId)")
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        } else if let clientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
            print("🔑 Google Sign-In configured with GIDClientID from Info.plist: \(clientId)")
            print("🔑 Expected client ID (from backend): \(expectedClientID)")
            if clientId != expectedClientID {
                print("⚠️ WARNING: Client ID mismatch! Configured: \(clientId), Expected: \(expectedClientID)")
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        } else {
            print("❌ ERROR: Could not find Google Client ID in Info.plist or GoogleService-Info.plist")
        }
        
        if let config = GIDSignIn.sharedInstance.configuration {
            print("✅ Google Sign-In is configured with client ID: \(config.clientID)")
        } else {
            print("❌ ERROR: Google Sign-In configuration is nil!")
        }
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        let lowRatingCategory = UNNotificationCategory(
            identifier: "LOW_RATING_ALERT",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([lowRatingCategory])
        
        if !username.isEmpty {
            SocketIOViewModel.shared.configureSocket()
        }
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        
        return true
    }
    
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        return ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
//        sceneConfig.delegateClass = SceneDelegate.self
        if let response = options.notificationResponse {
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
        return sceneConfig
    }
    

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return Self.orientationLock
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            print("fcm", fcm, "☕️")
            fcmtoken = fcm
        }
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print(userInfo)
        if let type = userInfo["screen"] as? String {
            if type == "messaging" {
                hasReadChat = false
            } else {
                hasReadNotifcation = false
            }
        }
        
        completionHandler([.badge, .sound, .banner])
    }
    
    
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print(userInfo)
        if let type = userInfo["screen"] as? String {
            if type == "messaging" {
                hasReadChat = false
            } else {
                hasReadNotifcation = false
            }
        }
        
        
        completionHandler(.newData) // Signal completion
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Always call the completion handler when done
        let userInfo = response.notification.request.content.userInfo
        print(userInfo)
        if let type = userInfo["screen"] as? String {
            if type == "messaging" {
                openChatTab()
            } else {
                postOpenCommentSectionNotification(shouldOpen: true)
            }
            
        } else if let fileURLString = userInfo["fileURL"] as? String {
            if let url = URL(string: fileURLString) {
                downloadManager.openFile(at: url)
            }
        }
        
        completionHandler()
    }
    
    
    // background uploading task

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }

}


func postOpenCommentSectionNotification(shouldOpen: Bool) {
    NotificationCenter.default.post(
        name: NSNotification.Name("showNotificationScreen"),
        object: nil,
        userInfo: ["shouldOpen": shouldOpen]
    )
}


func openChatTab() {
    NotificationCenter.default.post(
        name: NSNotification.Name("openChatTab"),
        object: nil,
        userInfo: nil
    )
}


func checkForDeliveredNotifications(completion: ((String) -> Void)?) {
    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
        DispatchQueue.main.async {
            
            var readNotification: Bool = true
            var readChat: Bool = true
            
            for notification in notifications {
                let userInfo = notification.request.content.userInfo
                
                if let type = userInfo["screen"] as? String {
                    if type == "messaging" {
                        readChat = false
                        
                        if !readNotification && !readChat {
                            break
                        }
                        
                    } else {
                        readNotification = false
                        if !readNotification && !readChat {
                            break
                        }
                    }
                }
            }
            
            if !readNotification && !readChat {
                completion?("both")
                return
            }
            
            if !readNotification {
                completion?("notification")
                return
            }
            
            if !readChat {
                completion?("chat")
                return
            }
            
            if readChat && readNotification {
                completion?("none")
            }
        }
    }
}


func getGenericNotificationIDs()  {
    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
       
        for notification in notifications {
            let userInfo = notification.request.content.userInfo
            
            if let type = userInfo["screen"] as? String {
                if type == "messaging" {
                    
                    
                } else {
                    
                }
            }
        }
    }
}
