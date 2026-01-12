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
    /// When true, the next outgoing echo from socket (`newMessage` where `from == username`)
    /// will be ignored. Used to avoid duplicating locally-inserted messages (e.g. share post).
    var suppressNextOutgoingEcho: Bool = false
    var isSharingPost: Bool = false // Prevent multiple simultaneous post shares
    private let sharingLock = NSLock() // Lock to prevent concurrent share calls
    var recentlySentMediaURLs: Set<String> = [] // Track recently sent media to prevent duplicates
    var recentlySharedPostMediaURLs: Set<String> = [] // Track ALL media URLs from a shared post to filter duplicates
    var sharePostBlockStartTime: Date? = nil // Track when we started sharing to block messages within a time window
    var pendingPostToShare: PostData? = nil // Post to share when ChatView appears
    var lastSharedPostID: String? = nil // Track last shared post ID to prevent duplicates
    @Published var messages: [PrivateMessage] = []
    @Published var messageFieldText: String = ""
    @Published var editingMessage: PrivateMessage? = nil
    
    // Retry logic for operations attempted before server `_id` is available.
    private var mutationRetryCount: [String: Int] = [:]
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
                
                let isInShareBlockWindow = self.sharePostBlockStartTime != nil && 
                    Date().timeIntervalSince(self.sharePostBlockStartTime!) < 10.0
                
                let filteredMessages = messages.filter { message in
                    if isInShareBlockWindow {
                        let isOutgoing = (message.sentByMe == 1) || (message.from == self.username)
                        let isMediaType = message.type == "image" || message.type == "video" || message.type == "post"
                        
                        if isOutgoing && isMediaType {
                            return false
                        }
                    }
                    
                    return true
                }
                
                let updatedMessages = addShowDatePropertyToMessages(messages: filteredMessages)
                
                if refresh {
                    // Preserving local pending messages (those with clientMessageID but no server messageID yet)
                    let pendingMessages = self.messages.filter { $0.clientMessageID != nil && $0.messageID == nil }
                    
                    // Filter out any messages from updatedMessages that were already in pendingMessages to avoid duplicates if server is fast
                    let filteredUpdated = updatedMessages.filter { serverMsg in
                        !pendingMessages.contains(where: { $0.clientMessageID == serverMsg.clientMessageID })
                    }
                    
                    self.messages = pendingMessages + filteredUpdated
                } else {
                    self.messages += updatedMessages
                }
            }
            .store(in: &cancellables)
        
        socketViewModel.$newMessage
            .sink { [weak self] message in
                guard let self else { return }
                if var message {
                    if let from = message.from {
                        let isFromRecipient = from == username
                        let isEchoFromMe = from == socketViewModel.username && message.to == username
                        
                        if isFromRecipient || isEchoFromMe {
                            // If it's an echo from me, ensure we flag it as sentByMe = 1
                            if isEchoFromMe {
                                message.sentByMe = 1
                            }

                            if isFromRecipient && suppressNextOutgoingEcho {
                                suppressNextOutgoingEcho = false
                                return
                            }
                            
                            if isEchoFromMe && suppressNextOutgoingEcho {
                                suppressNextOutgoingEcho = false
                                return
                            }

                            if let blockStart = sharePostBlockStartTime, 
                               Date().timeIntervalSince(blockStart) < 10.0 {
                                let isMediaType = message.type == "image" || message.type == "video" || message.type == "post"
                                if isMediaType {
                                    return
                                }
                            }
                            
                            // No more URL-based filtering here. clientID matching below handles it.
                            
                            if let clientID = message.clientMessageID ?? message.id,
                               let index = messages.firstIndex(where: { $0.clientMessageID == clientID || $0.id == clientID }) {
                                // Update existing optimistic message with server data
                                var updated = message
                                updated.showDate = messages[index].showDate
                                // Preserve local properties that might be missing from server echo
                                if updated.isUploading == nil {
                                    updated.isUploading = false
                                }
                                messages[index] = updated
                            } else {
                                if let first = messages.first {
                                    let hasChanged = hasDateChanged(from: message.createdAt ?? "", to: first.createdAt ?? "")
                                    message.showDate = hasChanged
                                }
                                
                                messages.insert(message, at: 0)
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        socketViewModel.$editedMessageUpdate
            .sink { [weak self] update in
                guard let self else { return }
                guard let update else { return }
                self.applyEditUpdate(update)
            }
            .store(in: &cancellables)
        
        socketViewModel.$deletedMessageUpdate
            .sink { [weak self] update in
                guard let self else { return }
                guard let update else { return }
                self.applyDeleteUpdate(update)
            }
            .store(in: &cancellables)
        
        $photoPickerItems
            .sink { [weak self] pickerItems in
                guard let self else { return }
                guard let firstItem = pickerItems.first else { return }

                // Insert the "sending" bubble immediately (especially important for videos,
                // since `loadTransferable` can take a moment to export/move the asset).
                let clientID = UUID().uuidString
                Task { @MainActor [weak self] in
                    self?.insertPendingMediaMessage(for: firstItem, clientID: clientID)
                    self?.photoPickerItems.removeAll()
                }

                Task { [weak self] in
                    await self?.processPickedMediaItem(firstItem, clientID: clientID)
                }
            }
            .store(in: &cancellables)
        
        // NOTE: Sending image/video is now driven directly from `photoPickerItems` so we can
        // show the "sending" bubble instantly (videos can take time to export via PhotosPicker).
        
        $fileImporterResult
            .sink { [weak self] result in
                guard let self else { return }
                if let result {
                    let (data, url) = pdfSelected(result: result)
                    
                    if let data,
                       let url {
                        let randomID = UUID().uuidString
                        var message = PrivateMessage(
                            id: randomID,
                            createdAt: DateManager.dateIntoIsoFormat(date: Date()),
                            isSeen: 1,
                            content: url.lastPathComponent,
                            sentByMe: 1,
                            type: "pdf",
                            messageID: nil,
                            clientMessageID: randomID,
                            isUploading: true,
                            uploadProgress: 0.0,
                            isRemotePDF: false,
                            pdfData: data
                        )
                        
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
    
    
    // parsePhotoPickerItem no longer used (kept logic in `processPickedMediaItem`).

    @MainActor
    private func insertPendingMediaMessage(for item: PhotosPickerItem, clientID: String) {
        let type = item.isVideo ? "video" : "image"
        let contentText = item.isVideo ? "Video" : "Image"

        var message = PrivateMessage(
            id: clientID,
            createdAt: DateManager.dateIntoIsoFormat(date: Date()),
            isSeen: 1,
            content: contentText,
            sentByMe: 1,
            type: type,
            messageID: nil,
            clientMessageID: clientID,
            isUploading: true,
            uploadProgress: 0.0
        )

        if let first = messages.first {
            let hasChanged = hasDateChanged(from: message.createdAt ?? "", to: first.createdAt ?? "")
            message.showDate = hasChanged
        }

        messages.insert(message, at: 0)
    }

    private func processPickedMediaItem(_ item: PhotosPickerItem, clientID: String) async {
        if item.isVideo {
            guard let mov = try? await item.loadTransferable(type: VideoPickerTransferable.self) else {
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == clientID }) {
                        messages.remove(at: index)
                    }
                    ErrorModalManager.showErrorModal(router: router, errorText: "failed_to_send_media".localized(localizationManager.language))
                }
                return
            }

            let videoURL = mov.url

            // Update local message with a thumbnail as soon as we can generate it.
            if let thumbnail = try? await videoURL.generateVideoThumbnail() {
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == clientID }) {
                        messages[index].thumbnail = thumbnail
                        messages[index].mediaUrl = videoURL.absoluteString
                    }
                }
            } else {
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == clientID }) {
                        messages[index].mediaUrl = videoURL.absoluteString
                    }
                }
            }

            let media = MessageMedia(id: clientID, type: .video(UIImage(), videoURL))
            let parameters: [String: Any] = [
                "username": username,
                "message": "Video",
                "messageType": "video",
            ]
            await MainActor.run {
                sendMediaMessage(media: [media], parameters: parameters)
            }
        } else {
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == clientID }) {
                        messages.remove(at: index)
                    }
                    ErrorModalManager.showErrorModal(router: router, errorText: "failed_to_send_media".localized(localizationManager.language))
                }
                return
            }

            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == clientID }) {
                    messages[index].thumbnail = image
                }
            }

            let media = MessageMedia(id: clientID, type: .photo(image))
            let parameters: [String: Any] = [
                "username": username,
                "message": "Image",
                "messageType": "image",
            ]
            await MainActor.run {
                sendMediaMessage(media: [media], parameters: parameters)
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

    
    
    
    func sendMessage(message: String, type: String = "text", mediaID: String? = nil, mediaUrl: String? = nil, thumbnailUrl: String? = nil, clientMessageID: String? = nil) {
        
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedClientMessageID = clientMessageID ?? UUID().uuidString
        
        var messageModel: [String: Any] = [
            "type" : type,
            "message": trimmedMessage,
            "clientMessageID": resolvedClientMessageID
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
        
        // NOTE: Backend may store `clientMessageID` as a top-level field (recommended),
        // so we include it BOTH at top-level and inside the nested message model.
        let parameters: [String: Any] = [
            "message": messageModel,
            "to": username,
            "clientMessageID": resolvedClientMessageID
        ]
        socketViewModel.sendMessage(parameters: parameters)
        
        if mediaID == nil {
            
            var message = PrivateMessage(
                id: resolvedClientMessageID,
                createdAt: DateManager.dateIntoIsoFormat(date: Date()),
                isSeen: 1,
                content: trimmedMessage,
                sentByMe: 1,
                type: type,
                messageID: nil,
                clientMessageID: resolvedClientMessageID
            )
            
            if let first = messages.first {
                let hasChanged = hasDateChanged(from: message.createdAt ?? "", to: first.createdAt ?? "")
                message.showDate = hasChanged
            }
            
            messages.insert(message, at: 0)
        }
    }
    
    func sendOrEditCurrentText() {
        let trimmed = messageFieldText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let editingMessage {
            submitEdit(for: editingMessage, newText: trimmed)
            messageFieldText = ""
            self.editingMessage = nil
        } else {
            sendMessage(message: trimmed)
            messageFieldText = ""
        }
    }
    
    func beginEditing(_ message: PrivateMessage) {
        guard message.sentByMe == 1 else { return }
        guard message.type == "text" else { return }
        guard message.isDeleted != true else { return }
        editingMessage = message
        messageFieldText = message.content ?? ""
        isTextFieldFocused = true
    }
    
    func cancelEditing() {
        editingMessage = nil
        messageFieldText = ""
    }
    
    func showDeleteMessageModal(_ message: PrivateMessage) {
        guard message.sentByMe == 1 else { return }
        guard message.isDeleted != true else { return }
        
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "Do you really want to delete this message?",
            rightButtonTitle: "No",
            leftButtonTitle: "Yes"
        ) { [weak self] in
            self?.deleteMessage(message)
        } onRightButtonPressed: { } onDismiss: { }
    }
    
    // MARK: - Applying socket updates
    
    private func submitEdit(for message: PrivateMessage, newText: String) {
        guard socketViewModel.isConnected else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Connection lost. Please try again.")
            return
        }
        // IMPORTANT:
        // If the server doesn't reliably support lookup by `clientMessageID`,
        // emitting edit/delete before we have the Mongo `_id` will produce "Message not found".
        // So we only emit immediately when we have a real server id.
        let serverMessageID = message.messageID
        
        // Optimistic update
        if let index = findMessageIndex(messageID: message.messageID, clientMessageID: message.clientMessageID ?? message.id) {
            messages[index].isEdited = true
            messages[index].editedAt = DateManager.dateIntoIsoFormat(date: Date())
            messages[index] = PrivateMessage(
                id: messages[index].id,
                createdAt: messages[index].createdAt,
                isSeen: messages[index].isSeen,
                content: newText,
                sentByMe: messages[index].sentByMe,
                type: messages[index].type,
                messageID: messages[index].messageID,
                clientMessageID: messages[index].clientMessageID,
                isEdited: true,
                editedAt: messages[index].editedAt,
                isDeleted: messages[index].isDeleted,
                deletedAt: messages[index].deletedAt,
                mediaUrl: messages[index].mediaUrl,
                thumbnailUrl: messages[index].thumbnailUrl,
                from: messages[index].from,
                to: messages[index].to,
                thumbnail: messages[index].thumbnail,
                hasUploaded: messages[index].hasUploaded,
                isUploading: messages[index].isUploading,
                isRemotePDF: messages[index].isRemotePDF,
                isURL: messages[index].isURL,
                showDate: messages[index].showDate,
                pdfData: messages[index].pdfData
            )
        }
        
        if let serverMessageID, !serverMessageID.isEmpty {
            socketViewModel.editMessage(messageID: serverMessageID, message: newText)
        }
        
        // Force a refresh so we don't "revert" on navigation if the server is the source of truth.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            self.socketViewModel.fetchPrivateConversation(username: self.username, pageNumber: 1)
        }
        
        // If this message doesn't have server `_id` yet, retry edit after server has a chance to persist it.
        if serverMessageID == nil || serverMessageID?.isEmpty == true {
            retryEditIfNeeded(original: message, newText: newText)
        }
    }
    
    private func deleteMessage(_ message: PrivateMessage) {
        guard socketViewModel.isConnected else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Connection lost. Please try again.")
            return
        }
        // See note in submitEdit: avoid emitting delete before server `_id` exists.
        let serverMessageID = message.messageID
        
        // Optimistic update
        if let index = findMessageIndex(messageID: message.messageID, clientMessageID: message.clientMessageID ?? message.id) {
            messages[index].isDeleted = true
            messages[index] = PrivateMessage(
                id: messages[index].id,
                createdAt: messages[index].createdAt,
                isSeen: messages[index].isSeen,
                content: "The message was deleted",
                sentByMe: messages[index].sentByMe,
                type: messages[index].type,
                messageID: messages[index].messageID,
                clientMessageID: messages[index].clientMessageID,
                isEdited: messages[index].isEdited,
                editedAt: messages[index].editedAt,
                isDeleted: true,
                deletedAt: DateManager.dateIntoIsoFormat(date: Date()),
                mediaUrl: messages[index].mediaUrl,
                thumbnailUrl: messages[index].thumbnailUrl,
                from: messages[index].from,
                to: messages[index].to,
                thumbnail: messages[index].thumbnail,
                hasUploaded: messages[index].hasUploaded,
                isUploading: messages[index].isUploading,
                isRemotePDF: messages[index].isRemotePDF,
                isURL: messages[index].isURL,
                showDate: messages[index].showDate,
                pdfData: messages[index].pdfData
            )
        }
        
        if let serverMessageID, !serverMessageID.isEmpty {
            socketViewModel.deleteMessage(messageID: serverMessageID)
        }
        
        // Force a refresh so we don't "revert" on navigation if the server is the source of truth.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            self.socketViewModel.fetchPrivateConversation(username: self.username, pageNumber: 1)
        }
        
        // If this message doesn't have server `_id` yet, retry delete after server has a chance to persist it.
        if serverMessageID == nil || serverMessageID?.isEmpty == true {
            retryDeleteIfNeeded(original: message)
        }
    }
    
    // MARK: - Delayed retries (server may not have indexed/stored the message yet)
    
    private func retryDeleteIfNeeded(original: PrivateMessage) {
        guard original.messageID == nil else { return } // already has server id
        guard let clientID = original.clientMessageID ?? original.id else { return }
        
        let key = "delete:\(clientID)"
        let count = mutationRetryCount[key, default: 0]
        guard count < 2 else { return } // retry up to 2 times
        mutationRetryCount[key] = count + 1
        
        // Re-fetch to get the server `_id`, then retry using it.
        socketViewModel.fetchPrivateConversation(username: username, pageNumber: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            if let serverID = self.resolveServerMessageID(for: original, clientID: clientID) {
                self.socketViewModel.deleteMessage(messageID: serverID)
            } else {
                self.retryDeleteIfNeeded(original: original)
            }
        }
    }
    
    private func retryEditIfNeeded(original: PrivateMessage, newText: String) {
        guard original.messageID == nil else { return } // already has server id
        guard let clientID = original.clientMessageID ?? original.id else { return }
        
        let key = "edit:\(clientID)"
        let count = mutationRetryCount[key, default: 0]
        guard count < 2 else { return } // retry up to 2 times
        mutationRetryCount[key] = count + 1
        
        socketViewModel.fetchPrivateConversation(username: username, pageNumber: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            if let serverID = self.resolveServerMessageID(for: original, clientID: clientID) {
                self.socketViewModel.editMessage(messageID: serverID, message: newText)
            } else {
                self.retryEditIfNeeded(original: original, newText: newText)
            }
        }
    }
    
    private func resolveServerMessageID(for original: PrivateMessage, clientID: String) -> String? {
        // Preferred: match by `clientMessageID` from server response.
        if let byClient = socketViewModel.privateMessagesList.first(where: { ($0.clientMessageID == clientID) || ($0.id == clientID) }),
           let serverID = byClient.messageID,
           !serverID.isEmpty {
            return serverID
        }
        
        // Fallback: some backend responses may omit `clientMessageID` in fetch conversations.
        // Try matching by (sentByMe, type, content, createdAt proximity).
        let originalContent = original.content ?? ""
        let originalType = original.type ?? ""
        let originalDate = isoDate(original.createdAt)
        
        let candidates = socketViewModel.privateMessagesList.filter { msg in
            guard msg.sentByMe == 1 else { return false }
            guard (msg.type ?? "") == originalType else { return false }
            // Avoid matching already-deleted placeholders
            if msg.isDeleted == true { return false }
            return (msg.content ?? "") == originalContent
        }
        
        if let originalDate {
            // Pick the closest in time within ~20 seconds.
            var best: (id: String, delta: TimeInterval)? = nil
            for msg in candidates {
                guard let serverID = msg.messageID, !serverID.isEmpty else { continue }
                guard let msgDate = isoDate(msg.createdAt) else { continue }
                let delta = abs(msgDate.timeIntervalSince(originalDate))
                if delta <= 20 {
                    if best == nil || delta < best!.delta {
                        best = (serverID, delta)
                    }
                }
            }
            return best?.id
        } else {
            // If we can't parse dates, just take the newest matching content/type.
            return candidates.first?.messageID
        }
    }
    
    private func isoDate(_ iso: String?) -> Date? {
        guard let iso, !iso.isEmpty else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: iso) { return d }
        // Some payloads may not have fractional seconds.
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: iso)
    }
    
    private func applyEditUpdate(_ update: SocketMessageEditUpdate) {
        guard let index = findMessageIndex(messageID: update.messageID, clientMessageID: update.clientMessageID) else { return }
        
        let newText = update.message ?? messages[index].content ?? ""
        messages[index] = PrivateMessage(
            id: messages[index].id,
            createdAt: messages[index].createdAt,
            isSeen: messages[index].isSeen,
            content: newText,
            sentByMe: messages[index].sentByMe,
            type: messages[index].type,
            messageID: update.messageID ?? messages[index].messageID,
            clientMessageID: update.clientMessageID ?? messages[index].clientMessageID,
            isEdited: update.isEdited ?? true,
            editedAt: update.editedAt ?? messages[index].editedAt,
            isDeleted: messages[index].isDeleted,
            deletedAt: messages[index].deletedAt,
            mediaUrl: messages[index].mediaUrl,
            thumbnailUrl: messages[index].thumbnailUrl,
            from: update.from ?? messages[index].from,
            to: update.to ?? messages[index].to,
            thumbnail: messages[index].thumbnail,
            hasUploaded: messages[index].hasUploaded,
            isUploading: messages[index].isUploading,
            isRemotePDF: messages[index].isRemotePDF,
            isURL: messages[index].isURL,
            showDate: messages[index].showDate,
            pdfData: messages[index].pdfData
        )
    }
    
    private func applyDeleteUpdate(_ update: SocketMessageDeleteUpdate) {
        guard let index = findMessageIndex(messageID: update.messageID, clientMessageID: update.clientMessageID) else { return }
        
        messages[index] = PrivateMessage(
            id: messages[index].id,
            createdAt: messages[index].createdAt,
            isSeen: messages[index].isSeen,
            content: "The message was deleted",
            sentByMe: messages[index].sentByMe,
            type: messages[index].type,
            messageID: update.messageID ?? messages[index].messageID,
            clientMessageID: update.clientMessageID ?? messages[index].clientMessageID,
            isEdited: messages[index].isEdited,
            editedAt: messages[index].editedAt,
            isDeleted: update.isDeleted ?? true,
            deletedAt: messages[index].deletedAt ?? DateManager.dateIntoIsoFormat(date: Date()),
            mediaUrl: messages[index].mediaUrl,
            thumbnailUrl: messages[index].thumbnailUrl,
            from: update.from ?? messages[index].from,
            to: update.to ?? messages[index].to,
            thumbnail: messages[index].thumbnail,
            hasUploaded: messages[index].hasUploaded,
            isUploading: messages[index].isUploading,
            isRemotePDF: messages[index].isRemotePDF,
            isURL: messages[index].isURL,
            showDate: messages[index].showDate,
            pdfData: messages[index].pdfData
        )
    }
    
    private func findMessageIndex(messageID: String?, clientMessageID: String?) -> Int? {
        if let messageID, !messageID.isEmpty {
            if let index = messages.firstIndex(where: { $0.messageID == messageID || $0.id == messageID }) {
                return index
            }
        }
        if let clientMessageID, !clientMessageID.isEmpty {
            if let index = messages.firstIndex(where: { $0.clientMessageID == clientMessageID || $0.id == clientMessageID }) {
                return index
            }
        }
        return nil
    }
    
    func sharePostViaDM(postData: PostData, caption: String? = nil) {
        sharingLock.lock()
        defer { sharingLock.unlock() }
        
        guard !isSharingPost else {
            return
        }
        
        // Allow sharing the same post again if enough time has passed (15 seconds total)
        if let postID = postData.id, 
           postID == lastSharedPostID,
           let blockStartTime = sharePostBlockStartTime,
           Date().timeIntervalSince(blockStartTime) < 15.0 {
            return
        }
        
        isSharingPost = true
        sharePostBlockStartTime = Date()
        lastSharedPostID = postData.id
        
        guard let mediaRefs = postData.mediaRef, 
              !mediaRefs.isEmpty else {
            isSharingPost = false
            sharePostBlockStartTime = nil
            return
        }
        
        // For video posts, find the video media. Otherwise use the first media.
        let targetMedia = mediaRefs.first(where: { media in
            if let mimeType = media.mimeType, mimeType.contains("video") {
                return true
            }
            return false
        }) ?? mediaRefs.first
        
        guard let firstMedia = targetMedia,
              let mediaID = firstMedia.id,
              let mediaUrl = firstMedia.sourceURL else {
            isSharingPost = false
            sharePostBlockStartTime = nil
            return
        }
        
        let messageType: String
        if let mimeType = firstMedia.mimeType, mimeType.contains("video") {
            messageType = "video"
        } else {
            messageType = "image"
        }
        
        let thumbnailUrl = firstMedia.thumbnailURL ?? (messageType == "image" ? mediaUrl : nil)
        let messageText = caption ?? postData.content ?? "Check this out!"
        
        var allPostMediaURLs = Set<String>()
        allPostMediaURLs.insert(mediaUrl)
        
        for media in mediaRefs {
            if let url = media.sourceURL {
                allPostMediaURLs.insert(url)
            }
        }
        
        recentlySentMediaURLs.insert(mediaUrl)
        recentlySharedPostMediaURLs.formUnion(allPostMediaURLs)
        
        let clientMessageID = UUID().uuidString
        var localMessage = PrivateMessage(
            id: clientMessageID,
            createdAt: DateManager.dateIntoIsoFormat(date: Date()),
            isSeen: 1,
            content: messageText,
            sentByMe: 1,
            type: messageType,
            messageID: nil,
            clientMessageID: clientMessageID,
            mediaUrl: mediaUrl,
            thumbnailUrl: thumbnailUrl,
            mediaID: mediaID,
            postID: postData.id,
            postOwnerID: (postData.userID ?? postData.postedBy?.id),
            isSharedPost: true,
            isUploading: true
        )
        
        if let first = messages.first {
            let hasChanged = hasDateChanged(from: localMessage.createdAt ?? "", to: first.createdAt ?? "")
            localMessage.showDate = hasChanged
        }
        
        messages.insert(localMessage, at: 0)
        
        var messageModel: [String: Any] = [
            "type": messageType,
            "message": messageText,
            "clientMessageID": clientMessageID,
            "mediaID": mediaID,
            "mediaUrl": mediaUrl,
            "postID": postData.id ?? "",
            "postOwnerID": (postData.userID ?? postData.postedBy?.id ?? ""),
            "isSharedPost": true
        ]
        
        if let thumbnailUrl {
            messageModel.updateValue(thumbnailUrl, forKey: "thumbnailUrl")
        }
        
        let parameters: [String: Any] = [
            "message": messageModel,
            "to": username,
            "clientMessageID": clientMessageID
        ]
        
        socketViewModel.sendMessage(parameters: parameters)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            self.recentlySentMediaURLs.remove(mediaUrl)
            self.recentlySharedPostMediaURLs.subtract(allPostMediaURLs)
            self.isSharingPost = false
            self.sharePostBlockStartTime = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.lastSharedPostID = nil
            }
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
    
    // Open a shared post "in feed" (like Android's UserPostsViewer): photos list or reels for videos.
    func openSharedPostInFeed(from message: PrivateMessage) {
        let initialMediaID = message.mediaID
        let type = (message.type ?? "").lowercased()
        
        // Prefer explicit owner id when backend provides it
        if let ownerID = message.postOwnerID, !ownerID.isEmpty {
            openViewer(ownerID: ownerID, type: type, initialMediaID: initialMediaID)
            return
        }
        
        // Backend currently sends `postID` but not `postOwnerID`.
        // Resolve owner by fetching the post once.
        guard let postID = message.postID, !postID.isEmpty else { return }
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await SinglePostDataManager().getSinglePost(id: postID)
                let ownerID = result.data?.userID ?? result.data?.postedBy?.id
                
                await MainActor.run {
                    guard let ownerID, !ownerID.isEmpty else {
                        // Fallback to single post view if we couldn't resolve the owner feed.
                        self.showSharePostView(postID: postID, sharedByID: "")
                        return
                    }
                    self.openViewer(ownerID: ownerID, type: type, initialMediaID: initialMediaID)
                }
            } catch {
                await MainActor.run {
                    // If post fetch fails, fallback to single post view.
                    self.showSharePostView(postID: postID, sharedByID: "")
                }
            }
        }
    }
    
    private func openViewer(ownerID: String, type: String, initialMediaID: String?) {
        if type == "video" {
            router.showScreen(.push) { router in
                ProfileVideoDetailView(userProfileID: ownerID, initialMediaID: initialMediaID, profileData: nil)
                    .environmentObject(ThemeManager.shared)
                    .environmentObject(LocalizationManager.shared)
                    .navigationBarBackButtonHidden()
            }
        } else {
            router.showScreen(.push) { router in
                ProfilePhotoDetailView(userProfileID: ownerID, initialMediaID: initialMediaID, profileData: nil, preloadedPhotos: nil)
                    .environmentObject(ThemeManager.shared)
                    .environmentObject(LocalizationManager.shared)
                    .navigationBarBackButtonHidden()
            }
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
        Task {
            do {
                let result = try await dataManager.uploadMedia(media: media, parameters: parameters, uploadProgress: { [weak self] progress in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.updateUploadProgress(clientMessageID: media.first?.id, progress: progress)
                    }
                })
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let index = messages.firstIndex(where: { $0.id == media[0].id }) {
                            messages[index].isUploading = false
                            messages[index].uploadProgress = nil
                        }
                        
                        if let data = result.data,
                           let message = data.message,
                           let type = message.type,
                           let textMessage = message.message,
                           let mediaID = message.mediaID,
                           let mediaUrl = message.mediaUrl,
                           let thumbnailUrl = message.thumbnailUrl {
                            
                            sendMessage(
                                message: textMessage,
                                type: type,
                                mediaID: mediaID,
                                mediaUrl: mediaUrl,
                                thumbnailUrl: thumbnailUrl,
                                clientMessageID: media[0].id
                            )
                        }
                        
                    } else {
                        if let index = messages.firstIndex(where: { $0.id == media[0].id }) {
                            messages.remove(at: index)
                        }
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
            } catch {
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == media[0].id }) {
                        messages.remove(at: index)
                    }
                    ErrorModalManager.showErrorModal(router: router, errorText: "failed_to_send_media".localized(localizationManager.language))
                }
            }
        }
    }

    @MainActor
    private func updateUploadProgress(clientMessageID: String?, progress: Double) {
        guard let clientMessageID else { return }
        guard let index = messages.firstIndex(where: { $0.id == clientMessageID }) else { return }
        guard messages[index].isUploading == true else { return }

        let clamped = max(0.0, min(1.0, progress))
        let current = messages[index].uploadProgress ?? 0.0
        // Reduce UI churn for large uploads.
        if clamped - current >= 0.01 || clamped >= 1.0 {
            messages[index].uploadProgress = clamped
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
