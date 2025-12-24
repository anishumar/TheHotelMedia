//
//  CreatePostScreen.swift
//  HotelMedia
//
//  Created by MAC on 05/08/24.
//

import SwiftUI
import Flow
import SwiftfulRouting
import PhotosUI
import SDWebImageSwiftUI
import Lottie
import Combine



struct PHPickerSwiftUI: UIViewControllerRepresentable {
    
    @Environment(\.dismiss) var dismiss
    let config: PHPickerConfiguration
    let completion: (_ selectedImages: [PHPickerResult]) -> Void
    
    func makeUIViewController(context: Context) ->  PHPickerViewController {
        let controller = PHPickerViewController(configuration: config)
                controller.delegate = context.coordinator
                return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // We'll not update anything on this view.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        let parent: PHPickerSwiftUI
        
        init(parent: PHPickerSwiftUI) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            self.parent.completion(results)
            parent.dismiss.callAsFunction()
        }
    }
}


// MARK: - Invite Collaborator

struct InviteCollaboratorView: View {
    
    @StateObject var viewModel: InviteCollaboratorViewModel
    @Binding var selectedCollaborators: [SearchProfile]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            searchField
            selectedSection
                .frame(height: viewModel.selectedProfiles.isEmpty ? 0 : 70)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.profiles) { profile in
                        profileRow(profile: profile)
                            .onTapGesture {
                                withAnimation(.smooth) {
                                    viewModel.didToggleProfile(profile: profile)
                                }
                            }
                            .onAppear {
                                if let lastProfile = viewModel.profiles.last,
                                   lastProfile.id == profile.id {
                                    viewModel.pageNumber += 1
                                    viewModel.isPagination = true
                                    viewModel.getProfiles(pageNo: viewModel.pageNumber)
                                }
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 60)
        .background(
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
        )
        .overlay(
            header
                .padding(.bottom, 4)
                .padding(.horizontal, 12)
                .background(
                    themeManager.currentTheme.backgroundColor
                )
            , alignment: .top
        )
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .onChange(of: selectedCollaborators) { newValue in
            viewModel.syncSelectedProfiles(with: newValue)
        }
        .onAppear {
            viewModel.syncSelectedProfiles(with: selectedCollaborators)
        }
    }
}


