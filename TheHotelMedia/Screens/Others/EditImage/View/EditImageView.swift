//
//  EditImageView.swift
//  HotelMedia
//
//  Created by MAC on 09/09/24.
//

import SwiftUI
import SwiftUICoreImage


enum EditButton: String {
    case crop
    case filter
    case emoji
    case text
    case tag
    case location
}

// Define enum without associated values for iteration
enum FilterType: CaseIterable {
    case normal
    case sepiaTone
    case vibrance
    case black_white
    case faded
    case noir
    case bloom
    case pinkcity
    case oceanblues
    case retropolaroid
    case pixellate
    case moonlitgloom
    case bokehblur
    case goldenglow
    
    var title: String {
        switch self {
        case .sepiaTone: return "Sepia Tone"
        case .vibrance: return "Vibrance"
        case .normal:
            return "Normal"
        case .black_white:
            return "Black & White"
        case .faded:
            return "Faded"
        case .noir:
            return "Noir"
        case .bloom:
            return "Bloom"
        case .pinkcity:
            return "Pink City"
        case .oceanblues:
            return "Ocean Blues"
        case .retropolaroid:
            return "Retro Polaroid"
        case .pixellate:
            return "Pixellate"
        case .moonlitgloom:
            return "Moonlit Gloom"
        case .bokehblur:
            return "Bokeh Blur"
        case .goldenglow:
            return "Golden Glow"
        }
    }
    
    func ciImage(uiImage: UIImage) -> CIImage {
        switch self {
        case .sepiaTone:
            return CIImage(uiImage: uiImage)
                .sepiaTone(intensity: 1.0)
        case .vibrance:
            return CIImage(uiImage: uiImage)
                .vibrance(amount: 100.0)
        case .normal:
            return CIImage(uiImage: uiImage)
                
        case .black_white:
            return CIImage(uiImage: uiImage)
                .photoEffectMono(active: true)
        case .faded:
            return CIImage(uiImage: uiImage)
                .photoEffectFade(active: true)
                .sepiaTone(intensity: 0.7)
        case .noir:
            return CIImage(uiImage: uiImage)
                .photoEffectNoir(active: true)
        case .bloom:
            return CIImage(uiImage: uiImage)
                .recropping { image in
                    image
                        .clampedToExtent(active: true)
                        .bloom(radius: 4, intensity: 1.0)
                }
        case .pinkcity:
            return CIImage(uiImage: uiImage)
                .photoEffectInstant(active: true)
                .colorMonochrome(color: .magenta, intensity: 0.4)
        case .oceanblues:
            return CIImage(uiImage: uiImage)
                .colorMonochrome(color: .blue, intensity: 0.5)
        case .retropolaroid:
            return CIImage(uiImage: uiImage)
                .photoEffectProcess(active: true)
                .vignette(intensity: 1.0, radius: 1)
        case .pixellate:
            return CIImage(uiImage: uiImage)
                .recropping(apply: { image in
                    image
                        .clampedToExtent(active: true)
                        .pixellate(center: .zero, scale: 4)
                        .gloom(radius: 1, intensity: 1.2)
                        
                })
                
        case .moonlitgloom:
            return CIImage(uiImage: uiImage)
                .gloom(radius: 1, intensity: 2.0)
                .colorMonochrome(color: .gray, intensity: 0.8)
        case .bokehblur:
            return CIImage(uiImage: uiImage)
                .recropping { image in
                    image
                        .clampedToExtent(active: true)
                        .bokehBlur(radius: 3)
                }
                
        case .goldenglow:
            return CIImage(uiImage: uiImage)
                .exposureAdjust(ev: 1.1)
                .colorMonochrome(color: .yellow, intensity: 0.5)
        }
    }
}


struct EditImageView: View {
    
