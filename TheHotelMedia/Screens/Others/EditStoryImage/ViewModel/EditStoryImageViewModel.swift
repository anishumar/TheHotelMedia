//
//  EditStoryImageViewModel.swift
//  HotelMedia
//
//  Created by MAC on 11/09/24.
//

import SwiftUI
import SwiftUICoreImage
import Combine
import SwiftfulRouting
import AVFoundation

struct EditStoryVideoViewModel_Wrapper { // Just to isolate if needed, but I'll just append
}

struct LocationTagBox: Identifiable {
    var id = UUID().uuidString
    var placeName: String
    var lat: Double
    var lng: Double
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var scale: CGFloat = 1.0
    var lastScale: CGFloat = 1.0
    var rotation: Angle = .zero
    var lastRotation: Angle = .zero
}

class EditStoryVideoViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    
    @Published var videoURL: URL
    @Published var selectedType: EditButton? = nil
    @Published var textBoxes: [TextBox] = []
    @Published var addedEmojis: [EmojiBox] = []
    @Published var addNewBox: Bool = true
    @Published var currentIndex = 0
    @Published var showHeader: Bool = true
    @Published var showEmojiDeleteButon: Bool = false
    @Published var currentEmojiIndex: Int = 0
    @Published var taggedUsers: [TagBox] = []
    @Published var locationTag: LocationTagBox? = nil
    @Published var showUserSelectionSheet: Bool = false
    @Published var showLocationSelectionSheet: Bool = false
    
    var allEmojis: [Emoji] {
        return [
            // Smileys & Emotion
            Emoji(emoji: "😀"), Emoji(emoji: "😃"), Emoji(emoji: "😄"), Emoji(emoji: "😁"), Emoji(emoji: "😆"), Emoji(emoji: "😅"),
            Emoji(emoji: "😂"), Emoji(emoji: "🤣"), Emoji(emoji: "😊"), Emoji(emoji: "😇"), Emoji(emoji: "🙂"), Emoji(emoji: "🙃"),
            Emoji(emoji: "😉"), Emoji(emoji: "😌"), Emoji(emoji: "😍"), Emoji(emoji: "🥰"), Emoji(emoji: "😘"), Emoji(emoji: "😗"),
            Emoji(emoji: "😙"), Emoji(emoji: "😚"), Emoji(emoji: "😋"), Emoji(emoji: "😜"), Emoji(emoji: "🤪"), Emoji(emoji: "😝"),
            Emoji(emoji: "🤑"), Emoji(emoji: "🤗"), Emoji(emoji: "🤭"), Emoji(emoji: "🤫"), Emoji(emoji: "🤔"), Emoji(emoji: "🤐"),
            Emoji(emoji: "🤨"), Emoji(emoji: "😐"), Emoji(emoji: "😑"), Emoji(emoji: "😶"), Emoji(emoji: "😏"), Emoji(emoji: "😒"),
            Emoji(emoji: "🙄"), Emoji(emoji: "😬"), Emoji(emoji: "🤥"), Emoji(emoji: "😌"), Emoji(emoji: "😔"), Emoji(emoji: "😪"),
            Emoji(emoji: "🤤"), Emoji(emoji: "😴"), Emoji(emoji: "😷"), Emoji(emoji: "🤒"), Emoji(emoji: "🤕"), Emoji(emoji: "🤢"),
            Emoji(emoji: "🤮"), Emoji(emoji: "🤧"), Emoji(emoji: "🥵"), Emoji(emoji: "🥶"), Emoji(emoji: "🥴"), Emoji(emoji: "😵"),
            Emoji(emoji: "🤯"), Emoji(emoji: "🤠"), Emoji(emoji: "🥳"), Emoji(emoji: "😎"), Emoji(emoji: "🤓"), Emoji(emoji: "🧐"),
            
            // Gestures & Hands
            Emoji(emoji: "👋"), Emoji(emoji: "🤚"), Emoji(emoji: "🖐"), Emoji(emoji: "✋"), Emoji(emoji: "👌"), Emoji(emoji: "✌️"),
            Emoji(emoji: "🤞"), Emoji(emoji: "🤟"), Emoji(emoji: "🤘"), Emoji(emoji: "🤙"), Emoji(emoji: "👈"), Emoji(emoji: "👉"),
            Emoji(emoji: "👆"), Emoji(emoji: "👇"), Emoji(emoji: "👍"), Emoji(emoji: "👎"), Emoji(emoji: "✊"), Emoji(emoji: "👊"),
            Emoji(emoji: "🤛"), Emoji(emoji: "🤜"), Emoji(emoji: "👏"), Emoji(emoji: "🙌"), Emoji(emoji: "👐"), Emoji(emoji: "🤲"),
            
            // Animals & Nature
            Emoji(emoji: "🐶"), Emoji(emoji: "🐱"), Emoji(emoji: "🐭"), Emoji(emoji: "🐹"), Emoji(emoji: "🐰"), Emoji(emoji: "🦊"),
            Emoji(emoji: "🐻"), Emoji(emoji: "🐼"), Emoji(emoji: "🐨"), Emoji(emoji: "🐯"), Emoji(emoji: "🦁"), Emoji(emoji: "🐮"),
            Emoji(emoji: "🐷"), Emoji(emoji: "🐽"), Emoji(emoji: "🐸"), Emoji(emoji: "🐵"), Emoji(emoji: "🙈"), Emoji(emoji: "🙉"),
            Emoji(emoji: "🙊"), Emoji(emoji: "🐒"), Emoji(emoji: "🐔"), Emoji(emoji: "🐧"), Emoji(emoji: "🐦"), Emoji(emoji: "🐤"),
            Emoji(emoji: "🐣"), Emoji(emoji: "🐥"), Emoji(emoji: "🦆"), Emoji(emoji: "🦅"), Emoji(emoji: "🦉"), Emoji(emoji: "🦇"),
            
            // Food & Drink
            Emoji(emoji: "🍏"), Emoji(emoji: "🍎"), Emoji(emoji: "🍐"), Emoji(emoji: "🍊"), Emoji(emoji: "🍋"), Emoji(emoji: "🍌"),
            Emoji(emoji: "🍉"), Emoji(emoji: "🍇"), Emoji(emoji: "🍓"), Emoji(emoji: "🫐"), Emoji(emoji: "🍈"), Emoji(emoji: "🍒"),
            Emoji(emoji: "🍑"), Emoji(emoji: "🍍"), Emoji(emoji: "🥭"), Emoji(emoji: "🥥"), Emoji(emoji: "🥝"), Emoji(emoji: "🍅"),
            Emoji(emoji: "🍆"), Emoji(emoji: "🥑"), Emoji(emoji: "🥦"), Emoji(emoji: "🥕"), Emoji(emoji: "🌽"), Emoji(emoji: "🌶"),
            
            // Travel & Places
            Emoji(emoji: "🚗"), Emoji(emoji: "🚕"), Emoji(emoji: "🚙"), Emoji(emoji: "🚌"), Emoji(emoji: "🚎"), Emoji(emoji: "🏎"),
            Emoji(emoji: "🚓"), Emoji(emoji: "🚑"), Emoji(emoji: "🚒"), Emoji(emoji: "🚚"), Emoji(emoji: "🚜"), Emoji(emoji: "✈️"),
            Emoji(emoji: "🚂"), Emoji(emoji: "🚀"), Emoji(emoji: "🛸"), Emoji(emoji: "🚁"), Emoji(emoji: "🚤"), Emoji(emoji: "🛳"),
            
            // Objects & Symbols
            Emoji(emoji: "⌚"), Emoji(emoji: "📱"), Emoji(emoji: "💻"), Emoji(emoji: "🖥"), Emoji(emoji: "🖨"), Emoji(emoji: "⌨️"),
            Emoji(emoji: "💽"), Emoji(emoji: "📀"), Emoji(emoji: "💾"), Emoji(emoji: "📷"), Emoji(emoji: "📹"), Emoji(emoji: "📞"),
            Emoji(emoji: "📺"), Emoji(emoji: "🔈"), Emoji(emoji: "🔉"), Emoji(emoji: "🔊"), Emoji(emoji: "🔇"), Emoji(emoji: "🔔"),
            Emoji(emoji: "🔕"), Emoji(emoji: "🔒"), Emoji(emoji: "🔓"), Emoji(emoji: "🔑"), Emoji(emoji: "🔨"), Emoji(emoji: "💡")
        ]
    }
    
    init(router: AnyRouter, videoURL: URL) {
        self.router = router
        self.videoURL = videoURL
        addSubscribers()
    }
    
    func addSubscribers() {
        $selectedType
            .combineLatest($addNewBox)
            .sink { [weak self] (type, addNewBox) in
                guard let self else { return }
                if type == .text {
                    if addNewBox {
                        textBoxes.append(TextBox())
                        currentIndex = textBoxes.count - 1
                    }
                    showHeader = false
                } else {
                    showHeader = true
                }
            }
            .store(in: &cancellables)
    }
    
    func cancelTextView() {
        if !textBoxes.isEmpty && currentIndex < textBoxes.count {
            textBoxes.remove(at: currentIndex)
        }
        currentIndex = 0
        selectedType = nil
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    func showCheckinScreen() {
        router.showScreen(.fullScreenCover) { router in
            CheckinScreen(viewModel: CheckinViewModel(router: router, onSelectingPlace: { [weak self] place in
                guard let self else { return }
                
                if let name = place.businessProfileRef?.name,
                   let lat = place.businessProfileRef?.address?.lat,
                   let lng = place.businessProfileRef?.address?.lng {
                    
                    self.locationTag = LocationTagBox(placeName: name, lat: lat, lng: lng)
                    self.selectedType = .tag // Or a new type for location if needed, but managing overlays similarly
                    // If we want to switch to location tag editing specifically, we might need a separate state or just handle it in the view
                }
            }))
            .environmentObject(ThemeManager.shared)
        }
    }
}



