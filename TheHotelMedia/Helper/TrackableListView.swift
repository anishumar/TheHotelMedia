//
//  TrackableListView.swift
//  TheHotelMedia
//
//  Created by MAC on 07/03/25.
//

import SwiftUI
import Combine

struct TrackableListView<Content: View>: View {
    let isScrollingChanged: (Bool) -> Void
    var onViewedPost: (() -> Void)?
    let content: Content
    
    @State private var lastOffset: CGPoint = .zero
    @State private var currentOffset: CGPoint = .zero
    @State private var isScrolling = false
    @State private var offsetThreshold: CGFloat = 100
    private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @State var task: Task<Void, Never>?
    
    init(isScrollingChanged: @escaping (Bool) -> Void = { _ in }, onViewedPost: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.isScrollingChanged = isScrollingChanged
        self.onViewedPost = onViewedPost
        self.content = content()
    }
    
    var body: some View {
        List {
            content
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("ListView")).origin)
                    }
                )
        }
        .coordinateSpace(name: "ListView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { newOffset in
            currentOffset = newOffset
            if !isScrolling {
                isScrolling = true
                isScrollingChanged(true)
            }

        }
        .onReceive(timer) { _ in
            checkScrolling()
        }
        .onChange(of: isScrolling) { newValue in
            if !newValue {
                task = Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        onViewedPost?()
                    }
                }
            } else {
                task?.cancel()
                task = nil
            }
        }
    }
    
    
    private func configureCancellable() {
        
    }
    
    
    private func checkScrolling() {
        let yDifference = abs(abs(currentOffset.y) - abs(lastOffset.y))
        let isCurrentlyScrolling = lastOffset != currentOffset
        offsetThreshold = 0
//        offsetThreshold = isScrolling ? 0 : 100
        
        if yDifference >= offsetThreshold {
            if isCurrentlyScrolling != isScrolling {
                isScrolling = isCurrentlyScrolling
                isScrollingChanged(isScrolling)
            }
            lastOffset = currentOffset
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}