// MARK: - Invite Collaborator Components
extension InviteCollaboratorView {
    
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    dismiss.callAsFunction()
                }
            
            Text("invite_collaborator".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                selectedCollaborators = viewModel.selectedProfiles
                dismiss.callAsFunction()
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
    
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17))
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            
            TextField(
                "",
                text: $viewModel.searchFieldText,
                prompt: Text("search".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            )
            .foregroundStyle(themeManager.currentTheme.label)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 46)
        .padding(.horizontal, 16)
        .background(
            CapsuleBackground(backgroundColor: themeManager.currentTheme.darkGray05_white)
        )
    }
    
    
    private var selectedSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.selectedProfiles) { profile in
                    profileImage(profile: profile)
                        .overlay(
                            xmarkButton
                                .frame(width: 24, height: 24)
                                .background(Color.black.opacity(0.001))
                                .onTapGesture {
                                    withAnimation(.smooth) {
                                        viewModel.didDeselectProfile(profile: profile)
                                    }
                                }
                                .offset(x: 4, y: -4)
                            , alignment: .topTrailing
                        )
                }
            }
            .animation(.none, value: viewModel.selectedProfiles)
        }
    }
    
    
    private func profileRow(profile: SearchProfile) -> some View {
        HStack(spacing: 15) {
            WebImage(url: URL(string: profile.accountType == "business" ? profile.businessProfileRef?.profilePic?.small ?? "" : profile.profilePic?.small ?? ""), content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 41, height: 41)
                    .clipShape(Circle())
                    .padding(.leading, 8)
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 41, height: 41)
                    .clipShape(Circle())
                    .padding(.leading, 8)
            })
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(profile.accountType == "individual" ? profile.name ?? "" : profile.businessProfileRef?.name ?? "")
                        .font(.custom(Constants.comicFont, size: 16))
                        .foregroundColor(themeManager.currentTheme.label)
                    
                    if profile.role == "official" {
                        Image(systemName: "checkmark.seal.fill")
                            .resizable()
                            .foregroundColor(.hmIndigo)
                            .frame(width: 16, height: 16)
                    }
                }
                
                if profile.accountType == "individual" {
                    Text(profile.username ?? "")
                        .font(.custom(Constants.comicFont, size: 11))
                        .foregroundColor(themeManager.currentTheme.white04_darkGray07)
                        .lineLimit(1)
                }
                
                if profile.accountType == "business" {
                    HStack(spacing: 2) {
                        WebImage(url: URL(string: profile.businessProfileRef?.businessTypeRef?.icon ?? ""))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 11, height: 11)
                        
                        Text(profile.businessProfileRef?.businessTypeRef?.name ?? "")
                            .font(.custom(Constants.comicFont, size: 11))
                            .foregroundColor(themeManager.currentTheme.white04_darkGray07)
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(
                        CapsuleBackground(height: 20, borderColor: themeManager.currentTheme.mediumGray_hmIndigo05, backgroundColor: themeManager.currentTheme.darkGray05_hmIndigo02)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 30)
            .frame(height: 46, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 58, alignment: .center)
        .background(
            CustomShape3()
                .fill(themeManager.currentTheme.black09_white)
                .overlay(
                    Circle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .frame(width: 24)
                        .offset(x: -4, y: 4)
                        .overlay(
                            VStack {
                                Image("Tick")
                                    .resizable()
                                    .renderingMode(.template)
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.currentTheme.white_hmIndigo)
                                    .scaledToFit()
                                    .opacity(profile.isSelected ?? false ? 1.0 : 0.0)
                                    .frame(width: 13)
                                    .offset(x: -4, y: 4)
                                    .animation(.smooth, value: profile.isSelected)
                            }
                        )
                    , alignment: .topTrailing
                )
        )
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
        )
    }
    
    
    private func profileImage(profile: SearchProfile) -> some View {
        VStack {
            WebImage(url: URL(string: profile.accountType == "business" ? profile.businessProfileRef?.profilePic?.small ?? "" : profile.profilePic?.small ?? ""), content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60)
                    .clipShape(Circle())
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60)
                    .clipShape(Circle())
            })
            
            Text(profile.accountType == "individual" ? profile.name ?? "" : profile.businessProfileRef?.name ?? "")
                .font(.custom(Constants.comicFont, size: 9))
                .foregroundColor(themeManager.currentTheme.label)
        }
    }
    
    
    private var xmarkButton: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .frame(width: 16)
            
            Image(systemName: "xmark")
                .renderingMode(.template)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}


// MARK: - Invite Collaborator ViewModel

final class InviteCollaboratorViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = TagPeopleDataManager()
    var cancellables = Set<AnyCancellable>()
    var task: Task<(), Never>? = nil
    
    @Published var searchFieldText: String = ""
    @Published var profiles: [SearchProfile] = []
    @Published var newProfiles: [SearchProfile] = []
    @Published var selectedProfiles: [SearchProfile]
    @Published var isPagination: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var pageNumber: Int = 1
    @Published var totalPageNumber: Int = 1
    @Published var recentQuery: String = ""
    
    
    init(router: AnyRouter, selectedProfiles: [SearchProfile] = []) {
        self.router = router
        self.selectedProfiles = selectedProfiles
        addSubscribers()
        getProfiles(pageNo: 1)
    }
    
    
    private func addSubscribers() {
        $searchFieldText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                
                guard recentQuery != query else { return }
                recentQuery = query
                
                isPagination = false
                pageNumber = 1
                totalPageNumber = 1
                
                getProfiles(query: query, pageNo: pageNumber)
            }
            .store(in: &cancellables)
        
        $newProfiles
            .map { [weak self] profiles -> [SearchProfile] in
                guard let self else { return [] }
                
                return profiles.map { profile in
                    var mutableProfile = profile
                    if self.selectedProfiles.contains(where: { $0.id == profile.id }) {
                        mutableProfile.isSelected = true
                    } else {
                        mutableProfile.isSelected = false
                    }
                    return mutableProfile
                }
            }
            .sink { [weak self] profiles in
                guard let self else { return }
                
                if isPagination {
                    self.profiles += profiles
                } else {
                    self.profiles = profiles
                }
            }
            .store(in: &cancellables)
    }
    
    
    func didToggleProfile(profile: SearchProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        
        var updatedProfile = profiles[index]
        let currentlySelected = updatedProfile.isSelected ?? false
        updatedProfile.isSelected = !currentlySelected
        profiles[index] = updatedProfile
        
        if updatedProfile.isSelected ?? false {
            if !selectedProfiles.contains(where: { $0.id == updatedProfile.id }) {
                selectedProfiles.append(updatedProfile)
            }
        } else {
            selectedProfiles.removeAll(where: { $0.id == updatedProfile.id })
        }
    }
    
    
    func didDeselectProfile(profile: SearchProfile) {
        selectedProfiles.removeAll(where: { $0.id == profile.id })
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index].isSelected = false
        }
    }
    
    
    func syncSelectedProfiles(with profiles: [SearchProfile]) {
        selectedProfiles = profiles
        
        self.profiles = self.profiles.map { profile in
            var mutableProfile = profile
            mutableProfile.isSelected = profiles.contains(where: { $0.id == profile.id })
            return mutableProfile
        }
    }
}


