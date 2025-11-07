//
//  ContentView.swift
//  HotelMedia
//
//  Created by MAC on 26/07/24.
//

import SwiftUI
import SwiftfulRouting
import FacebookLogin

struct ContentView: View {
    
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    @AppStorage("hasReadNotifcation") var hasReadNotifcation: Bool = true
    @AppStorage("username") var username: String = ""
    @AppStorage("hasReadChat") var hasReadChat: Bool = true
    @AppStorage("appIsActive") var appIsActive: Bool = true
    @State var showContentScreen: Bool = false
    
    @StateObject var networkMonitor = NetworkMonitor()
    @StateObject var notificationManager = NotificationManager()
    @StateObject var inAppUpdateManager = UpdateNotifierViewModel()
    @StateObject var themeManager = ThemeManager.shared
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            if showContentScreen {
                if hasOnboarded {
                    if hasLoggedIn {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            ZStack {
                                RouterView { router in
                                    MainTabBarView(viewModel: MainTabBarViewModel(router: router))
                                        .environmentObject(networkMonitor)
                                        .environmentObject(themeManager)
                                        .navigationBarBackButtonHidden()
                                }
                            }
                            .transition(.move(edge: .bottom))
                            
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            ZStack {
                                RouterView { router in
                                    SignInView(viewModel: SignInViewModel(router: router))
                                        .environmentObject(themeManager)
                                        .navigationBarBackButtonHidden()
                                        .onOpenURL { url in
                                            ApplicationDelegate.shared.application(UIApplication.shared,
                                                                                   open: url,sourceApplication: nil,
                                                                                   annotation: UIApplication.OpenURLOptionsKey.annotation)
                                        }
                                }
                            }
                            .transition(.move(edge: .trailing))
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        ZStack {
                            RouterView { router in
                                SelectLanguageView(viewModel: SelectLanguageViewModel(router: router, initialScreen: true))
                                    .environmentObject(themeManager)
                                    .navigationBarBackButtonHidden()
                            }
                        }
                        .transition(.move(edge: .leading))
                    }
                }
            } else {
                LaunchView()
                    .environmentObject(themeManager)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .animation(.easeInOut(duration: 0.5), value: hasLoggedIn)
        .animation(.easeInOut(duration: 0.5), value: hasOnboarded)
        .environmentObject(LocalizationManager.shared)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showContentScreen = true
            }
        }
        .onAppear {
            inAppUpdateManager.checkForUpdate()
        }
        .alert(isPresented: $inAppUpdateManager.showAlert) {
            Alert(
                title: Text("Update Available"),
                message: Text("A new version of the app is available. Tap Update to download."),
                primaryButton: .default(Text("Update"), action: {
                    if let url = inAppUpdateManager.updateURL {
                        UIApplication.shared.open(url)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
        .overlay(alignment: .top) {
            ZStack {
                if networkMonitor.isActive {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Text("no_internet_connection".localized(LocalizationManager.shared.language))
                            .withComicFont(16, color: .white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        Rectangle()
                            .fill(.red)
                    )
//                    .padding(.top)
                    .transition(.move(edge: .top))
                }
            }
            .animation(.easeInOut, value: networkMonitor.isActive)
        }
        .preferredColorScheme(themeManager.darkThemeActive ? .dark :  .light)
        .task {
            await notificationManager.request()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                print("App became active")
                appIsActive = true
                if !username.isEmpty {
                    SocketIOViewModel.shared.configureSocket()
                }
                
                checkForDeliveredNotifications { type in
                    if type == "both" {
                        hasReadNotifcation = false
                        hasReadChat = false
                        
                    } else if type == "notification" {
                        hasReadNotifcation = false
                        hasReadChat = true
                    } else if type == "chat" {
                        hasReadChat = false
                        hasReadNotifcation = true
                    } else if type == "none" {
                        hasReadChat = true
                        hasReadNotifcation = true
                    }
                }
            case .inactive:
                print("App will resign active")
//                SocketIOViewModel.shared.disconnectSocket()
                appIsActive = false
                
            case .background:
                print("App moved to background")
                SocketIOViewModel.shared.disconnectSocket()
                appIsActive = false
            @unknown default:
                break
            }
        }
//        .onChange(of: UIApplication.shared.applicationState) { state in
//            if state == .active {
//            }
//        }
    }
}


struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        @Environment(\.router) var router
        
        ContentView()
    }
}

extension ContentView {
   
}


extension UIViewController {
    /// Finds the top-most view controller in the hierarchy.
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? tabBarController
        }
        return self
    }
}