struct TagBox: Identifiable {
    var id = UUID().uuidString
    var userID: String
    var username: String
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var scale: CGFloat = 1.0
    var lastScale: CGFloat = 1.0
    var rotation: Angle = .zero
    var lastRotation: Angle = .zero
}

class EditStoryImageViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    @Published var isModalSelection: Bool = false
    @Published var selectedType: EditButton? = nil
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
    @Published var taggedUsers: [TagBox] = []
    @Published var locationTag: LocationTagBox? = nil
    
    @Published var showUserSelectionSheet: Bool = false
    @Published var showLocationSelectionSheet: Bool = false
    
    var allEmojis: [Emoji] {
        return [
            // Smileys & Emotion
            Emoji(emoji: "😀"), Emoji(emoji: "😃"), Emoji(emoji: "😄"), Emoji(emoji: "😁"), Emoji(emoji: "😆"), Emoji(emoji: "😅"),
            Emoji(emoji: "😂"), Emoji(emoji: "🤣"), Emoji(emoji: "😊"), Emoji(emoji: "😇"), Emoji(emoji: "🙂"), Emoji(emoji: "🙃"),
            Emoji(emoji: "😉"), Emoji(emoji: "😌"), Emoji(emoji: "😍"), Emoji(emoji: "🥰"), Emoji(emoji: "😘"), Emoji(emoji: "😗"),
            Emoji(emoji: "😙"), Emoji(emoji: "😚"), Emoji(emoji: "😋"), Emoji(emoji: "😜"), Emoji(emoji: "🤪"), Emoji(emoji: "😝"),
            Emoji(emoji: "🤑"), Emoji(emoji: "🤗"), Emoji(emoji: "🤭"), Emoji(emoji: "🤫"), Emoji(emoji: "🤔"), Emoji(emoji: "🤐"),
            Emoji(emoji: "🤨"), Emoji(emoji: "😐"), Emoji(emoji: "😑"), Emoji(emoji: "😶"), Emoji(emoji: "😏"), Emoji(emoji: "😒"),
            Emoji(emoji: "🙄"), Emoji(emoji: "😬"), Emoji(emoji: "🤥"), Emoji(emoji: "😌"), Emoji(emoji: "😔"), Emoji(emoji: "😪"),
            Emoji(emoji: "🤤"), Emoji(emoji: "😴"), Emoji(emoji: "😷"), Emoji(emoji: "🤒"), Emoji(emoji: "🤕"), Emoji(emoji: "🤢"),
            Emoji(emoji: "🤮"), Emoji(emoji: "🤧"), Emoji(emoji: "🥵"), Emoji(emoji: "🥶"), Emoji(emoji: "🥴"), Emoji(emoji: "😵"),
            Emoji(emoji: "🤯"), Emoji(emoji: "🤠"), Emoji(emoji: "🥳"), Emoji(emoji: "😎"), Emoji(emoji: "🤓"), Emoji(emoji: "🧐"),
            
            // Gestures & Hands
            Emoji(emoji: "👋"), Emoji(emoji: "🤚"), Emoji(emoji: "🖐"), Emoji(emoji: "✋"), Emoji(emoji: "👌"), Emoji(emoji: "✌️"),
            Emoji(emoji: "🤞"), Emoji(emoji: "🤟"), Emoji(emoji: "🤘"), Emoji(emoji: "🤙"), Emoji(emoji: "👈"), Emoji(emoji: "👉"),
            Emoji(emoji: "👆"), Emoji(emoji: "👇"), Emoji(emoji: "👍"), Emoji(emoji: "👎"), Emoji(emoji: "✊"), Emoji(emoji: "👊"),
            Emoji(emoji: "🤛"), Emoji(emoji: "🤜"), Emoji(emoji: "👏"), Emoji(emoji: "🙌"), Emoji(emoji: "👐"), Emoji(emoji: "🤲"),
            
            // Animals & Nature
            Emoji(emoji: "🐶"), Emoji(emoji: "🐱"), Emoji(emoji: "🐭"), Emoji(emoji: "🐹"), Emoji(emoji: "🐰"), Emoji(emoji: "🦊"),
            Emoji(emoji: "🐻"), Emoji(emoji: "🐼"), Emoji(emoji: "🐨"), Emoji(emoji: "🐯"), Emoji(emoji: "🦁"), Emoji(emoji: "🐮"),
            Emoji(emoji: "🐷"), Emoji(emoji: "🐽"), Emoji(emoji: "🐸"), Emoji(emoji: "🐵"), Emoji(emoji: "🙈"), Emoji(emoji: "🙉"),
            Emoji(emoji: "🙊"), Emoji(emoji: "🐒"), Emoji(emoji: "🐔"), Emoji(emoji: "🐧"), Emoji(emoji: "🐦"), Emoji(emoji: "🐤"),
            Emoji(emoji: "🐣"), Emoji(emoji: "🐥"), Emoji(emoji: "🦆"), Emoji(emoji: "🦅"), Emoji(emoji: "🦉"), Emoji(emoji: "🦇"),
            
            // Food & Drink
            Emoji(emoji: "🍏"), Emoji(emoji: "🍎"), Emoji(emoji: "🍐"), Emoji(emoji: "🍊"), Emoji(emoji: "🍋"), Emoji(emoji: "🍌"),
            Emoji(emoji: "🍉"), Emoji(emoji: "🍇"), Emoji(emoji: "🍓"), Emoji(emoji: "🫐"), Emoji(emoji: "🍈"), Emoji(emoji: "🍒"),
            Emoji(emoji: "🍑"), Emoji(emoji: "🍍"), Emoji(emoji: "🥭"), Emoji(emoji: "🥥"), Emoji(emoji: "🥝"), Emoji(emoji: "🍅"),
            Emoji(emoji: "🍆"), Emoji(emoji: "🥑"), Emoji(emoji: "🥦"), Emoji(emoji: "🥕"), Emoji(emoji: "🌽"), Emoji(emoji: "🌶"),
            
            // Travel & Places
            Emoji(emoji: "🚗"), Emoji(emoji: "🚕"), Emoji(emoji: "🚙"), Emoji(emoji: "🚌"), Emoji(emoji: "🚎"), Emoji(emoji: "🏎"),
            Emoji(emoji: "🚓"), Emoji(emoji: "🚑"), Emoji(emoji: "🚒"), Emoji(emoji: "🚚"), Emoji(emoji: "🚜"), Emoji(emoji: "✈️"),
            Emoji(emoji: "🚂"), Emoji(emoji: "🚀"), Emoji(emoji: "🛸"), Emoji(emoji: "🚁"), Emoji(emoji: "🚤"), Emoji(emoji: "🛳"),
            
            // Objects & Symbols
            Emoji(emoji: "⌚"), Emoji(emoji: "📱"), Emoji(emoji: "💻"), Emoji(emoji: "🖥"), Emoji(emoji: "🖨"), Emoji(emoji: "⌨️"),
            Emoji(emoji: "💽"), Emoji(emoji: "📀"), Emoji(emoji: "💾"), Emoji(emoji: "📷"), Emoji(emoji: "📹"), Emoji(emoji: "📞"),
            Emoji(emoji: "📺"), Emoji(emoji: "🔈"), Emoji(emoji: "🔉"), Emoji(emoji: "🔊"), Emoji(emoji: "🔇"), Emoji(emoji: "🔔"),
            Emoji(emoji: "🔕"), Emoji(emoji: "🔒"), Emoji(emoji: "🔓"), Emoji(emoji: "🔑"), Emoji(emoji: "🔨"), Emoji(emoji: "💡")
        ]
    }
    
    init(router: AnyRouter, image: UIImage) {
        self.router = router
        self.image = image
        self.edittedImage = Image(uiImage: image)
        self.edittedImage2 = image
        
        Task {
            if let image = await edittedImage.render() {
                await MainActor.run {
                    edittedImage2 = image
                }
            }
        }
        addSubscribers()
    }
    
    
    func addSubscribers() {
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
//        router.dismissEnvironment()
        router.dismissScreen()
    }
    
    func showCheckinScreen() {
        router.showScreen(.fullScreenCover) { router in
            CheckinScreen(viewModel: CheckinViewModel(router: router, onSelectingPlace: { [weak self] place in
                guard let self else { return }
                
                if let name = place.businessProfileRef?.name,
                   let lat = place.businessProfileRef?.address?.lat,
                   let lng = place.businessProfileRef?.address?.lng {
                    
                    self.locationTag = LocationTagBox(placeName: name, lat: lat, lng: lng)
                    self.selectedType = .tag
                }
            }))
            .environmentObject(ThemeManager.shared)
        }
    }
}