    @StateObject var viewModel: EditImageViewModel
    var returnedImage: ((UIImage) -> Void)?
    var onDismissed: (() -> Void)?
    @Environment(\.displayScale) var displayScale
    var emojiGrid: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var filterScrollViewStored: some View {
        filterScrollView
    }
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            header
                .opacity(viewModel.showHeader && !viewModel.showEmojiDeleteButon ? 1.0 : 0)
                .allowsHitTesting(viewModel.showHeader && !viewModel.showEmojiDeleteButon)
                .overlay {
                    ZStack {
                        if viewModel.showEmojiDeleteButon {
                            emojiEditButtons
                                .padding(.top, 16)
                        }
                        
                        if viewModel.selectedType == .text {
                            textEditButtons
                                .padding(.top, 16)
                        }
                    }
                    .zIndex(2.0)
                }
            VStack {
                ZStack {
                    edittedImageView(roundedCorner: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .overlay(
                HStack {
                    if viewModel.selectedType == .crop  {
                        cropButtonsSection
                            .frame(height: 64)
                            .background(
                                ZStack {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
//                                    Capsule()
//                                        .fill(themeManager.currentTheme.black03_white03)
                                    indigoCapsuleBackground
                                }
                            )
                    } else if viewModel.selectedType == .emoji {
                        emojiSection
                        
                    } else if viewModel.selectedType == .filter {
                        filterScrollViewStored
                            .frame(height: 64)
                            .background(
                                ZStack {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                    indigoCapsuleBackground
                                }
                            )
                    }
                }
                , alignment: .bottom
            )
            
            
            bottomButtonSection
                .padding(.horizontal, 24)
                .frame(height: 64)
                .background(
                    grayCapsuleBackground
                )
                .opacity(viewModel.showHeader && !viewModel.showEmojiDeleteButon ? 1.0 : 0)
                .allowsHitTesting(viewModel.showHeader && !viewModel.showEmojiDeleteButon)
            
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
        )
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
//                viewModel.showCropOptionModalView()
//            }
//        }
    }
    
}

// MARK: - Preview
struct EditImageView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditImageView(viewModel: EditImageViewModel(router: router, image: UIImage(named: "Landscape1")!))
    }
}


// MARK: - Functions

extension EditImageView {
    func getIndex(textBox: TextBox) -> Int {
        let index = viewModel.textBoxes.firstIndex { box in
            return textBox.id == box.id
        } ?? 0
        print(index)
        return index
    }
    
    
    func getEmojiIndex(emojiBox: EmojiBox) -> Int {
        let index = viewModel.addedEmojis.firstIndex { box in
            return emojiBox.id == box.id
        } ?? 0
        
        return index
    }
    
    
    func onTickButtonPressed() {
        if let uiImage = edittedImageView(roundedCorner: false).render(convertToColorDepth: true, scale: Constants.scale) {
            returnedImage?(uiImage)
        }
    }
}


// MARK: - Components

