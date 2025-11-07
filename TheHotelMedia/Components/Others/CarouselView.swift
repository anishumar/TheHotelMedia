//
//  CarouselView.swift
//  HotelMedia
//
//  Created by MAC on 13/08/24.
//

import SwiftUI

struct CarouselView: View {
    
    @GestureState private var dragState = DragState.inactive
    @State var carouselLocation = 0
    var actaulViewCount: Int
    var itemHeight: CGFloat
    var itemWidth: CGFloat
    @Binding var currentIndex: Int
    var views: [AnyView]
    var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    
    private func onDragEnded(drag: DragGesture.Value) {
        print("drag ended")
        let dragThreshold: CGFloat = 100
        
        if drag.predictedEndTranslation.width > dragThreshold || drag.translation.width > dragThreshold {
            carouselLocation -= 1
            decreaseIndex()
        } else if (drag.predictedEndTranslation.width) < (-1 * dragThreshold) || (drag.translation.width) < (-1 * dragThreshold) {
            carouselLocation += 1
            increaseIndex()
        }
    }
    
    
    private func increaseIndex() {
        if currentIndex == actaulViewCount - 1 {
            currentIndex = 0
        } else {
            currentIndex += 1
        }
    }
    
    
    private func decreaseIndex() {
        if currentIndex == 0 {
            currentIndex = actaulViewCount - 1
        } else {
            currentIndex -= 1
        }
    }
    
    
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    Spacer()
                    ForEach(0..<views.count) { i in
                        self.views[i]
                            .frame(width: itemWidth, height: getHeight(i))
                            .animation(.interpolatingSpring(stiffness: 300, damping: 30, initialVelocity: 10), value: carouselLocation)
                            .offset(x: self.getOffset(i))
                            .animation(.interpolatingSpring(stiffness: 300, damping: 30, initialVelocity: 10), value: carouselLocation)
                            .opacity(self.getOpacity(i))
                    }
                    Spacer()
                }
                .gesture(
                    DragGesture()
                        .updating($dragState, body: { drag, state, transaction in
                            state = .dragging(translation: drag.translation)
                        })
                        .onEnded(onDragEnded)
                )
            }
        }
        
        
    }
    
    
    func relativeLoc() -> Int {
        return ((views.count * 10000) + carouselLocation) % views.count
    }
    
    
    func getHeight(_ i: Int) -> CGFloat {
        if i == relativeLoc() {
            return itemHeight
        } else {
            return itemHeight - 50
        }
    }
    
    
    func getOpacity(_ i: Int) -> Double {
        if isIpad {
            if i == relativeLoc()
    //            || i + 1 == relativeLoc()
    //            || i - 1 == relativeLoc()
                || i + 2 == relativeLoc()
                || i - 2 == relativeLoc()
    //            || (i + 1) - views.count == relativeLoc()
    //            || (i - 1) + views.count == relativeLoc()
                || (i + 2) - views.count == relativeLoc()
                || (i - 2) + views.count == relativeLoc()
            {
                return 1
            } else {
                return 0
            }
        } else {
            
            if i == relativeLoc()
                || i + 1 == relativeLoc()
                || i - 1 == relativeLoc()
                || i + 2 == relativeLoc()
                || i - 2 == relativeLoc()
                || (i + 1) - views.count == relativeLoc()
                || (i - 1) + views.count == relativeLoc()
                || (i + 2) - views.count == relativeLoc()
                || (i - 2) + views.count == relativeLoc()
            {
                return 1
            } else {
                return 0
            }
        }
        
    }
    
    
//    func getOffset(_ i: Int) -> CGFloat {
//        
//        // This sets up the central location
//        if (i) == relativeLoc()
//        {
//            return self.dragState.translation.width
//        }
//        
//        // These sets up offset +/- 1
//        else if
//            (i) == relativeLoc() + 1 || (relativeLoc() == views.count - 1 && i == 0)
//        {
//            //Set offset +1
//            return self.dragState.translation.width + (itemWidth + 20)
//        }
//        else if
//            (i) == relativeLoc() - 1
//                || (relativeLoc() == 0 && (i) == views.count - 1)
//        {
//            //Set offset +1
//            return self.dragState.translation.width - (itemWidth + 20)
//        }
//        
//        // These sets up offset +/- 2
//        else if
//            (i) == relativeLoc() + 2
//                ||
//                (relativeLoc() == views.count - 1 && i == 1)
//                ||
//                (relativeLoc() == views.count - 2 && i == 0)
//        {
//            // Set offset +2
//            return self.dragState.translation.width + (2 * (itemWidth + 20))
//        }
//        else if
//            (i) == relativeLoc() + 2
//                ||
//                (relativeLoc() == 1 && i == views.count - 1)
//                ||
//                (relativeLoc() == 0 && i == views.count - 2)
//        {
//            // Set offset -2
//            return self.dragState.translation.width - (2 * (itemWidth + 20))
//        }
//        
//        // These sets up offset +/- 3
//        else if
//            (i) == relativeLoc() + 3
//                ||
//                (relativeLoc() == views.count - 1 && i == 2)
//                ||
//                (relativeLoc() == views.count - 2 && i == 1)
//                ||
//                (relativeLoc() == views.count - 3 && i == 0)
//        {
//            // Set offset +3
//            return self.dragState.translation.width + (3 * (itemWidth + 20))
//        }
//        else if
//            (i) == relativeLoc() - 3
//                ||
//                (relativeLoc() == 2 && i == views.count - 1)
//                ||
//                (relativeLoc() == 1 && i == views.count - 2)
//                ||
//                (relativeLoc() == 0 && i == views.count - 3)
//        {
//            return self.dragState.translation.width - (3 * (itemWidth + 20))
//        }
//        else
//        {
//            return 10000
//        }
//    }
    
    func getOffset(_ i: Int) -> CGFloat {
        if i == relativeLoc() {
            return dragState.translation.width
        } else if i == relativeLoc() + 1 || relativeLoc() == views.count - 1 && i == 0{
            return dragState.translation.width + (300 + 20)
        } else if i == relativeLoc() - 1 || relativeLoc() == 0 && i == views.count - 1 {
            return dragState.translation.width - (300 + 20)
        } else if i == relativeLoc() + 2 || (relativeLoc() == views.count - 1 && i == 1) || (relativeLoc() == views.count - 2 && i == 0) {
            return dragState.translation.width + (2*(300 + 20))
        } else if i == relativeLoc() - 2 || (relativeLoc() == 1 && i == views.count - 1) || (relativeLoc() == 0 && i == views.count - 2) {
            return dragState.translation.width - (2*(300 + 20))
        } else if i == relativeLoc() + 3 || (relativeLoc() == views.count - 1 && i == 2) || (relativeLoc() == views.count - 2 && i == 1) || (relativeLoc() == views.count - 3 && i == 0){
            return dragState.translation.width + (3*(300 + 20))
        } else if i == relativeLoc() - 3 || (relativeLoc() == 2 && i == views.count - 1) || (relativeLoc() == 1 && i == views.count - 2) || (relativeLoc() == 0 && i == views.count - 3) {
            return dragState.translation.width - (3*(300 + 20))
        } else {
            return 10000
        }
    }
}


enum DragState {
    case inactive
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging( let translation):
            return translation
        }
    }
    
    
    var isDragging: Bool {
        switch self {
        case .inactive:
            return false
        case .dragging:
            return true
        }
    }
}
