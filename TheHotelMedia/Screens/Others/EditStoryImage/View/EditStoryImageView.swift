//
//  EditStoryImageView.swift
//  HotelMedia
//
//  Created by MAC on 11/09/24.
//

import SwiftUI
import AVKit

struct EditStoryVideoView: View {
    
    @StateObject var viewModel: EditStoryVideoViewModel
    var returnedVideo: ((URL, StoryTaggingData) -> Void)?
    var onDismissed: (() -> Void)?
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var player: AVPlayer?
    
    var emojiGrid: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            editStoryVideoHeader
                .opacity(viewModel.showHeader && !viewModel.showEmojiDeleteButon ? 1.0 : 0)
                .allowsHitTesting(viewModel.showHeader && !viewModel.showEmojiDeleteButon)
                .overlay {
                    ZStack {
                        if viewModel.showEmojiDeleteButon {
                            editStoryVideoEmojiEditButtons
                                .padding(.top, 16)
                        }
                        
                        if viewModel.selectedType == .text {
                            editStoryVideoTextEditButtons
                                .padding(.top, 16)
                        }
                    }
                    .zIndex(2.0)
                }
            
            VStack {
                ZStack {
                    videoPlayerWithOverlays(roundedCorner: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .overlay(
                HStack {
                    if viewModel.selectedType == .emoji {
                        editStoryVideoEmojiSection
                    } else if viewModel.selectedType == .filter {
                        Text("video_filter_coming_soon".localized(localizationManager.language))
                            .font(.custom(Constants.comicFont, size: 14))
                            .foregroundColor(themeManager.currentTheme.label)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                            )
                    }
                }
                , alignment: .bottom
            )
            
            editStoryVideoBottomButtonSection
                .padding(.horizontal, 24)
                .frame(height: 64)
                .background(
                    editStoryVideoGrayCapsuleBackground
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
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .sheet(isPresented: $viewModel.showUserSelectionSheet) {
            UserSelectionView(viewModel: UserSelectionViewModel(router: viewModel.router, onUserSelected: { id, username in
                let newTag = TagBox(userID: id, username: username)
                viewModel.taggedUsers.append(newTag)
                viewModel.selectedType = .tag
            }))
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Functions
extension EditStoryVideoView {
    
    private func setupPlayer() {
        print("📹 [EditStoryVideoView] Setting up player with URL: \(viewModel.videoURL)")
        
        if !FileManager.default.fileExists(atPath: viewModel.videoURL.path) {
            print("❌ [EditStoryVideoView] Video file NOT found at path: \(viewModel.videoURL.path)")
        }
        
        player = AVPlayer(url: viewModel.videoURL)
        player?.actionAtItemEnd = .none
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        player?.play()
        print("▶️ [EditStoryVideoView] Player started")
    }
    
    func getIndex(textBox: TextBox) -> Int {
        return viewModel.textBoxes.firstIndex { $0.id == textBox.id } ?? 0
    }
    
    func getEmojiIndex(emojiBox: EmojiBox) -> Int {
        return viewModel.addedEmojis.firstIndex { $0.id == emojiBox.id } ?? 0
    }
    
    func onTickButtonPressed() {
        let taggedUserIDs = viewModel.taggedUsers.map { $0.userID }
        // For positions, we might want to pass the whole TagBox or a mapped structure if API supports it.
        // Current API has userTaggedPositionX/Y (single user?). The prompt asked for "user and location tagging... include positional data".
        // The data model has `userTagged` (String?) and `userTaggedId` (String?). It seems it might only support ONE tagged user or a string representation?
        // Wait, GetStoriesResponse has `userTagged` (String?).
        // Let's assume we pass the FIRST tagged user for now if the API only takes one set of coordinates, or check if we can pass multiple.
        // The updated MainTabBarViewModel signature takes `userTagged`, `userTaggedId` strings.
        
        var userTagged: String? = nil
        var userTaggedId: String? = nil
        var userTaggedPositionX: Double? = nil
        var userTaggedPositionY: Double? = nil
        
        if let firstUser = viewModel.taggedUsers.first {
            userTagged = firstUser.username
            userTaggedId = firstUser.userID
            userTaggedPositionX = firstUser.offset.width
            userTaggedPositionY = firstUser.offset.height
        }
        
        var placeName: String? = nil
        var lat: Double? = nil
        var lng: Double? = nil
        var locationPositionX: Double? = nil
        var locationPositionY: Double? = nil
        
        if let loc = viewModel.locationTag {
            placeName = loc.placeName
            lat = loc.lat
            lng = loc.lng
            locationPositionX = loc.offset.width
            locationPositionY = loc.offset.height
        }
        
        let taggingData = StoryTaggingData(
            mentions: taggedUserIDs,
            placeName: placeName,
            lat: lat,
            lng: lng,
            locationPositionX: locationPositionX,
            locationPositionY: locationPositionY,
            userTagged: userTagged,
            userTaggedId: userTaggedId,
            userTaggedPositionX: userTaggedPositionX,
            userTaggedPositionY: userTaggedPositionY
        )
        
        returnedVideo?(viewModel.videoURL, taggingData)
    }
}

// MARK: - Components
extension EditStoryVideoView {
    
    private var editStoryVideoHeader: some View {
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
            
            Text("edit_story".localized(localizationManager.language))
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
    
    private var editStoryVideoTextEditButtons: some View {
        HStack {
            Button(action: {
                viewModel.selectedType = nil
            }, label: {
                Text("add".localized(localizationManager.language))
                    .font(.custom(Constants.comicBold, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
            })
            
            Spacer()
            
            if !viewModel.textBoxes.isEmpty {
                ColorPicker("", selection: $viewModel.textBoxes[viewModel.currentIndex].textColor)
                    .labelsHidden()
            }
            
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
    
    private func videoPlayerWithOverlays(roundedCorner: Bool) -> some View {
        let width = UIScreen.main.bounds.width - 12
        let height = UIScreen.main.bounds.height - 140 - UIApplication.topSafeAreaHeightTHM - UIApplication.bottomSafeAreaHeightTHM
        
        return ZStack {
            if let player = player {
                CustomVideoPlayer(player: player, contentMode: .resizeAspect, backgroundColor: UIColor(themeManager.currentTheme.backgroundColor))
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: roundedCorner ? 20 : 0))
            } else {
                Rectangle()
                    .fill(.black)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: roundedCorner ? 20 : 0))
            }
            
            // Overlays Container
            ZStack {
                ForEach(viewModel.textBoxes) { box in
                    editStoryVideoTextBoxView(box: box)
                }
                
                ForEach(viewModel.addedEmojis) { box in
                    editStoryVideoEmojiBoxView(box: box)
                }
                
                ForEach(viewModel.taggedUsers) { box in
                    editStoryVideoTagBoxView(box: box)
                }
                
                if let locationTag = viewModel.locationTag {
                    editStoryVideoLocationTagBoxView(box: locationTag)
                }
            }
            .frame(width: width, height: height)
            
            if viewModel.selectedType == .text {
                themeManager.currentTheme.black75_white75
                    .ignoresSafeArea()
                    .onTapGesture {
                        endEditing()
                    }
                
                VStack(alignment: .center) {
                    TextField(
                        "type_here".localized(localizationManager.language),
                        text: $viewModel.textBoxes[viewModel.currentIndex].text,
                        prompt: Text("type_here".localized(localizationManager.language))
                            .font(.system(size: 25))
                            .foregroundColor(viewModel.textBoxes[viewModel.currentIndex].textColor),
                        axis: .vertical
                    )
                    .font(.system(size: 25))
                    .foregroundColor(viewModel.textBoxes[viewModel.currentIndex].textColor)
                    .multilineTextAlignment(.center)
                    .colorScheme(.dark)
                    .padding(.horizontal, 12)
                }
                .frame(width: Constants.screenWidth, alignment: .center)
                .frame(maxHeight: Constants.screenHeight * 0.3)
            }
        }
    }
    
    private func editStoryVideoTextBoxView(box: TextBox) -> some View {
        let index = getIndex(textBox: box)
        return Text(viewModel.textBoxes[viewModel.currentIndex].id == box.id && viewModel.selectedType == .text ? "" : box.text)
            .fontWeight(box.isBold ? .bold : .none)
            .font(.system(size: box.fontSize))
            .multilineTextAlignment(.center)
            .foregroundColor(box.textColor)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .rotationEffect(box.angle)
            .offset(box.offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newTranslation = CGSize(
                            width: value.translation.width + box.lastOffset.width,
                            height: value.translation.height + box.lastOffset.height
                        )
                        viewModel.textBoxes[index].offset = newTranslation
                    }
                    .onEnded { value in
                        viewModel.textBoxes[index].lastOffset = viewModel.textBoxes[index].offset
                    }
            )
            .simultaneousGesture(
                RotationGesture()
                    .onChanged { angle in
                        viewModel.textBoxes[index].angle = angle + box.lastAngle
                    }
                    .onEnded { angle in
                        viewModel.textBoxes[index].lastAngle = viewModel.textBoxes[index].angle
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newFontSize = box.lastFontSize * value
                        viewModel.textBoxes[index].fontSize = max(10, newFontSize)
                    }
                    .onEnded { value in
                        viewModel.textBoxes[index].lastFontSize = viewModel.textBoxes[index].fontSize
                    }
            )
            .onTapGesture {
                viewModel.currentIndex = index
                viewModel.addNewBox = false
                viewModel.selectedType = .text
            }
            .opacity(viewModel.textBoxes[viewModel.currentIndex].id == box.id && viewModel.selectedType == .text ? 0.0 : 1.0)
    }
    
    private func editStoryVideoEmojiBoxView(box: EmojiBox) -> some View {
        let index = getEmojiIndex(emojiBox: box)
        return Text(box.emoji.emoji)
            .font(.system(size: box.fontSize))
            .shadow(color: viewModel.addedEmojis[viewModel.currentEmojiIndex].id == box.id && viewModel.showEmojiDeleteButon ? .black : .clear, radius: 10)
            .rotationEffect(box.angle)
            .offset(box.offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newTranslation = CGSize(width: value.translation.width + box.lastOffset.width, height: value.translation.height + box.lastOffset.height)
                        viewModel.addedEmojis[index].offset = newTranslation
                    }
                    .onEnded { value in
                        viewModel.addedEmojis[index].lastOffset = viewModel.addedEmojis[index].offset
                    }
            )
            .simultaneousGesture(
                RotationGesture()
                    .onChanged { angle in
                        viewModel.addedEmojis[index].angle = angle + box.lastAngle
                    }
                    .onEnded { angle in
                        viewModel.addedEmojis[index].lastAngle = viewModel.addedEmojis[index].angle
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        viewModel.addedEmojis[index].fontSize = box.lastFontSize * value
                    }
                    .onEnded { value in
                        viewModel.addedEmojis[index].lastFontSize = viewModel.addedEmojis[index].fontSize
                    }
            )
            .onTapGesture {
                viewModel.showEmojiDeleteButon = true
                viewModel.currentEmojiIndex = index
            }
    }
    
    private func editStoryVideoTagBoxView(box: TagBox) -> some View {
        let index = viewModel.taggedUsers.firstIndex { $0.id == box.id } ?? 0
        return VStack {
            Text("@\(box.username)")
                .font(.custom(Constants.comicBold, size: 20))
                .foregroundColor(.hmIndigo)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 5)
                )
        }
        .rotationEffect(box.rotation)
        .scaleEffect(box.scale)
        .offset(box.offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let newTranslation = CGSize(
                        width: value.translation.width + box.lastOffset.width,
                        height: value.translation.height + box.lastOffset.height
                    )
                    viewModel.taggedUsers[index].offset = newTranslation
                }
                .onEnded { value in
                    viewModel.taggedUsers[index].lastOffset = viewModel.taggedUsers[index].offset
                }
        )
        .simultaneousGesture(
            RotationGesture()
                .onChanged { angle in
                    viewModel.taggedUsers[index].rotation = angle + box.lastRotation
                }
                .onEnded { angle in
                    viewModel.taggedUsers[index].lastRotation = viewModel.taggedUsers[index].rotation
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    viewModel.taggedUsers[index].scale = box.lastScale * value
                }
                .onEnded { value in
                    viewModel.taggedUsers[index].lastScale = viewModel.taggedUsers[index].scale
                }
        )
    }

    private var editStoryVideoEmojiEditButtons: some View {
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

    private var editStoryVideoBottomButtonSection: some View {
        HStack {
            editStoryVideoButton(type: .filter)
            Spacer()
            editStoryVideoButton(type: .emoji)
            Spacer()
            editStoryVideoButton(type: .text) {
                viewModel.addNewBox = true
            }
            Spacer()
            editStoryVideoButton(type: .tag) {
                viewModel.showUserSelectionSheet = true
            }
            Spacer()
            editStoryVideoButton(type: .location) {
                viewModel.showCheckinScreen()
            }
        }
    }
    
    private func editStoryVideoButton(type: EditButton, action: (() -> Void)? = nil ) -> some View {
        VStack(spacing: 4) {
            if type == .tag {
                Image(themeManager.currentTheme.TagIcon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundColor(viewModel.selectedType == nil ? themeManager.currentTheme.white08_darkGray08 : viewModel.selectedType == type ? .hmIndigo : themeManager.currentTheme.white08_darkGray08)
            } else {
                Image(type.rawValue.capitalized)
                    .renderingMode(.template)
                    .font(.system(size: 26))
                    .foregroundColor(viewModel.selectedType == nil ? themeManager.currentTheme.white08_darkGray08 : viewModel.selectedType == type ? .hmIndigo : themeManager.currentTheme.white08_darkGray08)
            }
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
    

    
    private func editStoryVideoLocationTagBoxView(box: LocationTagBox) -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                Text(box.placeName)
                    .font(.custom(Constants.comicBold, size: 20))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [.hmIndigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .black.opacity(0.2), radius: 5)
            )
        }
        .rotationEffect(box.rotation)
        .scaleEffect(box.scale)
        .offset(box.offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if var loc = viewModel.locationTag {
                         let newTranslation = CGSize(
                             width: value.translation.width + loc.lastOffset.width,
                             height: value.translation.height + loc.lastOffset.height
                         )
                         loc.offset = newTranslation
                         viewModel.locationTag = loc
                    }
                }
                .onEnded { value in
                    if var loc = viewModel.locationTag {
                        loc.lastOffset = loc.offset
                        viewModel.locationTag = loc
                    }
                }
        )
        .simultaneousGesture(
            RotationGesture()
                .onChanged { angle in
                    if var loc = viewModel.locationTag {
                        loc.rotation = angle + loc.lastRotation
                        viewModel.locationTag = loc
                    }
                }
                .onEnded { angle in
                    if var loc = viewModel.locationTag {
                        loc.lastRotation = loc.rotation
                        viewModel.locationTag = loc
                    }
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    if var loc = viewModel.locationTag {
                        loc.scale = loc.lastScale * value
                        viewModel.locationTag = loc
                    }
                }
                .onEnded { value in
                    if var loc = viewModel.locationTag {
                        loc.lastScale = loc.scale
                        viewModel.locationTag = loc
                    }
                }
        )
    }
    
    private var editStoryVideoGrayCapsuleBackground: some View {
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
    
    private var editStoryVideoEmojiSection: some View {
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

struct EditStoryImageView: View {
    
    @StateObject var viewModel: EditStoryImageViewModel
    var returnedImage: ((UIImage, StoryTaggingData) -> Void)?
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
                    if viewModel.selectedType == .emoji {
                        emojiSection
                        
                    } else if viewModel.selectedType == .filter {
                        filterScrollViewStored
                            .frame(height: 64)
                            .background(
                                indigoCapsuleBackground
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
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                viewModel.showCropView = true
//            }
//        }


        .sheet(isPresented: $viewModel.showUserSelectionSheet) {
            UserSelectionView(viewModel: UserSelectionViewModel(router: viewModel.router, onUserSelected: { id, username in
                let newTag = TagBox(userID: id, username: username)
                viewModel.taggedUsers.append(newTag)
                viewModel.selectedType = .tag
            }))
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}


// MARK: - Preview
struct EditStoryImageView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditStoryImageView(viewModel: EditStoryImageViewModel(router: router, image: UIImage(named: "Landscape1")!))
    }
}


// MARK: - Functions

extension EditStoryImageView {
    
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
        // Render image first
        if let uiImage = edittedImageView(roundedCorner: false).render(convertToColorDepth: true, scale: Constants.scale) {
            
            let taggedUserIDs = viewModel.taggedUsers.map { $0.userID }
            
            var userTagged: String? = nil
            var userTaggedId: String? = nil
            var userTaggedPositionX: Double? = nil
            var userTaggedPositionY: Double? = nil
            
            if let firstUser = viewModel.taggedUsers.first {
                userTagged = firstUser.username
                userTaggedId = firstUser.userID
                userTaggedPositionX = firstUser.offset.width
                userTaggedPositionY = firstUser.offset.height
            }
            
            var placeName: String? = nil
            var lat: Double? = nil
            var lng: Double? = nil
            var locationPositionX: Double? = nil
            var locationPositionY: Double? = nil
            
            if let loc = viewModel.locationTag {
                placeName = loc.placeName
                lat = loc.lat
                lng = loc.lng
                locationPositionX = loc.offset.width
                locationPositionY = loc.offset.height
            }
            
            let taggingData = StoryTaggingData(
                mentions: taggedUserIDs,
                placeName: placeName,
                lat: lat,
                lng: lng,
                locationPositionX: locationPositionX,
                locationPositionY: locationPositionY,
                userTagged: userTagged,
                userTaggedId: userTaggedId,
                userTaggedPositionX: userTaggedPositionX,
                userTaggedPositionY: userTaggedPositionY
            )
            
            returnedImage?(uiImage, taggingData)
        }
    }
}


// MARK: - Components
extension EditStoryImageView {
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
            
            Text("edit_story".localized(localizationManager.language))
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
                .scaledToFit()
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
                .overlay {
                    ZStack {
                        ForEach(viewModel.taggedUsers) { box in
                            tagBoxView(box: box)
                        }
                        
                        if let locationTag = viewModel.locationTag {
                            locationTagBoxView(box: locationTag)
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
                }
                .frame(width: Constants.screenWidth, alignment: .center)
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
                    .foregroundColor(.white)
                    
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
        
        return Text(viewModel.textBoxes[viewModel.currentIndex].id == box.id && viewModel.selectedType == .text ? "" : box.text)
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
            if type == .tag {
                Image(themeManager.currentTheme.TagIcon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundColor(viewModel.selectedType == nil ? themeManager.currentTheme.white08_darkGray08 : viewModel.selectedType == type ? .hmIndigo : themeManager.currentTheme.white08_darkGray08)
            } else {
                Image(type.rawValue.capitalized)
                    .renderingMode(.template)
                    .font(.system(size: 26))
                    .foregroundColor(viewModel.selectedType == nil ? themeManager.currentTheme.white08_darkGray08 : viewModel.selectedType == type ? .hmIndigo : themeManager.currentTheme.white08_darkGray08)
            }
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
            bottomButton(type: .filter)
            Spacer()
            bottomButton(type: .emoji)
            Spacer()
            bottomButton(type: .text) {
                // updating this bool so that new TextBox gets created.
                viewModel.addNewBox = true
            }
            Spacer()
            bottomButton(type: .tag) {
                viewModel.showUserSelectionSheet = true
            }
            Spacer()
            bottomButton(type: .location) {
                viewModel.showCheckinScreen()
            }
        }
    }
    
    private func locationTagBoxView(box: LocationTagBox) -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                Text(box.placeName)
                    .font(.custom(Constants.comicBold, size: 20))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [.hmIndigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .black.opacity(0.2), radius: 5)
            )
        }
        .rotationEffect(box.rotation)
        .scaleEffect(box.scale)
        .offset(box.offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if var loc = viewModel.locationTag {
                         let newTranslation = CGSize(
                             width: value.translation.width + loc.lastOffset.width,
                             height: value.translation.height + loc.lastOffset.height
                         )
                         loc.offset = newTranslation
                         viewModel.locationTag = loc
                    }
                }
                .onEnded { value in
                    if var loc = viewModel.locationTag {
                        loc.lastOffset = loc.offset
                        viewModel.locationTag = loc
                    }
                }
        )
        .simultaneousGesture(
            RotationGesture()
                .onChanged { angle in
                    if var loc = viewModel.locationTag {
                        loc.rotation = angle + loc.lastRotation
                        viewModel.locationTag = loc
                    }
                }
                .onEnded { angle in
                    if var loc = viewModel.locationTag {
                        loc.lastRotation = loc.rotation
                        viewModel.locationTag = loc
                    }
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    if var loc = viewModel.locationTag {
                        loc.scale = loc.lastScale * value
                        viewModel.locationTag = loc
                    }
                }
                .onEnded { value in
                    if var loc = viewModel.locationTag {
                        loc.lastScale = loc.scale
                        viewModel.locationTag = loc
                    }
                }
        )
    }
    
    private func tagBoxView(box: TagBox) -> some View {
        let index = viewModel.taggedUsers.firstIndex { $0.id == box.id } ?? 0
        
        return VStack {
            Text("@\(box.username)")
                .font(.custom(Constants.comicBold, size: 20)) // Fixed size for now, scaled by scaleEffect
                .foregroundColor(.hmIndigo)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 5)
                )
        }
        .rotationEffect(box.rotation)
        .scaleEffect(box.scale)
        .offset(box.offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let newTranslation = CGSize(
                        width: value.translation.width + box.lastOffset.width,
                        height: value.translation.height + box.lastOffset.height
                    )
                    viewModel.taggedUsers[index].offset = newTranslation
                }
                .onEnded { value in
                    viewModel.taggedUsers[index].lastOffset = CGSize(
                        width: value.translation.width + box.lastOffset.width,
                        height: value.translation.height + box.lastOffset.height
                    )
                }
        )
        .simultaneousGesture(
            RotationGesture()
                .onChanged { angle in
                    viewModel.taggedUsers[index].rotation = angle + box.lastRotation
                }
                .onEnded { angle in
                    viewModel.taggedUsers[index].lastRotation = angle + box.lastRotation
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    viewModel.taggedUsers[index].scale = box.lastScale * value
                }
                .onEnded { value in
                    viewModel.taggedUsers[index].lastScale = viewModel.taggedUsers[index].scale
                }
        )
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