extension EditImageView {
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    onDismissed?()
                    viewModel.dismissScreen()
                }
            
            Text("edit_image".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                onTickButtonPressed()
                viewModel.dismissScreen()
            }, label: {
                Circle()
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    .frame(width: 28)
                    .overlay(
                        Image("Tick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    )
            })
        }
        .padding(.top, 16)
    }
    
    
    private var textEditButtons: some View {
        HStack {
            Button(action: {
                viewModel.selectedType = nil
            }, label: {
                Text("add".localized(localizationManager.language))
                    .font(.custom(Constants.comicBold, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
            })
            
            Spacer()
            
            ColorPicker("", selection: $viewModel.textBoxes[viewModel.currentIndex].textColor)
                .labelsHidden()
            
            Spacer()
            
            Button(action: {
                viewModel.cancelTextView()
            }, label: {
                Text("cancel".localized(localizationManager.language))
                    .font(.custom(Constants.comicBold, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
            })
            
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    
    private func edittedImageView(roundedCorner: Bool) -> some View {
        let width = UIScreen.main.bounds.width - 12
        let height = UIScreen.main.bounds.height - 140 - UIApplication.topSafeAreaHeightTHM - UIApplication.bottomSafeAreaHeightTHM
        return ZStack {
            Image(ciImage: (viewModel.filter.ciImage(uiImage: viewModel.edittedImage2)))
                .resizable()
                .scaledToFill()
                .rotationEffect(viewModel.selectedCropType == nil ? Angle(degrees: 0) : Angle(degrees: 0))
                .frame(
                    width: viewModel.currentImageStyle == "portrait" ? height * viewModel.currentImageWidthRatio : width,
                    height: viewModel.currentImageStyle == "portrait" ? height : width * viewModel.currentImageHeightRatio
                )
                .overlay {
                    ZStack {
                        ForEach(viewModel.textBoxes) { box in
                            textBoxView(box: box)
                        }
                    }
                    .frame(
                        width: viewModel.currentImageStyle == "portrait" ? height * viewModel.currentImageWidthRatio : width,
                        height: viewModel.currentImageStyle == "portrait" ? height : width * viewModel.currentImageHeightRatio
                    )
                }
                .overlay {
                    ZStack {
                        ForEach(viewModel.addedEmojis) { box in
                            emojiBoxView(box: box)
                        }
                    }
                    .frame(
                        width: viewModel.currentImageStyle == "portrait" ? height * viewModel.currentImageWidthRatio : width,
                        height: viewModel.currentImageStyle == "portrait" ? height : width * viewModel.currentImageHeightRatio
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: roundedCorner ? 20 : 0))
            
            if viewModel.selectedType == .text {
                themeManager.currentTheme.black75_white75
                    .ignoresSafeArea()
                    .onTapGesture {
                        endEditing()
                    }
                
                // textfield
                VStack(alignment: .center) {
                    TextField(
                        "type_here".localized(localizationManager.language),
                        text: $viewModel.textBoxes[viewModel.currentIndex].text,
                        prompt: Text(
                            "type_here".localized(localizationManager.language)
                        )
                        .font(.system(size: 25))
                        .foregroundColor(viewModel.textBoxes[viewModel.currentIndex].textColor),
                        axis: .vertical
                    )
                        .font(.system(size: 25))
                        .foregroundColor(viewModel.textBoxes[viewModel.currentIndex].textColor)
                        .multilineTextAlignment(.center)
                        .colorScheme(.dark)
                        .padding(.horizontal, 12)
//                        .toolbar {
//                            ToolbarItemGroup(placement: .keyboard) {
//                                doneButton
//                            }
//                        }
                }
                .frame(width: UIScreen.main.bounds.width, alignment: .center)
                .frame(maxHeight: Constants.screenHeight * 0.3)
            }
        }
        
    }
    
    
    private var doneButton: some View {
        HStack {
            
            Spacer()
            Button(action: {
                endEditing()
            }, label: {
                Text("done".localized(localizationManager.language))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                    
            })
        }
    }
    
    
    private var emojiEditButtons: some View {
        HStack {
            Button(action: {
                viewModel.addedEmojis.remove(at: viewModel.currentEmojiIndex)
                viewModel.currentEmojiIndex = 0
                viewModel.showEmojiDeleteButon = false
            }, label: {
                Text("delete".localized(localizationManager.language))
                    .font(.custom(Constants.comicBold, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
            })
            
            Spacer()
            
            Button(action: {
                viewModel.showEmojiDeleteButon = false
            }, label: {
                Text("cancel".localized(localizationManager.language))
                    .font(.custom(Constants.comicBold, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
            })
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    
    private func textBoxView(box: TextBox) -> some View {
        let index = getIndex(textBox: box)
        let width = UIScreen.main.bounds.width - 12
        let height = UIScreen.main.bounds.height - 140
        
        return VStack {
            Text(viewModel.textBoxes[viewModel.currentIndex].id == box.id && viewModel.selectedType == .text ? "" : box.text)
                .fontWeight(box.isBold ? .bold : .none)
                .font(.system(size: box.fontSize)) // Use fontSize instead of fixed size
                .multilineTextAlignment(.center)
                .foregroundColor(box.textColor)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .rotationEffect(box.angle)
                .offset(box.offset)
                .gesture(
                    // Drag Gesture
                    DragGesture()
                        .onChanged { value in
                            let newTranslation = CGSize(
                                width: value.translation.width + box.lastOffset.width,
                                height: value.translation.height + box.lastOffset.height
                            )
                            viewModel.textBoxes[index].offset = newTranslation
                        }
                        .onEnded { value in
                            viewModel.textBoxes[index].lastOffset = CGSize(
                                width: value.translation.width + box.lastOffset.width,
                                height: value.translation.height + box.lastOffset.height
                            )
                        }
                )
                .simultaneousGesture(
                    // Rotation Gesture
                    RotationGesture()
                        .onChanged { angle in
                            viewModel.textBoxes[index].angle = angle + box.lastAngle
                        }
                        .onEnded { angle in
                            viewModel.textBoxes[index].lastAngle = angle + box.lastAngle
                        }
                )
                .simultaneousGesture(
                    // Magnification Gesture for Font Size
                    MagnificationGesture()
                        .onChanged { value in
                            let newFontSize = box.lastFontSize * value
                            viewModel.textBoxes[index].fontSize = max(10, newFontSize) // Minimum font size
                        }
                        .onEnded { value in
                            viewModel.textBoxes[index].lastFontSize = box.fontSize
                        }
                )
                .onTapGesture {
                    viewModel.currentIndex = index
                    viewModel.addNewBox = false
                    viewModel.selectedType = .text
                }
                .opacity(viewModel.textBoxes[viewModel.currentIndex].id == box.id && viewModel.selectedType == .text ? 0.0 : 1.0)
        }
        .frame(
            width: viewModel.currentImageStyle == "portrait" ? height * viewModel.currentImageWidthRatio : width,
            height: viewModel.currentImageStyle == "portrait" ? height : width * viewModel.currentImageHeightRatio,
            alignment: .center
        )
        
    }
    
    
    private func emojiBoxView(box: EmojiBox) -> some View {
        let index = getEmojiIndex(emojiBox: box)
        
        return Text(box.emoji.emoji)
            .font(.system(size: box.fontSize)) // Use fontSize instead of scale
            .shadow(color: viewModel.addedEmojis[viewModel.currentEmojiIndex].id == box.id && viewModel.showEmojiDeleteButon ? .black : .clear, radius: 10)
            .rotationEffect(box.angle)
            .offset(box.offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let current = value.translation
                        let lastOffset = box.lastOffset
                        let newTranslation = CGSize(width: current.width + lastOffset.width, height: current.height + lastOffset.height)
                        viewModel.addedEmojis[index].offset = newTranslation
                    }
                    .onEnded { value in
                        let current = value.translation
                        let lastOffset = viewModel.addedEmojis[index].lastOffset
                        viewModel.addedEmojis[index].lastOffset = CGSize(width: current.width + lastOffset.width, height: current.height + lastOffset.height)
                    }
            )
            .simultaneousGesture(
                RotationGesture()
                    .onChanged { angle in
                        let lastAngle = box.lastAngle
                        viewModel.addedEmojis[index].angle = angle + lastAngle
                    }
                    .onEnded { angle in
                        let lastAngle = box.lastAngle
                        viewModel.addedEmojis[index].lastAngle = angle + lastAngle
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        let lastFontSize = box.lastFontSize
                        viewModel.addedEmojis[index].fontSize = lastFontSize * value
                    }
                    .onEnded { value in
                        viewModel.addedEmojis[index].lastFontSize = viewModel.addedEmojis[index].fontSize
                    }
            )
            .onTapGesture {
                viewModel.showEmojiDeleteButon = true
                viewModel.currentEmojiIndex = index
            }
            .animation(.bouncy(duration: 0.1), value: viewModel.showEmojiDeleteButon)
    }

    
    
    private func bottomButton(type: EditButton, action: (() -> Void)? = nil ) -> some View {
        VStack(spacing: 4) {
            Image(type.rawValue.capitalized)
                .renderingMode(.template)
                .font(.system(size: 26))
                .foregroundColor(viewModel.selectedType == nil ? themeManager.currentTheme.white08_darkGray08 : viewModel.selectedType == type ? .hmIndigo : themeManager.currentTheme.white08_darkGray08)
            Text(type.rawValue.capitalized)
                .font(.custom(Constants.comicFont , size: 9))
                .foregroundColor(viewModel.selectedType == nil ? themeManager.currentTheme.white08_darkGray08 : viewModel.selectedType == type ? .hmIndigo : themeManager.currentTheme.white08_darkGray08)
        }
        .onTapGesture {
            action?()
            if viewModel.selectedType == type {
                viewModel.selectedType = nil
            } else {
                viewModel.selectedType = type
            }
            
        }
    }
    
    
    private var bottomButtonSection: some View {
        HStack {
            bottomButton(type: .crop)
            Spacer()
            bottomButton(type: .filter)
                .fullScreenCover(isPresented: $viewModel.showCropView ) {
                    CropView(crop: viewModel.selectedCropType!, image: Image(uiImage: viewModel.image), hideDismissButton: false) { returnedImage, isCropped in
                        guard isCropped else { return }
                        
                        if let returnedImage {
                            viewModel.edittedImage = returnedImage
                            viewModel.edittedImage2 = returnedImage.render(scale: displayScale)!
                        }
                        
                    }
                    .environmentObject(ThemeManager.shared)
                }
            Spacer()
            bottomButton(type: .emoji)
                .fullScreenCover(isPresented: $viewModel.showingCropper, content: {
                    ImageCropper(image: $viewModel.image,
                                 cropShapeType: $viewModel.cropShapeType,
                                 presetFixedRatioType: $viewModel.presetFixedRatioType,
                                 type: $viewModel.cropperType, transformation: $viewModel.transformation, onCropped: { croppedImage in
                        viewModel.edittedImage2 = croppedImage
                    })
                    //                                .onDisappear(perform: reset)
                    .ignoresSafeArea()
                })
            Spacer()
            bottomButton(type: .text) {
                // updating this bool so that new TextBox gets created.
                viewModel.addNewBox = true
            }
        }
    }
    
    
    private func cropButton(type: Crop) -> some View {
        VStack(spacing: 4) {
            Image(type.name())
                .renderingMode(.template)
                .font(.system(size: 26))
                .foregroundColor(viewModel.selectedCropType == nil ? themeManager.currentTheme.white08_darkGray08 : viewModel.selectedCropType == type ? .hmIndigo : themeManager.currentTheme.white08_darkGray08)
                .shadow(color: .black, radius: 5)
            
            Text(type.name())
                .font(.custom(Constants.comicFont , size: 9))
                .foregroundColor(viewModel.selectedCropType == nil ? themeManager.currentTheme.white08_darkGray08 : viewModel.selectedCropType == type ? .hmIndigo : themeManager.currentTheme.white08_darkGray08)
                .shadow(color: themeManager.currentTheme.backgroundColor, radius: 10)
                
        }
        .onTapGesture {
            viewModel.selectedCropType = type
        }
    }
    
    
    private var grayCapsuleBackground: some View {
        Capsule()
            .stroke(lineWidth: 1)
            .fill(
                LinearGradient(
                    colors: [
                        .hmDarkerGray,
                        .hmDarkerGray.opacity(0.8),
                        .hmDarkerGray.opacity(0.4),
                        .hmDarkerGray.opacity(0.2),
                        .black.opacity(0.001),
                        .black.opacity(0.001),
                        .hmDarkerGray.opacity(0.2),
                        .hmDarkerGray.opacity(0.4),
                        .hmDarkerGray.opacity(0.8),
                        .hmDarkerGray
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    
    private var indigoCapsuleBackground: some View {
        Capsule()
            .stroke(lineWidth: 1)
            .fill(
                LinearGradient(
                    colors: [
                        .hmIndigo,
                        .hmIndigo.opacity(0.8),
                        .hmIndigo.opacity(0.4),
                        .hmIndigo.opacity(0.2),
                        .black.opacity(0.001),
                        .black.opacity(0.001),
                        .hmIndigo.opacity(0.2),
                        .hmIndigo.opacity(0.4),
                        .hmIndigo.opacity(0.8),
                        .hmIndigo
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    
    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(FilterType.allCases, id: \.self ) { filter in
                    
                    VStack {
                        Image(ciImage: filter.ciImage(uiImage: viewModel.edittedImage2))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(.circle)
                            .onTapGesture {
                                viewModel.filter = filter
                            }
                        
                        Text(filter.title)
                            .font(.custom(Constants.comicFont, size: 8))
                            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                            .lineLimit(2)
                    }
                   
                    
                }
            }
            .padding(.horizontal, 20)
        }
        .clipShape(Capsule())
    }
    
    
    private var cropButtonsSection: some View {
        HStack {
            Spacer()
            cropButton(type: .landscape)
            Spacer()
            cropButton(type: .portrait)
            Spacer()
            cropButton(type: .square)
            Spacer()
        }
    }
    
    
    private var emojiSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: emojiGrid, spacing: 12) {
                ForEach(viewModel.allEmojis) { emoji in
                    Text(emoji.emoji)
                        .font(.system(size: 35))
                        .onTapGesture {
                            viewModel.addedEmojis.append(EmojiBox(emoji: emoji))
                            viewModel.selectedType = nil
                        }
                }
            }
        }
        .background(
            VStack {
                if themeManager.darkThemeActive {
                    Color.black.opacity(0.95)
                } else {
                    Color.hmWhite.opacity(0.95)
                }
            }
        )
    }
}
