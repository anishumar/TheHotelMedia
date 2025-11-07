//
//  EditImageViewModel.swift
//  HotelMedia
//
//  Created by MAC on 09/09/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import Mantis


class EditImageViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    var cropOptions = ["Landscape", "Portrait", "Square"]
    @Published var selectedType: EditButton? = nil
    @Published var selectedCropType: Crop? = nil
    @Published var image: UIImage
    @Published var edittedImage: Image
    @Published var edittedImage2: UIImage
    @Published var showCropView: Bool = false
    @Published var filter: FilterType = .normal
    @Published var textBoxes: [TextBox] = []
    @Published var addedEmojis: [EmojiBox] = []
    @Published var addNewBox: Bool = true
    @Published var currentIndex = 0
    @Published var showHeader: Bool = true
    @Published var showEmojiDeleteButon: Bool = false
    @Published var currentEmojiIndex: Int = 0
    @Published var currentImageHeightRatio: CGFloat = 1
    @Published var currentImageWidthRatio: CGFloat = 1
    @Published var currentImageStyle: String = "portrait"
    
    @Published var showingCropper = false
    @Published var showingCropShapeList = false
    @Published var cropShapeType: Mantis.CropShapeType = .rect
    @Published var presetFixedRatioType: Mantis.PresetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
    @Published var cropperType: ImageCropperType = .normal
    @Published var transformation: Transformation?
    
    var allEmojis: [Emoji] {
        return [
            // Smileys & Emotion
            Emoji(emoji: "😀"), Emoji(emoji: "😃"), Emoji(emoji: "😄"), Emoji(emoji: "😁"), Emoji(emoji: "😆"), Emoji(emoji: "😅"),
            Emoji(emoji: "😂"), Emoji(emoji: "🤣"), Emoji(emoji: "😊"), Emoji(emoji: "😇"), Emoji(emoji: "🙂"), Emoji(emoji: "🙃"),
            Emoji(emoji: "😉"), Emoji(emoji: "😌"), Emoji(emoji: "😍"), Emoji(emoji: "🥰"), Emoji(emoji: "😘"), Emoji(emoji: "😗"),
            Emoji(emoji: "😙"), Emoji(emoji: "😚"), Emoji(emoji: "😋"), Emoji(emoji: "😜"), Emoji(emoji: "🤪"), Emoji(emoji: "😝"),
            Emoji(emoji: "🤑"), Emoji(emoji: "🤗"), Emoji(emoji: "🤭"), Emoji(emoji: "🤫"), Emoji(emoji: "🤔"), Emoji(emoji: "🤐"),
            Emoji(emoji: "🤨"), Emoji(emoji: "😐"), Emoji(emoji: "😑"), Emoji(emoji: "😶"), Emoji(emoji: "😏"), Emoji(emoji: "😒"),
            Emoji(emoji: "🙄"), Emoji(emoji: "😬"), Emoji(emoji: "🤥"), Emoji(emoji: "😔"), Emoji(emoji: "😪"), Emoji(emoji: "🤤"),
            Emoji(emoji: "😴"), Emoji(emoji: "😷"), Emoji(emoji: "🤒"), Emoji(emoji: "🤕"), Emoji(emoji: "🤢"), Emoji(emoji: "🤮"),
            Emoji(emoji: "🤧"), Emoji(emoji: "🥵"), Emoji(emoji: "🥶"), Emoji(emoji: "🥴"), Emoji(emoji: "😵"), Emoji(emoji: "🤯"),
            Emoji(emoji: "🤠"), Emoji(emoji: "🥳"), Emoji(emoji: "😎"), Emoji(emoji: "🤓"), Emoji(emoji: "🧐"), Emoji(emoji: "😕"),
            Emoji(emoji: "😟"), Emoji(emoji: "🙁"), Emoji(emoji: "😮"), Emoji(emoji: "😯"), Emoji(emoji: "😲"), Emoji(emoji: "😳"),
            Emoji(emoji: "🥺"), Emoji(emoji: "😢"), Emoji(emoji: "😭"), Emoji(emoji: "😤"), Emoji(emoji: "😠"), Emoji(emoji: "😡"),
            Emoji(emoji: "🤬"), Emoji(emoji: "🤯"), Emoji(emoji: "🥱"), Emoji(emoji: "😩"), Emoji(emoji: "😫"), Emoji(emoji: "😰"),
            Emoji(emoji: "😨"), Emoji(emoji: "😱"), Emoji(emoji: "😳"), Emoji(emoji: "😖"), Emoji(emoji: "😣"), Emoji(emoji: "😞"),
            
            // Gestures & Hands
            Emoji(emoji: "👋"), Emoji(emoji: "🤚"), Emoji(emoji: "🖐"), Emoji(emoji: "✋"), Emoji(emoji: "👌"), Emoji(emoji: "✌️"),
            Emoji(emoji: "🤞"), Emoji(emoji: "🤟"), Emoji(emoji: "🤘"), Emoji(emoji: "🤙"), Emoji(emoji: "👈"), Emoji(emoji: "👉"),
            Emoji(emoji: "👆"), Emoji(emoji: "👇"), Emoji(emoji: "👍"), Emoji(emoji: "👎"), Emoji(emoji: "✊"), Emoji(emoji: "👊"),
            Emoji(emoji: "🤛"), Emoji(emoji: "🤜"), Emoji(emoji: "👏"), Emoji(emoji: "🙌"), Emoji(emoji: "👐"), Emoji(emoji: "🤲"),
            Emoji(emoji: "🙏"), Emoji(emoji: "✍️"), Emoji(emoji: "💪"), Emoji(emoji: "🖖"), Emoji(emoji: "🤙"), Emoji(emoji: "🤲"),
            
            // Animals & Nature
            Emoji(emoji: "🐶"), Emoji(emoji: "🐱"), Emoji(emoji: "🐭"), Emoji(emoji: "🐹"), Emoji(emoji: "🐰"), Emoji(emoji: "🦊"),
            Emoji(emoji: "🐻"), Emoji(emoji: "🐼"), Emoji(emoji: "🐨"), Emoji(emoji: "🐯"), Emoji(emoji: "🦁"), Emoji(emoji: "🐮"),
            Emoji(emoji: "🐷"), Emoji(emoji: "🐽"), Emoji(emoji: "🐸"), Emoji(emoji: "🐵"), Emoji(emoji: "🙈"), Emoji(emoji: "🙉"),
            Emoji(emoji: "🙊"), Emoji(emoji: "🐒"), Emoji(emoji: "🐔"), Emoji(emoji: "🐧"), Emoji(emoji: "🐦"), Emoji(emoji: "🐤"),
            Emoji(emoji: "🐣"), Emoji(emoji: "🐥"), Emoji(emoji: "🦆"), Emoji(emoji: "🦅"), Emoji(emoji: "🦉"), Emoji(emoji: "🦇"),
            Emoji(emoji: "🐢"), Emoji(emoji: "🐍"), Emoji(emoji: "🦎"), Emoji(emoji: "🐊"), Emoji(emoji: "🐬"), Emoji(emoji: "🦭"),
            Emoji(emoji: "🐳"), Emoji(emoji: "🐋"), Emoji(emoji: "🦈"), Emoji(emoji: "🐙"), Emoji(emoji: "🦑"), Emoji(emoji: "🦞"),
            
            // Food & Drink
            Emoji(emoji: "🍏"), Emoji(emoji: "🍎"), Emoji(emoji: "🍐"), Emoji(emoji: "🍊"), Emoji(emoji: "🍋"), Emoji(emoji: "🍌"),
            Emoji(emoji: "🍉"), Emoji(emoji: "🍇"), Emoji(emoji: "🍓"), Emoji(emoji: "🫐"), Emoji(emoji: "🍈"), Emoji(emoji: "🍒"),
            Emoji(emoji: "🍑"), Emoji(emoji: "🍍"), Emoji(emoji: "🥭"), Emoji(emoji: "🥥"), Emoji(emoji: "🥝"), Emoji(emoji: "🍅"),
            Emoji(emoji: "🍆"), Emoji(emoji: "🥑"), Emoji(emoji: "🥦"), Emoji(emoji: "🥕"), Emoji(emoji: "🌽"), Emoji(emoji: "🌶"),
            Emoji(emoji: "🫑"), Emoji(emoji: "🥒"), Emoji(emoji: "🥬"), Emoji(emoji: "🥔"), Emoji(emoji: "🍠"), Emoji(emoji: "🍯"),
            Emoji(emoji: "🍞"), Emoji(emoji: "🥐"), Emoji(emoji: "🥖"), Emoji(emoji: "🥨"), Emoji(emoji: "🥞"), Emoji(emoji: "🧇"),
            
            // Travel & Places
            Emoji(emoji: "🚗"), Emoji(emoji: "🚕"), Emoji(emoji: "🚙"), Emoji(emoji: "🚌"), Emoji(emoji: "🚎"), Emoji(emoji: "🏎"),
            Emoji(emoji: "🚓"), Emoji(emoji: "🚑"), Emoji(emoji: "🚒"), Emoji(emoji: "🚚"), Emoji(emoji: "🚜"), Emoji(emoji: "✈️"),
            Emoji(emoji: "🚂"), Emoji(emoji: "🚀"), Emoji(emoji: "🛸"), Emoji(emoji: "🚁"), Emoji(emoji: "🚤"), Emoji(emoji: "🛳"),
            Emoji(emoji: "🚢"), Emoji(emoji: "⛵"), Emoji(emoji: "🛶"), Emoji(emoji: "🏠"), Emoji(emoji: "🏡"), Emoji(emoji: "🏢"),
            Emoji(emoji: "🏰"), Emoji(emoji: "🏯"), Emoji(emoji: "🏖"), Emoji(emoji: "🏜"), Emoji(emoji: "🗺"), Emoji(emoji: "🏕"),
            
            // Objects & Symbols
            Emoji(emoji: "⌚"), Emoji(emoji: "📱"), Emoji(emoji: "💻"), Emoji(emoji: "🖥"), Emoji(emoji: "🖨"), Emoji(emoji: "⌨️"),
            Emoji(emoji: "💽"), Emoji(emoji: "📀"), Emoji(emoji: "💾"), Emoji(emoji: "📷"), Emoji(emoji: "📹"), Emoji(emoji: "📞"),
            Emoji(emoji: "📺"), Emoji(emoji: "🔈"), Emoji(emoji: "🔉"), Emoji(emoji: "🔊"), Emoji(emoji: "🔇"), Emoji(emoji: "🔔"),
            Emoji(emoji: "🔕"), Emoji(emoji: "🔒"), Emoji(emoji: "🔓"), Emoji(emoji: "🔑"), Emoji(emoji: "🔨"), Emoji(emoji: "💡"),
            Emoji(emoji: "🧯"), Emoji(emoji: "🛠"), Emoji(emoji: "⚒"), Emoji(emoji: "⛏"), Emoji(emoji: "🗡"), Emoji(emoji: "🔫")
        ] 
    }
    
    init(router: AnyRouter, image: UIImage) {
        self.router = router
        self.image = image
        self.edittedImage = Image(uiImage: image)
        self.edittedImage2 = image
        
        Task {
            if let image = await edittedImage.render(convertToColorDepth: true) {
                await MainActor.run {
                    edittedImage2 = image
                }
            }
        }
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $selectedCropType
            .sink { [weak self] crop in
                guard let self else { return }
                if crop != nil {
                    switch crop {
                    case .circle:
                        presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
                    case .portrait:
                        presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 3/4)
                    case .landscape:
                        presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 4/3)
                        
                    case .square:
                        presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
                    case .custom(let cGSize):
                        presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: cGSize.height/cGSize.width)
                    case .none:
                        break
                    }
                    
                    showingCropper.toggle()
                }
            }
            .store(in: &cancellables)
        
