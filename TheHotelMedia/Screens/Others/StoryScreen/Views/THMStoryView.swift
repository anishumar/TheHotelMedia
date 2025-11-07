//
//  THMStoryView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI
import AVFoundation
import SwiftfulRouting

typealias THMUserCompletionHandler = (_ story: THMStory, _ message: String?, _ emoji: String?, _ isLiked: Bool) -> Void

struct THMStoryView: View {
    
    
    @StateObject var viewModel = THMStoryViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    // Private properties
    var stories: [THMStoryUIModel] = []
    @State var selectedIndex: Int = 0
    @State var offset: CGFloat = 0.0
    @State var onDrag: Bool = false
    let router: AnyRouter
    
    // Public properties
    var userClosure: THMUserCompletionHandler? = nil
    var onDeleteStory: ((Int) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    
    /// Stories and isPresented required, selectedIndex is optional default: 0
    /// - Parameters:
    ///   - stories: all stories to show
    ///   - selectedIndex: current story index selected by user
    ///   - isPresented: to hide and show for closing storyView
    init(
        stories: [THMStoryUIModel],
        selectedIndex: Int = 0,
        router: AnyRouter,
        userClosure: THMUserCompletionHandler? = nil,
        onDeleteStory: ((Int) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.router = router
        _selectedIndex = State(initialValue: selectedIndex)
        self.stories = stories
        self.userClosure = userClosure
        self.onDeleteStory = onDeleteStory
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            TabView(selection: $viewModel.currentStoryUser) {
                ForEach(viewModel.stories) { model in
                    THMStoryDetailView2(
                        viewModel: viewModel,
                        detailViewModel: THMStoryDetailViewModel(router: router),
                        onDrag: $onDrag,
                        model: model,
                        userClosure: userClosure,
                        onDeleteStory: onDeleteStory,
                        onDismiss: onDismiss)
                }
            }
        }
        .onReceive(viewModel.$currentStoryUser, perform: { id in
            if let index = viewModel.stories.firstIndex(where: { $0.id == id}) {
                selectedIndex = index
            }
        })
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: offset)
        .gesture(
            DragGesture()
                .onChanged({ value in
                    withAnimation(.interactiveSpring) {
                        offset = value.translation.height
                    }
                })
                .onEnded { value in
                    
                    if value.translation.height > 100 {
                        onDrag = true
                        onDismiss?()
                        router.dismissScreen()
                    } else {
                        withAnimation(.interactiveSpring) {
                            offset = 0
                        }
                        onDrag = false
                    }
                    
                }
        )
        .onAppear() {
            startStory()
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            } catch(let error) {
                print(error.localizedDescription)
            }
        }
        .onDisappear() {
           stopVideo()
        }
    }
    
    private func startStory() {
        viewModel.stories = stories
        viewModel.stories[selectedIndex].isSeen = true
        viewModel.currentStoryUser = stories[selectedIndex].id
    }
    
    private func stopVideo() {
        NotificationCenter.default.post(name: .stopVideoTHM, object: nil)
        NotificationCenter.default.removeObserver(self)
    }
}