// MARK: - Networking
extension InviteCollaboratorViewModel {
    
    func getProfiles(query: String = "", pageNo: Int) {
        guard pageNumber <= totalPageNumber else { return }
        
        showLoadingIndicator = true
        
        task = Task {
            do {
                let result = try await dataManager.getTagPeople(pageNo: pageNo, query: query)
                
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            newProfiles = data
                        }
                        pageNumber = result.pageNo ?? 1
                        totalPageNumber = result.totalPages ?? 1
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
}


struct accessCameraView: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var isPresented
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
}

// Coordinator will help to preview the selected image in the View.
class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: accessCameraView
    
    init(picker: accessCameraView) {
        self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        self.picker.selectedImage = selectedImage
        self.picker.isPresented.wrappedValue.dismiss()
    }
}



struct CreatePostScreen: View {
    
    @StateObject var viewModel: CreatePostViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @State var showTagScreen: Bool = false
    @State var showCollaboratorScreen: Bool = false
    @State var showFeelingScreen: Bool = false
    
    @AppStorage("name") var name: String = ""
    @AppStorage("profilePic") var profilePic: String = ""
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    profileHeader
                    VStack {
                        if viewModel.reviewPlace != nil {
                            reviewImageView
                        }
                        descriptionField
                            .frame(minHeight: Constants.screenHeight * 0.22)
                            .padding(.horizontal, 8)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    doneButton
                                }
                            }
                        
                        imagesGrid
                        tagsSection
                            
                    }
                    .frame(minHeight: Constants.screenHeight * 0.22)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray06_darkGray008)
                    )
                    
                    VStack {
                        customButton(icon: themeManager.currentTheme.PhotoIcon3, title: "photo_video".localized(localizationManager.language))
                            .onTapGesture {
                                
                                if viewModel.mediaAttachments.count < 10 {
                                    if viewModel.hasSelectedSomeMedia {
                                        viewModel.showBottomAlert(message: "please_wait_while_your_selected_video_is_being_processed...".localized(localizationManager.language))
                                    } else {
                                        viewModel.photoPickerItem = nil
                                        viewModel.photoPickerItems.removeAll()
                                        viewModel.showPicker.toggle()
                                    }
                                    
                                } else {
                                    
                                    ErrorModalManager.showErrorModal(router: viewModel.router, errorText: "you_cannot_select_more_than_10_items".localized(localizationManager.language))
                                    
                                }
                                
                                
                                
                            }
                            .photosPicker(
                                isPresented: $viewModel.showPicker,
                                selection: $viewModel.photoPickerItems,
                                maxSelectionCount: 1
                            )
                            .ignoresSafeArea()
                            
                        customButton(icon: themeManager.currentTheme.TagIcon, title: "tag_people".localized(localizationManager.language))
                            .onTapGesture {
                                showTagScreen.toggle()
                            }
                            .fullScreenCover(isPresented: $showTagScreen,
                                             content: {
                                TagPeopleView(
                                    viewModel: TagPeopleViewModel(router: viewModel.router, selectedProfiles: viewModel.tagProfiles),
                                    selectedProfiles: $viewModel.tagProfiles
                                )
                                .environmentObject(localizationManager)
                            })
                        customButton(systemIcon: "person.2.circle", title: "invite_collaborator".localized(localizationManager.language))
                            .onTapGesture {
                                showCollaboratorScreen.toggle()
                            }
                            .fullScreenCover(isPresented: $showCollaboratorScreen) {
                                InviteCollaboratorView(
                                    viewModel: InviteCollaboratorViewModel(router: viewModel.router, selectedProfiles: viewModel.collaboratorProfiles),
                                    selectedCollaborators: $viewModel.collaboratorProfiles
                                )
                                .environmentObject(localizationManager)
                            }
                        customButton(icon: themeManager.currentTheme.HappyIcon, title: "feeling_activity".localized(localizationManager.language))
                            .onTapGesture {
                                showFeelingScreen.toggle()
                            }
                            .fullScreenCover(isPresented: $showFeelingScreen) {
                                AddFeelingView(viewModel: AddFeelingViewModel(router: viewModel.router, selectedFeeling: viewModel.feeling), selectedFeeling: $viewModel.feeling)
                                    .environmentObject(localizationManager)
                            }
                        customButton(icon: themeManager.currentTheme.CheckIn, title: "check_in".localized(localizationManager.language))
                            .onTapGesture {
                                viewModel.showCheckinScreen()
                            }
                            
                        customButton(icon: themeManager.currentTheme.CameraIcon2, title: "camera".localized(localizationManager.language))
                            .fullScreenCover(isPresented: $viewModel.showCustomCamera) {
                                CameraView(
                                    isPresented: $viewModel.showCustomCamera,
                                    onPhotoCaptured: { image in
                                        viewModel.handleCameraPhoto(image)
                                    },
                                    onVideoCaptured: { url in
                                        viewModel.handleCameraVideo(url)
                                    }
                                )
                                .environmentObject(themeManager)
                            }
                            .onTapGesture {
                                viewModel.showCustomCamera.toggle()
                            }
                        
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray06_darkGray008)
                    )
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 54)
            }
            .clipped()
            .overlay(
                header
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                    .background(themeManager.currentTheme.backgroundColor)
                
                , alignment: .top
            )
        }
        .overlay {
            ZStack {
                if viewModel.showLoadingAnimation {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    VStack {
                        LottieView(animation: .named("Animation-Posting"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
                            
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
            }
        }
        .overlay {
            ZStack {
                if viewModel.postUploaded {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    VStack {
                        Spacer()
                        LottieView(animation: .named("Animation-Uploaded"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                            .animationDidFinish { completed in
                                viewModel.postUploaded = false
                                viewModel.dismissScreen()
                            }
                            .scaleEffect(1.5)
                        Spacer()
                        Text("your_post_has_been_uploaded_and_will_be_live_shortly".localized(localizationManager.language))
                            .font(.custom(Constants.comicFont, size: 12))
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
            }
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.hasSelectedSomeMedia)
        }
    }
}

// MARK: - Preview

struct CreatePostScreen_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        CreatePostScreen(viewModel: CreatePostViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}

// MARK: - Components
extension CreatePostScreen {
    
    private var tagsSection: some View {
        HStack(alignment: .top) {
            if !viewModel.tagProfiles.isEmpty {
                Text("tags:".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 12))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }
            
            HFlow {
                ForEach(viewModel.tagProfiles) { profile in
                    HStack {
                        Circle()
                            .fill(.hmIndigo)
                            .frame(width: 18)
                            .overlay(
                                Image(systemName: "xmark")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.white)
                                    .scaledToFit()
                                    .fontWeight(.black)
                                    .frame(width: 7, height: 7)
                            )
                            .onTapGesture {
                                viewModel.tagProfiles.removeAll(where: {$0.id == profile.id})
                            }
                        Text(profile.username ?? "")
                            .font(.custom(Constants.comicFont, size: 11))
                            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        
                    }
                    .padding(.horizontal, 6.5)
                    .padding(.vertical, 4.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6.5)
                            .fill(themeManager.currentTheme.mediumGray_mediumGray03)
                    )
                }
            }
            .padding(.leading, 8)
            .frame(width: UIScreen.main.bounds.width * 0.7, alignment: .leading)
//            .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(.leading, 8)
        .padding(.bottom, 8)
    }
    
    
    private func customButton(icon: String? = nil, systemIcon: String? = nil, title: String) -> some View {
        HStack {
            if let icon {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .padding(.leading, 8)
            } else if let systemIcon {
                Image(systemName: systemIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .padding(.leading, 12)
            }
            Text(title)
                .font(.custom(Constants.comicFont, size: 13))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .padding(.trailing, 16)
        }
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.black09_white)
        )
    }
    
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            ZStack(alignment: .topLeading) {
                if viewModel.descriptionFieldText.isEmpty {
                    Text("what's_in_your_mind".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                        .offset(x: 10, y: 10)
                }
                
                TextEditor(text: $viewModel.descriptionFieldText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundStyle(themeManager.currentTheme.label)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    viewModel.dismissScreen()
                }
            
            Text("create_post".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                endEditing()
//                viewModel.createPost()
                viewModel.createPostBackground()
                viewModel.postUploaded = true
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
                    .opacity(viewModel.descriptionFieldText.isEmpty && viewModel.mediaAttachments.isEmpty ? 0.5 : 1.0)
            })
            .disabled(viewModel.descriptionFieldText.isEmpty && viewModel.mediaAttachments.isEmpty)
        }
        .padding(.top, 16)
    }
    
    
    private var imagesGrid: some View {
        LazyVGrid(columns: viewModel.imagesColumns, content: {
            ForEach(viewModel.mediaAttachments) { attachment in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.hmDarkestGray.opacity(0.6))
                    .overlay(
                        Image(uiImage: attachment.thumbnail)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    )
                    .overlay(
                        Button(action: {
                            
                        }, label: {
                            Image("PlayIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .opacity(attachment.type == .video(UIImage(), URL(string: "https://www.google.com")!) ? 1 : 0)
                        })
                        
                    )
                    .overlay(
                        Circle()
                            .fill(.hmIndigo)
                            .frame(width: 18)
                            .overlay(
                                Image(systemName: "xmark")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.white)
                                    .scaledToFit()
                                    .fontWeight(.black)
                                    .frame(width: 7, height: 7)
                                    .overlay(
                                        Color.black.opacity(0.001)
                                            .frame(width: 20, height: 20)
                                            .onTapGesture {
                                                if let index = viewModel.mediaAttachments.firstIndex(where: { $0.id == attachment.id }) {
                                                    viewModel.mediaAttachments.remove(at: index)
                                                }
                                            }
                                    )
                                    
                            )
                            .offset(x: -5, y: 5)
                        , alignment: .topTrailing
                    )
                    .frame(height: (UIScreen.main.bounds.width / 2) - 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        })
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    
    private var profileHeader: some View {
        HStack (spacing: 15) {
            WebImage(url: URL(string: profilePic), content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38)
                    .clipShape(Circle())
            }, placeholder: {
                Image("NoProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38)
                    .clipShape(Circle())
            })
            
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
                
                if let feeling = viewModel.feeling {
                    HStack(spacing: 2) {
                        Image("Smily")
                        Text(feeling.title)
                            .font(.custom(Constants.comicFont, size: 11))
                            .foregroundColor(.hmIndigo)
                    }
                    .onTapGesture {
                        showFeelingScreen.toggle()
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.darkGray06_darkGray008)
        )
    }
    
    
    private var secondProfileDetailView: some View {
        HStack(alignment: .top, spacing: 15) {
            profilePic2
                .offset(y: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.reviewPlace?.businessProfileRef?.name?.capitalized ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundStyle(themeManager.currentTheme.label)
                    .lineLimit(1)
                
                Text(viewModel.addressString)
                    .lineLimit(2)
            }
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundStyle(themeManager.currentTheme.white04_darkGray07)
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
    }
    
    
    private var profilePic2: some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: 46, height: 46)
            .overlay(
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 43)
            )
            .overlay(
                
                WebImage(url: URL(string: viewModel.profileImage), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 39, height: 39)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 39, height: 39)
                })
                
            )
    }
    
    
    private var reviewImageView: some View {
        RoundedRectangle(cornerRadius: 10)
            .frame(minHeight: 150)
            .overlay(
                WebImage(url: viewModel.coverImage.isEmpty ? nil : URL(string: viewModel.coverImage), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }, placeholder: {
                    Image("CoverPlaceholder")
                        .resizable()
                        .scaledToFill()
                })
                    
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(.ultraThinMaterial.opacity(0.85))
//                        .preferredColorScheme(.dark)
                        .frame(height: 68)
                    secondProfileDetailView
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 6)
                        .padding(.horizontal, 10)
                }
                
                .clipShape(RoundedRectangle(cornerRadius: 10))
                , alignment: .top
            )
            .overlay(alignment: .topTrailing, content: {
                Circle()
                    .fill(.hmIndigo)
                    .frame(width: 20)
                    .overlay(
                        Image(systemName: "xmark")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .scaledToFit()
                            .fontWeight(.black)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Color.black.opacity(0.001)
                                    .frame(width: 30, height: 30)
                                    .onTapGesture {
                                        viewModel.reviewPlace = nil
                                    }
                            )
                            
                    )
                    .offset(x: -8, y: 8)
            })
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray06_darkGray008)
            )
    }
}
