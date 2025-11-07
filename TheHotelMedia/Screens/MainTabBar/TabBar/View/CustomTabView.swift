//
//  CustomTabView.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import SwiftUI


struct CustomTabView: View {
    
    @EnvironmentObject var viewModel: MainTabBarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var compassHeading: CompassHeading
    @EnvironmentObject var gyroManager: GyroManager
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("hasReadChat") var hasReadChat: Bool = true
//    @Namespace var blueDotNamespace
    
    @State var isScrolling: Bool = false
    @State var degrees: CGFloat = .zero
    @State var x: CGFloat = .zero
    @State var y: CGFloat = .zero
    
    var body: some View {
        tabBar
//            .offset(y: isScrolling ? 100 : 0)
//            .animation(.bouncy, value: isScrolling)
//            .onReceive(viewModel.isScrolling) { value in
//                isScrolling = value
//            }
            .onReceive(compassHeading.degrees) { value in
                degrees = value
            }
            .onReceive(gyroManager.rotationRate) { rate in
                x = rate.x
                y = rate.y
            }
    }
}


// MARK: - Components
extension CustomTabView {
    private var tabBar: some View {
        HStack {
            Spacer()
            tabButton(item: .home)
            Spacer()
            if isIndividual {
                tabButton(item: .search)
            } else {
                tabButton(item: .insight)
            }
            
            Spacer()
            ZStack {
                Image(themeManager.currentTheme.Compass)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: .black.opacity(0.8), radius: 50)
                    .frame(width: 85, height: 85)
                    .rotationEffect(Angle(degrees: -degrees))
                    .rotation3DEffect(
                        .degrees(-x * 15),  // X-axis opposite tilt
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(-y * 15),  // Y-axis opposite tilt
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .animation(.smooth, value: degrees)
                    .animation(.smooth, value: x)
                    .animation(.smooth, value: y)
                    
                postButton
            }
            .onTapGesture {
                withAnimation(.smooth) {
                    viewModel.createPostOn.toggle()
                }
                haptics(.light)
            }
            
            Spacer()
            tabButton(item: .chat)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .opacity(hasReadChat ? 0.0 : 1.0)
                }
            Spacer()
            tabButton(item: .profile)
            Spacer()
        }
        .frame(height: 64)
        .background(
            ZStack {
                Capsule()
                    .fill(.thinMaterial)
                    .preferredColorScheme(.dark)
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(LinearGradient(colors: [themeManager.currentTheme.mediumGray_hmIndigo ,themeManager.currentTheme.mediumGray_hmIndigo , .black.opacity(0.001), themeManager.currentTheme.mediumGray_hmIndigo, themeManager.currentTheme.mediumGray_hmIndigo], startPoint: .leading, endPoint: .trailing))
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, UIApplication.bottomSafeAreaHeightTHM > 0 ? UIApplication.bottomSafeAreaHeightTHM : 16)
    }
    
    private func tabButton(item: TabbedItem) -> some View {
        VStack(spacing: 4) {
            Image(viewModel.selectedTab == item && !viewModel.createPostOn ? item.iconName + "Selected" : themeManager.darkThemeActive ? item.iconName : item.iconName + "-Dark")
                .animation(.none, value: viewModel.selectedTab)
            if viewModel.selectedTab == item && !viewModel.createPostOn{
                Circle()
                    .fill(.hmIndigo)
//                    .matchedGeometryEffect(id: "blueDotNamespace", in: blueDotNamespace)
                    .frame(width: 7)
            }
        }
        .onTapGesture {
            withAnimation(.smooth(duration: 0.2)) {
                viewModel.createPostOn = false
//                viewModel.navigateTo(screen: viewModel.currentTab.title, open: viewModel.createPostOn)
            }
            viewModel.sendNotificationOfCurrentTab(currentTab: item)
            viewModel.selectedTab = item
            haptics(.light)
        }
        .onTapGesture(count: 2, perform: {
            if viewModel.selectedTab == .home {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.onDoubleTap.toggle()
                }
            }
        })
//        .animation(.smooth(duration: 0.3), value: viewModel.selectedTab)
    }
    
    
    private var postButton: some View {
        VStack(spacing: 4) {
            Image("postSelected")
                .renderingMode(.template)
                .foregroundColor(.white.opacity(0.8))
                .rotationEffect(Angle(degrees: 45))
                .background(
                    ZStack {
                        Circle()
                            .fill(.hmIndigo)
                    }
                )
//            if viewModel.createPostOn {
//                Circle()
//                    .fill(.hmIndigo)
//                    .frame(width: 7)
//            }
        }
//        .onTapGesture {
//            withAnimation(.smooth) {
//                viewModel.createPostOn.toggle()
////                viewModel.navigateTo(screen: viewModel.currentTab.title, open: viewModel.createPostOn)
//            }
//            haptics(.light)
//            
//        }
        .animation(.smooth(duration: 0.3), value: viewModel.selectedTab)
    }
}
