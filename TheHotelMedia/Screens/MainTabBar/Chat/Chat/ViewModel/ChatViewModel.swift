//
//  ChatViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 25/11/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import PhotosUI

struct MessageMedia: Identifiable {
    let id: String
    let type: MessageMediaType
}


enum MessageMediaType: Equatable {
    case photo(_ thumbnail: UIImage)
    case video(_ thumbnail: UIImage, _ url: URL)
    case file(_ data: Data)
    
    
    static func == (lhs: MessageMediaType, rhs: MessageMediaType) -> Bool {
        switch (lhs, rhs) {
        case (.photo, .photo), (.video, .video), (.file, .file):
            return true
        default:
            return false
        }
    }
}


class ChatViewModel: ObservableObject {
    
    let router: AnyRouter
    let username: String
    let userID: String
    let profilePic: String
    let name: String
    let lastScreen: String
    var cancellables = Set<AnyCancellable>()
    var dataManager = ChatMediaDataManager()
    var profileDataManager = ProfileDataManager()
    let localizationManager = LocalizationManager.shared
    var socketViewModel = SocketIOViewModel.shared
    var pageNo: Int = 1
    var refresh: Bool = true
    var gotInitialData: Bool = false
//    var onThisScreen: Bool = false
    @Published var messages: [PrivateMessage] = []
    @Published var messageFieldText: String = ""
    @Published var showFileImporter: Bool = false
    @Published var showPhotoPicker: Bool = false
    @Published var showOptionDialog: Bool = false
    @Published var showPdfViewer: Bool = false
    @Published var isRemotePDFUrl: Bool = true
    @Published var viewPDFName: String = "PDF Viewer"
    @Published var openPDFUrl: URL = URL(string: "https://thehotelmedia.com")!
    @Published var toDownloadPDFUrl: URL? = nil
    @Published var openPDFData: Data = Data()
    @Published var photoPickerItems: [PhotosPickerItem] = []
    @Published var selectedVideoToSend: URL? = nil
    @Published var selectedImageToSend: UIImage? = nil
    @Published var fileImporterResult: Result<URL, Error>? = nil
    @Published var showMediaPreview: Bool = false
    @Published var selectedMedia: MediaType = .image(urlString: "")
    @Published var selectedImage: UIImage? = nil
    @Published var showLoadingIndicator: Bool = false
    @Published var useEmojiKeyboard: Bool = false
    @Published var isTextFieldFocused: Bool = false
    @Published var showOptionView: Bool = false
    @Published var showReportScreen: Bool = false
    @Published var modalUp: Bool = false
    @Published var isBlocked: Bool = false
    
    @AppStorage("pdfLimit") var pdfLimit: Double = 5.0
    
    let downloadManager = FileDownloadManager.shared
    let pdfDownloader = PDFDownloader()
    
    init(router: AnyRouter, username: String, userID: String, profilePic: String, name: String, lastScreen: String = "recentChat", message: String = "", openKeyboard: Bool = false) {
        self.router = router
        self.username = username
        self.userID = userID
        self.profilePic = profilePic
        self.name = name
        self.lastScreen = lastScreen
        self.messageFieldText = message
        self.isTextFieldFocused = openKeyboard
    }
    