//        $image
//            .sink { [weak self] image in
//                guard let self else { return }
//                edittedImage = Image(uiImage: image)
//            }
//            .store(in: &cancellables)
        
        $selectedType
            .combineLatest($addNewBox)
            .sink { [weak self] (type, addNewBox) in
                guard let self else { return }
                if type == .text {
                    if addNewBox {
                        textBoxes.append(TextBox())
                        currentIndex = textBoxes.count - 1
                        print(currentIndex)
                    }
                    showHeader = false
                } else {
                    showHeader = true
                }
            }
            .store(in: &cancellables)
        
        $edittedImage2
            .sink {  [weak self] image in
                guard let self else { return }
                
                let width = image.size.width
                let height = image.size.height
                
                currentImageHeightRatio = height/width
                currentImageWidthRatio = width/height
                
                let screenWidthRatio = (Constants.screenWidth - 12) / (Constants.screenHeight - 140 - UIApplication.topSafeAreaHeightTHM - UIApplication.bottomSafeAreaHeightTHM)
                
                if currentImageWidthRatio >= screenWidthRatio {
                    currentImageStyle = "landscape"
                } else {
                    currentImageStyle = "portrait"
                }
            }
            .store(in: &cancellables)
    }
    
    
    func cancelTextView() {
        // removing the textbox at current index
        textBoxes.remove(at: currentIndex)
        
        // setting the currentIndex as zero, so that when view updates it does not give error for out of range index.
        currentIndex = 0
        
        // updating this var so that text editing area hides.
        selectedType = nil
        
    }
    
    
    func dismissScreen() {
        router.dismissEnvironment()
    }
    
    
    func showCropOptionModalView() {
        router.showModal {
            SelectOptionModal(options: self.cropOptions) { [weak self] option in
                guard let self else { return }
                
                if option == "Landscape" {
                    selectedCropType = .landscape
                } else if option == "Portrait" {
                    selectedCropType = .portrait
                } else {
                    selectedCropType = .square
                }
                router.dismissModal()
            }
        }
        
    }
    
}

extension View {
    /// Usually you would pass  `@Environment(\.displayScale) var displayScale`
    @MainActor func render(convertToColorDepth: Bool = false, scale displayScale: CGFloat = 1) -> UIImage? {
        let renderer = ImageRenderer(content: self)

        renderer.scale = displayScale
        renderer.isOpaque = convertToColorDepth
        
        guard let image = renderer.uiImage else { return nil }
        
        if convertToColorDepth {
            return image.convertedToColorDepth(8)
        } else {
            return image
//            return image.convertedToColorDepth(8)
        }
    }
    
}
