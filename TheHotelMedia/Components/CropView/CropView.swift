//
//  CropView.swift
//  HotelMedia
//
//  Created by MAC on 06/09/24.
//

import SwiftUI


// MARK: - View Extensions
extension View {
    // For making it simple and easy to use.
    @ViewBuilder
    func frame(_ size: CGSize) -> some View {
        self
            .frame(width: size.width, height: size.height)
    }
    
    
    func haptics(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    
    @ViewBuilder
    func customOnChange<Value: Equatable>(value: Value, completion: @escaping (Value) -> ()) -> some View {
        if #available(iOS 17, *) {
            self
                .onChange(of: value) { oldValue, newValue in
                    completion(newValue)
                }
        } else {
            self
                .onChange(of: value) { newValue in
                    completion(newValue)
                }
        }
    }
}


struct CropView: View {
    
    var crop: Crop
    var image: Image?
    var hideDismissButton: Bool = false
    var onCrop: (Image?, Bool) -> ()
    
    // View Properties
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 0
    @State private var degrees: CGFloat = 0 {
        didSet {
            changedDegress = degrees
        }
    }
    @State private var changedDegress: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero
    @GestureState private var isInteracting: Bool = false
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ImageView(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    themeManager.currentTheme.backgroundColor
                        .ignoresSafeArea()
                )
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Crop Image")
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: {
                            degrees -= 90
                        }, label: {
                            Image(systemName: "arrow.circlepath")
                        })
                        .foregroundColor(themeManager.currentTheme.label)
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: {
                            degrees += 90
                        }, label: {
                            Image(systemName: "arrow.circlepath")
                                .rotation3DEffect(
                                    Angle(degrees: 180),
                                                          axis: (x: 0.0, y: 1.0, z: 0.0)
                                )
                                .foregroundColor(themeManager.currentTheme.label)
                        })
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            if !hideDismissButton {
                                dismiss()
                            }
                            
                        }, label: {
                            Image(systemName: hideDismissButton ? "" : "xmark")
                                .foregroundColor(themeManager.currentTheme.label)
                        })
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            let renderer = ImageRenderer(content: ImageView(true))
                            renderer.scale = 10.0
                            renderer.proposedSize = .init(crop.size())
                            
                            if let image = renderer.uiImage {
                                onCrop(Image(uiImage: image), true)
                            } else {
                                onCrop(nil, false)
                            }
                            dismiss()
                            
                        }, label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.currentTheme.label)
                        })
                    }
                }
        }
    }
    
    // ImageView
    @ViewBuilder
    
    func ImageView(_ hideGrids: Bool) -> some View {
        let cropSize = crop.size()
        GeometryReader {
            let size = $0.size
            
            if let image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        GeometryReader{ proxy in
                            let rect = proxy.frame(in: .named("CropView"))
                            
                            Color.clear
                                .onChange(of: isInteracting, perform: { value in
                                    
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if rect.minX > 0 {
                                            offset.width = offset.width - rect.minX
                                            haptics(.medium)
                                        }
                                        
                                        if rect.minY > 0 {
                                            offset.height = offset.height - rect.minY
                                            haptics(.medium)
                                        }
                                        
                                        if rect.maxX < size.width {
                                            offset.width = rect.minX - offset.width
                                            haptics(.medium)
                                        }
                                        
                                        if rect.maxY < size.height {
                                            offset.height = rect.minY - offset.height
                                            haptics(.medium)
                                        }
                                    }
                                    
                                    
                                    if !value {
                                        lastStoredOffset = offset
                                    }
                                })
                                .onChange(of: changedDegress, perform: { value in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if rect.minX > 0 {
                                            offset.width = offset.width - rect.minX
                                        }
                                        
                                        if rect.minY > 0 {
                                            offset.height = offset.height - rect.minY
                                        }
                                        
                                        if rect.maxX < size.width {
                                            offset.width = rect.minX - offset.width
                                        }
                                        
                                        if rect.maxY < size.height {
                                            offset.height = rect.minY - offset.height
                                        }
                                    }
                                })
                        }
                    )
                    .frame(size)
                    
            }
        }
        .rotationEffect(Angle(degrees: degrees))
        .scaleEffect(scale)
        .offset(offset)
        .overlay(content: {
            if !hideGrids {
                Grids()
            }
        })
        .coordinateSpace(name: "CropView")
        .gesture(
            DragGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                }).onChanged({ value in
                    let translation = value.translation
                    offset = CGSize(width: translation.width + lastStoredOffset.width, height: translation.height + lastStoredOffset.height)
                })
        )
        .gesture(
            MagnificationGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                }).onChanged({ value in
                    let updatedScale = value + lastScale
                    // Prevent zooming in too much - max scale of 3x
                    let maxScale: CGFloat = 3.0
                    scale = min(max(updatedScale, 1), maxScale)
                }).onEnded({ value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if scale < 1 {
                            scale = 1
                            lastScale = 0
                        } else {
                            lastScale = scale - 1
                        }
                    }
                })
        )
        .frame(cropSize)
        .background(Color.black) // Black background for aspect fit
        .clipShape(
            RoundedRectangle(cornerRadius: crop == .circle ? cropSize.height / 2 : 0)
        )
    }
    
    // Grids
    @ViewBuilder
    func Grids() -> some View {
        ZStack {
            Rectangle()
                .stroke(lineWidth: 3)
                .fill(themeManager.currentTheme.label)
            
            VStack {
                Spacer()
                Rectangle()
                    .fill(.white)
                    .frame(height: 1)
                
                Spacer()
                
                Rectangle()
                    .fill(.white)
                    .frame(height: 1)
                
                Spacer()
            }
            
            HStack {
                Spacer()
                Rectangle()
                    .fill(.white)
                    .frame(width: 1)
                
                Spacer()
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 1)
                
                Spacer()
            }
        }
    }
}

#Preview {
    CropView(crop: .square, image: Image("Anime1")) { _, _ in
        
    }
}