    func addSubscribers() {
        socketViewModel.$isConnected
            .sink { [weak self] connected in
                guard let self else { return }
                
                // checking if socket is connected and if it is first data set or not.
                // because the socket reconnects every few minutes and we don't want to reset chat every time.
                if connected && !gotInitialData {
                    pageNo = 1
                    getChatData()
                    gotInitialData = true
                    
                } else if !connected { // if disconnect then reconnect to socket because we are inside chat screen.
                    socketViewModel.configureSocket()
                }
            }
            .store(in: &cancellables)
        
        socketViewModel.$privateChatPageNo
            .sink { [weak self] pageNo in
                guard let self else { return }
                self.pageNo = pageNo
            }
            .store(in: &cancellables)
        
        socketViewModel.$refreshMessages
            .sink { [weak self] refresh in
                guard let self else { return }
                self.refresh = refresh
            }
            .store(in: &cancellables)
        
        socketViewModel.$privateMessagesList
            .sink { [weak self] messages in
                guard let self else { return }
                
                let updatedMessages = addShowDatePropertyToMessages(messages: messages)
                
                if refresh {
                    self.messages = updatedMessages
                } else {
//                    var allMessages = self.messages
//                    allMessages.insert(contentsOf: messages.reversed(), at: 0)
//                    self.messages = allMessages
                    self.messages += updatedMessages
                }
                print(messages)
            }
            .store(in: &cancellables)
        
        socketViewModel.$newMessage
            .sink { [weak self] message in
                guard let self else { return }
                if var message {
                    if let from = message.from {
                        if from == username {
                            
                            if let first = messages.first {
                                let hasChanged = hasDateChanged(from: message.createdAt ?? "", to: first.createdAt ?? "")
                                message.showDate = hasChanged
                            }
                            
                            messages.insert(message, at: 0)
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        $photoPickerItems
            .sink { [weak self] pickerItems in
                guard let self else { return }
                
                Task {
                    if !pickerItems.isEmpty {
                        await self.parsePhotoPickerItem(pickerItems[0])
                        await MainActor.run {
                            self.photoPickerItems.removeAll()
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        $selectedImageToSend
            .sink { [weak self] image in
                guard let self else { return }
                if let image {
                    let randomID = UUID().uuidString
                    var message = PrivateMessage(id: randomID, createdAt: DateManager.dateIntoIsoFormat(date: Date()), isSeen: 1, content: "Image", sentByMe: 1, type: "image", thumbnail: image, isUploading: true)
                    
                    if let first = messages.first {
                        let hasChanged = hasDateChanged(from: message.createdAt ?? "", to: first.createdAt ?? "")
                        message.showDate = hasChanged
                    }
                    
                    messages.insert(message, at: 0)
                    
                    let media = MessageMedia(id: randomID, type: .photo(image))
                    let parameters: [String: Any] = [
                        "username": username,
                        "message": "Image",
                        "messageType": "image",
                    ]
                    
                    sendMediaMessage(media: [media], parameters: parameters)
                    selectedImageToSend = nil
                }
            }
            .store(in: &cancellables)
        
        $selectedVideoToSend
            .sink { [weak self] videoURL in
                guard let self else { return }
                if let videoURL {
                    let randomID = UUID().uuidString
                    var message = PrivateMessage(id: randomID, createdAt: DateManager.dateIntoIsoFormat(date: Date()), isSeen: 1, content: "Video", sentByMe: 1, type: "video", mediaUrl: videoURL.absoluteString, isUploading: true)
                    
                    if let first = messages.first {
                        let hasChanged = hasDateChanged(from: message.createdAt ?? "", to: first.createdAt ?? "")
                        message.showDate = hasChanged
                    }
                    
                    messages.insert(message, at: 0)
                    
                    Task { [weak self] in
                        guard let self else { return }
                        if let thumbnail = try? await videoURL.generateVideoThumbnail() {
                            await MainActor.run {
                                if let index = self.messages.firstIndex(where: {$0.id == randomID }) {
                                    self.messages[index].thumbnail = thumbnail
                                }
                            }
                        }
                    }
                    
                    let media = MessageMedia(id: randomID, type: .video(UIImage(), videoURL))
                    let parameters: [String: Any] = [
                        "username": username,
                        "message": "Video",
                        "messageType": "video",
                    ]
                    
                    sendMediaMessage(media: [media], parameters: parameters)
                    selectedVideoToSend = nil
                }
            }
            .store(in: &cancellables)
        
        $fileImporterResult
            .sink { [weak self] result in
                guard let self else { return }
                if let result {
                    let (data, url) = pdfSelected(result: result)
                    
                    if let data,
                       let url {
                        let randomID = UUID().uuidString
                        var message = PrivateMessage(id: randomID, createdAt: DateManager.dateIntoIsoFormat(date: Date()), isSeen: 1, content: url.lastPathComponent, sentByMe: 1, type: "pdf", isUploading: true, isRemotePDF: false, pdfData: data)
                        
                        if let first = messages.first {
                            let hasChanged = hasDateChanged(from: message.createdAt ?? "", to: first.createdAt ?? "")
                            message.showDate = hasChanged
                        }
                        
                        messages.insert(message, at: 0)
                        
                        let media = MessageMedia(id: randomID, type: .file(data))
                        let parameters: [String: Any] = [
                            "username": username,
                            "message": url.lastPathComponent,
                            "messageType": "pdf",
                        ]
                        
                        sendMediaMessage(media: [media], parameters: parameters)
                        fileImporterResult = nil
                    } else {
//                        ErrorModalManager.showErrorModal(router: router, errorText: "you_cannot_select_larger_than_5_MB".localized(localizationManager.language))
                        ErrorModalManager.showErrorModal(router: router, errorText: "You cannot select file larger than \(Int(pdfLimit)) MB.")
                    }
                }
            }
            .store(in: &cancellables)
        
//        $showPdfViewer
//            .sink { [weak self] bool in
//                guard let self else { return }
//                if bool {
//                    openPDFUrl.startAccessingSecurityScopedResource()
//                } else {
//                    openPDFUrl.stopAccessingSecurityScopedResource()
//                }
//            }
//            .store(in: &cancellables)
    }
    
    
    func showBlockModal() {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "do_you_really_want_to_block_this_user".localized(localizationManager.language),
            rightButtonTitle: "no".localized(localizationManager.language),
            leftButtonTitle: "yes".localized(localizationManager.language)) {
                self.blockUser(id: self.userID)
                self.modalUp.toggle()
            } onRightButtonPressed: {
                self.modalUp.toggle()
            } onDismiss: {
                self.modalUp.toggle()
            }
    }
    
    func showDeleteChatModal() {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "do_you_really_want_to_delete_the_chat_with_this_user".localized(localizationManager.language),
            rightButtonTitle: "no".localized(localizationManager.language),
            leftButtonTitle: "yes".localized(localizationManager.language)) {
                self.deleteChat(id: self.userID)
                self.modalUp.toggle()
            } onRightButtonPressed: {
                self.modalUp.toggle()
            } onDismiss: {
                self.modalUp.toggle()
            }
    }
    
    
    
    func addShowDatePropertyToMessages(messages: [PrivateMessage]) -> [PrivateMessage] {
        var updatedMessages: [PrivateMessage] = []
        var lastDate: String = ""
        var currentDate: String = ""
        
//                for (index, message) in messages.enumerated() {
//                    var newMessage: PrivateMessage = message
//
//                    lastDate = currentDate
//
//                    if let createdAt = message.createdAt, !lastDate.isEmpty, !createdAt.isEmpty {
//                        currentDate = createdAt
//                        let dateHasChanged = hasDateChanged(from: lastDate, to: currentDate)
//
//                        if dateHasChanged, index != 0 {
//                            updatedMessages[index - 1].showDate = true
//                        }
//
//                        newMessage.showDate = false
//                    } else {
//                        newMessage.showDate = false
//                    }
//                    updatedMessages.append(newMessage)
//                }
        
        // Updatign showDate property of last message
        if let last = self.messages.last {
            if let first = messages.first {
                let hasDateChanged = hasDateChanged(from: last.createdAt ?? "", to: first.createdAt ?? "")
                
                if let index = self.messages.firstIndex(where: {$0.id == last.id}) {
                    self.messages[index].showDate = hasDateChanged
                }
            }
        }
        
        for (index, message) in messages.reversed().enumerated() {
            var newMessage: PrivateMessage = message
            
            lastDate = currentDate
            
            if lastDate.isEmpty {
                newMessage.showDate = true
                
                if let createdAt = newMessage.createdAt {
                    currentDate = createdAt
                }
                
            } else if let createdAt = message.createdAt, !createdAt.isEmpty {
                currentDate = createdAt
                
                let hasDateChanged = hasDateChanged(from: currentDate, to: lastDate)
                newMessage.showDate = hasDateChanged
                
            } else {
                newMessage.showDate = false
                
                if let createdAt = newMessage.createdAt {
                    currentDate = createdAt
                }
            }
            
            updatedMessages.append(newMessage)
        }
        return updatedMessages.reversed()
    }
    
    
    func showUserProfileScreen(id: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func isValidURL(_ string: String) -> Bool {
        if let url = URL(string: string), UIApplication.shared.canOpenURL(url) {
            return true
        }
        return false
    }
    
    
    func getChatData() {
        socketViewModel.fetchPrivateConversation(username: username, pageNumber: pageNo)
    }
    
    
    func hasDateChanged(from isoDateString1: String, to isoDateString2: String) -> Bool {
        let datePart1 = String(isoDateString1.prefix(10)) // Extract "yyyy-MM-dd"
        let datePart2 = String(isoDateString2.prefix(10))
        return datePart1 != datePart2
    }
    
    
    private func parsePhotoPickerItem(_ photoPickerItem: PhotosPickerItem) async {
        if photoPickerItem.isVideo {

            if let mov = try? await photoPickerItem.loadTransferable(type: VideoPickerTransferable.self) {
                await MainActor.run {
                    selectedVideoToSend = mov.url
                }
            }
            
        } else {
            guard
            let data = try? await photoPickerItem.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
            else { return }
            
            await MainActor.run {
                selectedImageToSend = UIImage(data: data)
            }
        }
    }
    
    
//    func getAttributedDescriptionWithoutTruncation(content: String, id: String) -> AttributedString {
//        let urlRegex = try! NSRegularExpression(pattern: "^(https?|ftp|file)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]", options: [])
//        let matches = urlRegex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
//        
//        var adjustedContent = content
//        var urlInsertions: [(range: NSRange, link: String)] = []
//        
//        // Process URLs in reverse order to maintain index integrity after modifying the content
//        for match in matches.reversed() {
//            if let range = Range(match.range, in: content) {
//                let urlText = String(content[range])
//                let tappableText = urlText
//                
//                // Replace the full URL with tappable text in the adjusted content
//                adjustedContent.replaceSubrange(range, with: tappableText)
//                
//                // Record the insertion range for later styling in attributed string
//                if let adjustedRange = Range(match.range, in: adjustedContent) {
////                    urlInsertions.append((range: NSRange(adjustedRange, in: adjustedContent), link: "link://\(id)?url=\(urlText)"))
//                    urlInsertions.append((range: NSRange(adjustedRange, in: adjustedContent), link: "link://tabbar?url=\(urlText)"))
//                }
//            }
//        }
//        
//        // Create the attributed string for the adjusted content
//        var attributedString = AttributedString(adjustedContent)
//        
//        // Add tappable links for URLs
//        for insertion in urlInsertions {
//            if let range = Range(insertion.range, in: attributedString) {
//                attributedString[range].link = URL(string: insertion.link)
//                attributedString[range].underlineStyle = .single
//                attributedString[range].foregroundColor = .white
//            }
//        }
//
//        return attributedString
//    }
    func getAttributedDescriptionWithoutTruncation(content: String, id: String) -> AttributedString {
        let urlRegex = try! NSRegularExpression(pattern: "^(https?|ftp|file)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]", options: [])
        let matches = urlRegex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
        
        var adjustedContent = content
        var urlInsertions: [(range: NSRange, link: String)] = []
        
        // Process URLs in reverse order to maintain index integrity after modifying the content
        for match in matches.reversed() {
            if let range = Range(match.range, in: content) {
                let urlText = String(content[range])
                let tappableText = urlText
                
                // Replace the full URL with tappable text in the adjusted content
                adjustedContent.replaceSubrange(range, with: tappableText)
                
                // Record the insertion range for later styling in attributed string
                if let adjustedRange = Range(match.range, in: adjustedContent) {
                    urlInsertions.append((range: NSRange(adjustedRange, in: adjustedContent), link: "link://tabbar?url=\(urlText)"))
                }
            }
        }

        // Load abusive words from JSON
        let censoredWords = loadAbusiveWords()
        
        // Censor words from the list
        for word in censoredWords {
            let regexPattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            let wordRegex = try! NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)

            let matches = wordRegex.matches(in: adjustedContent, options: [], range: NSRange(adjustedContent.startIndex..., in: adjustedContent))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: adjustedContent) {
                    let word = String(adjustedContent[range])
                    let censoredWord = censorWord(word)
                    adjustedContent.replaceSubrange(range, with: censoredWord)
                }
            }
        }

        // Create the attributed string for the adjusted content
        var attributedString = AttributedString(adjustedContent)

        // Add tappable links for URLs
        for insertion in urlInsertions {
            if let range = Range(insertion.range, in: attributedString) {
                attributedString[range].link = URL(string: insertion.link)
                attributedString[range].underlineStyle = .single
                attributedString[range].foregroundColor = .white
            }
        }

        return attributedString
    }

    // Function to censor words (keep first letter, replace rest with `*`)
    func censorWord(_ word: String) -> String {
        guard word.count > 1 else { return word }
        let firstLetter = word.prefix(1)
        let maskedPart = String(repeating: "*", count: word.count - 1)
        return firstLetter + maskedPart
    }
    
    
    func loadAbusiveWords() -> [String] {
        guard let url = Bundle.main.url(forResource: "abusive_words", withExtension: "json") else {
            print("Failed to locate abusive_words.json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return jsonObject?["abusiveWords"] as? [String] ?? []
        } catch {
            print("Error loading abusive words: \(error)")
            return []
        }
    }

    
    
    func pdfSelected(result: Result<URL, Error>) -> (Data?, URL?) {
        let maxFileSizeInBytes = Int(pdfLimit) * 1024 * 1024 // 5 MB in bytes
        
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                url.stopAccessingSecurityScopedResource()
                return (nil, nil)
            }
            
            do {
                // Check the file size
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize, fileSize > maxFileSizeInBytes {
                    print("PDF file size exceeds 5 MB limit")
                    url.stopAccessingSecurityScopedResource()
                    return (nil, nil)
                }
                
                // Read file data
                let data = try Data(contentsOf: url)
                url.stopAccessingSecurityScopedResource()
                return (data, url)
                
            } catch {
                print("Error obtaining content of PDF from URL: \(error)")
                url.stopAccessingSecurityScopedResource()
                return (nil, nil)
            }
            
        case .failure(let error):
            print("Error loading PDF: \(error)")
            return (nil, nil)
        }
    }

    
    
    
    func sendMessage(message: String, type: String = "text", mediaID: String? = nil, mediaUrl: String? = nil, thumbnailUrl: String? = nil) {
        
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var messageModel: [String: Any] = [
            "type" : type,
            "message": trimmedMessage
        ]
        
        if let mediaID {
            messageModel.updateValue(mediaID, forKey: "mediaID")
        }
        
        if let mediaUrl {
            messageModel.updateValue(mediaUrl, forKey: "mediaUrl")
        }
        
        if let thumbnailUrl {
            messageModel.updateValue(thumbnailUrl, forKey: "thumbnailUrl")
        }
        
        let parameters: [String: Any] = [
            "message": messageModel,
            "to": username
        ]
        socketViewModel.sendMessage(parameters: parameters)
        
        if mediaID == nil {
            
            var message = PrivateMessage(id: UUID().uuidString, createdAt: DateManager.dateIntoIsoFormat(date: Date()), isSeen: 1, content: trimmedMessage, sentByMe: 1, type: type)
            
            if let first = messages.first {
                let hasChanged = hasDateChanged(from: message.createdAt ?? "", to: first.createdAt ?? "")
                message.showDate = hasChanged
            }
            
            messages.insert(message, at: 0)
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func cancelPublishers() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
    }
    
    
    func showActivityIndicator(at fileURL: URL) {
        DispatchQueue.main.async {
            do {
                // Create an activity view controller to share the file data
                let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

                // Find the active scene and its window
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(activityViewController, animated: true, completion: nil)
                } else {
                    print("Unable to find a root view controller to present the activity view controller.")
                }
            } catch {
                print("Failed to load file data: \(error.localizedDescription)")
            }
        }
    }
    
    
    func showSharedProfile(sharedID: String, sharedByID: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: sharedID, sharedByProfileID: sharedByID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSharePostView(postID: String, sharedByID: String) {
        router.showScreen(.push) { router in
            SinglePostView(viewModel: SinglePostViewModel(router: router, postID: postID, sharedByID: sharedByID), isPaused: .constant(false))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func showShareEventView(postID: String, sharedByID: String) {
        router.showScreen(.push) { router in
            EventDetailView(viewModel: EventDetailViewModel(router: router, postID: postID, sharedByID: sharedByID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func showCreateReviewScreen(id: String? = nil, placeID: String? = nil) {
        router.showScreen(.push) { router in
            CreateReviewView(viewModel: CreateReviewViewModel(router: router, businessProfileID: id, placeID: placeID, onReviewCreated: { [weak self] in
                guard let self else { return }
//                refreshHomeData = true
            }))
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
            
        }
    }
    
}


// MARK: - Networking 
extension ChatViewModel {
    
    func sendMediaMessage(media: [MessageMedia], parameters: [String: Any]) {
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.uploadMedia(media: media, parameters: parameters)
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let index = messages.firstIndex(where: { $0.id == media[0].id }) {
                            messages[index].isUploading = false
                        }
                        
                        if let data = result.data,
                           let message = data.message,
                           let type = message.type,
                           let textMessage = message.message,
                           let mediaID = message.mediaID,
                           let mediaUrl = message.mediaUrl,
                           let thumbnailUrl = message.thumbnailUrl {
                            
                            sendMessage(message: textMessage, type: type, mediaID: mediaID, mediaUrl: mediaUrl, thumbnailUrl: thumbnailUrl)
                        }
                        
                    } else {
                        if let index = messages.firstIndex(where: { $0.id == media[0].id }) {
                            messages.remove(at: index)
                        }
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                    
                    showLoadingIndicator = false
                }
            } catch {
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == media[0].id }) {
                        messages.remove(at: index)
                    }
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "failed_to_send_media".localized(localizationManager.language))
                }
            }
        }
    }
    
    
    func blockUser(id: String) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await profileDataManager.blockUser(id: userID)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    
                    if result.status && range.contains(result.statusCode) {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        if result.message.lowercased().contains("unblocked") {
                            isBlocked = false
                        } else {
                            isBlocked = true
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: "failed_to_block_the_user".localized(localizationManager.language))
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "internal_server_error_please_try_again".localized(localizationManager.language))
                }
            }
        }
    }
    
    
    func deleteChat(id: String) {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.deleteChat(userID: userID)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    
                    if result.status && range.contains(result.statusCode) {
                        ErrorModalManager.showErrorModal(router: router, errorText: "chat_deleted_successfully".localized(localizationManager.language))
                        
                        socketViewModel.leavePrivateChatEmit(user: username)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            guard let self else { return }
                            dismissScreen()
                        }
                        
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: "failed_to_delete_chat".localized(localizationManager.language))
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "internal_server_error_please_try_again".localized(localizationManager.language))
                }
            }
        }
    }
    
    
    func exportChat(id: String) {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.exportChat(userID: userID)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        
                        if let data = result.data,
                           let filename = data.filename,
                           let filepath = data.filepath {
                            
//                            if let url = URL(string: filepath) {
//                                showActivityIndicator(at: url)
//                            }
                            downloadManager.downloadFile(from: filepath, fileName: filename) { [weak self] result in
                                guard let self else { return }
                                showLoadingIndicator = false
                                switch result {
                                case .success(let url):
                                    showActivityIndicator(at: url)
                                    
                                case .failure(let error):
                                    break
                                }
                            }
                        }
                        
                    } else {
                        showLoadingIndicator = false
                        ErrorModalManager.showErrorModal(router: router, errorText: "failed_to_export_chat".localized(localizationManager.language))
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "internal_server_error_please_try_again".localized(localizationManager.language))
                }
            }
        }
    }
}
