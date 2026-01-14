//
//  EditProfileViewModel.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


final class EditProfileViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    @Published var profileData: ProfileData
    var onEditedProfile: ((ProfileData) -> Void)?
    let dataManager = ProfileDataManager()
    
    @Published var showLoadingIndicator: Bool = false
    @Published var errorText: String = ""
    @Published var selectedImage: Image? = nil
    @Published var croppedImage: Image? = nil
    @Published var showCameraPicker: Bool = false
    @Published var showImagePicker: Bool = false
    @Published var showFileImporter: Bool = false
    @Published var showOptionDialog: Bool = false
    @Published var showCropView: Bool = false
    @Published var profilePic: String = ""
    @Published var businessType: String = ""
    @Published var amenitiesRef: [Ref] = []
    
    @AppStorage("profilePic") var savedProfilePic: String = ""
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("locationString") var locationString: String = ""
    
    init(router: AnyRouter, profileData: ProfileData, onEditedProfile: ( (ProfileData) -> Void)? = nil) {
        self.router = router
        self.profileData = profileData
        self.onEditedProfile = onEditedProfile
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $selectedImage
            .sink { [weak self] image in
                guard let self else { return }
                if image != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        guard let self else { return }
                        showCropView = true
                    }
                }
            }
            .store(in: &cancellables)
        
        $croppedImage
            .sink { [weak self] image in
                guard let self else { return }
                if let image {
                    Task {
                        if let uiImage = await image.render(convertToColorDepth: true) {
                            await MainActor.run {
                                self.changeProfilePic(image: uiImage)
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        $profileData
            .sink { [weak self] profileData in
                guard let self else { return }
                
                if self.isIndividual {
                    if let profilePic = profileData.profilePic {
                        self.profilePic = profilePic.medium ?? ""
                    }
                } else {
                    if let profilePic = profileData.businessProfileRef?.profilePic {
                        self.profilePic = profilePic.medium ?? ""
                    }
                    
                    if let type = profileData.businessProfileRef?.businessTypeRef?.name {
                        self.businessType = type
                    }
                    
                    if let amenities = profileData.businessProfileRef?.amenitiesRef, amenities.isNotEmpty {
                        amenitiesRef = amenities
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showEditContactScreen() {
        router.showScreen(.push) { router in
            EditContactView(
                viewModel: EditContactViewModel(
                    router: router,
                    currentDialCode: self.isIndividual ? self.profileData.dialCode ?? "" : self.profileData.businessProfileRef?.dialCode ?? "",
                    currentPhoneNumber: self.isIndividual ? self.profileData.phoneNumber ?? "" : self.profileData.businessProfileRef?.phoneNumber ?? ""
                )
            )
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEditUsernameScreen() {
        router.showScreen(.push) { router in
            EditUsernameView(
                viewModel: EditUsernameViewModel(
                    router: router,
                    currentUsername: self.profileData.username ?? ""
                ),
                onChangedUsername: { [weak self] changedUsername in
                    guard let self else { return }
                    self.editProfileComprehensive(username: changedUsername)
                }
            )
            .environmentObject(ThemeManager.shared)
            .environmentObject(LocalizationManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEditNameScreen() {
        router.showScreen(.push) { router in
            EditNameView(
                viewModel: EditNameViewModel(
                    router: router,
                    currentName: self.isIndividual ? self.profileData.name ?? "" : self.profileData.businessProfileRef?.name ?? ""
                ),
                onChangedName: { [weak self] changedName in
                    guard let self else { return }
                    editProfile(name: changedName)
                }
            )
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEditBillingAddressScreen() {
        router.showScreen(.push) { router in
            EditAddressView(viewModel: EditAddressViewModel(router: router, currentAddress: self.locationString))
                .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEditEmailScreen() {
        router.showScreen(.push) { router in
            EditEmailView(
                viewModel: EditEmailViewModel(
                    router: router,
                    currentEmail: self.profileData.email ?? ""
                ),
                onEmailChanged: { changedEmail in
                    print(changedEmail)
                }
            )
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEditBioScreen() {
        router.showScreen(.push) { router in
            EditBioView(
                viewModel: EditBioViewModel(
                    router: router,
                    currentBio: self.isIndividual ? self.profileData.bio ?? "" : self.profileData.businessProfileRef?.bio ?? ""
                ),
                onChangedBio: { [weak self] changedBio in
                    guard let self else { return }
                    editProfile(bio: changedBio)
                }
            )
            .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showEditCategoryScreen() {
        router.showScreen(.push) { router in
            EditCategoryScreen(viewModel: EditCategoryViewModel(router: router, selectedAnswers: self.profileData.businessProfileRef?.businessAnswerRef ?? []))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showPasswordView() {
        router.showScreen(.push) { router in
            ConfirmEmailView(viewModel: ConfirmEmailViewModel(router: router, email: self.profileData.email ?? ""))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showAmenitiesQuestionsScreen() {
        router.showScreen(.push) { router in
            EditAmenitiesView(viewModel: EditAmenitiesViewModel(router: router, selectedAnswers: self.profileData.businessProfileRef?.businessAnswerRef ?? []))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func getParameters(name: String? = nil, bio: String? = nil) -> [String: Any] {
        var parameters: [String: Any] = [:]
        
        if let name {
            parameters.updateValue(name, forKey: "name")
        } else if let bio {
            parameters.updateValue(bio, forKey: "bio")
        }
        
        return parameters
    }
    
    /// Comprehensive method to build parameters for profile editing with all supported fields
    /// - Parameters:
    ///   - username: Unique username (validated for uniqueness)
    ///   - name: Full name / Business name
    ///   - dialCode: Phone country code
    ///   - phoneNumber: Phone number
    ///   - bio: Biography/Description
    ///   - profession: Profession (Individual only)
    ///   - website: Business website URL (Business only)
    ///   - email: Business email (Business only)
    ///   - gstn: GST number (Business only)
    ///   - businessTypeID: Business type ID (Business only)
    ///   - businessSubTypeID: Business sub-type ID (Business only)
    ///   - language: Preferred language
    ///   - acceptedTerms: Terms acceptance status
    ///   - privateAccount: Account privacy setting
    ///   - notificationEnabled: Notification preference
    /// - Returns: Dictionary of parameters to send to the API
    func buildEditProfileParameters(
        username: String? = nil,
        name: String? = nil,
        dialCode: String? = nil,
        phoneNumber: String? = nil,
        bio: String? = nil,
        profession: String? = nil,
        website: String? = nil,
        email: String? = nil,
        gstn: String? = nil,
        businessTypeID: String? = nil,
        businessSubTypeID: String? = nil,
        language: String? = nil,
        acceptedTerms: Bool? = nil,
        privateAccount: Bool? = nil,
        notificationEnabled: Bool? = nil
    ) -> [String: Any] {
        var parameters: [String: Any] = [:]
        
        // Common fields for both Individual and Business
        if let username = username, !username.isEmpty {
            parameters["username"] = username
        }
        
        if let name = name, !name.isEmpty {
            parameters["name"] = name
        }
        
        if let dialCode = dialCode, !dialCode.isEmpty {
            parameters["dialCode"] = dialCode
        }
        
        if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
            parameters["phoneNumber"] = phoneNumber
        }
        
        if let bio = bio {
            parameters["bio"] = bio
        }
        
        if let language = language, !language.isEmpty {
            parameters["language"] = language
        }
        
        if let acceptedTerms = acceptedTerms {
            parameters["acceptedTerms"] = acceptedTerms
        }
        
        if let privateAccount = privateAccount {
            parameters["privateAccount"] = privateAccount
        }
        
        if let notificationEnabled = notificationEnabled {
            parameters["notificationEnabled"] = notificationEnabled
        }
        
        // Individual account fields
        if isIndividual {
            if let profession = profession, !profession.isEmpty {
                parameters["profession"] = profession
            }
        } else {
            // Business account fields
            if let website = website, !website.isEmpty {
                parameters["website"] = website
            }
            
            if let email = email, !email.isEmpty {
                parameters["email"] = email
            }
            
            if let gstn = gstn, !gstn.isEmpty {
                parameters["gstn"] = gstn
            }
            
            if let businessTypeID = businessTypeID, !businessTypeID.isEmpty {
                parameters["businessTypeID"] = businessTypeID
            }
            
            if let businessSubTypeID = businessSubTypeID, !businessSubTypeID.isEmpty {
                parameters["businessSubTypeID"] = businessSubTypeID
            }
        }
        
        return parameters
    }
    
    
    func imageSelectedFromFileImporter(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                url.stopAccessingSecurityScopedResource()
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                handleImageData(data: data)
                url.stopAccessingSecurityScopedResource()
                
            } catch {
                print("Error obtaining content of pdf from url \(error)")
            }
            
        case .failure(let error):
            print("Error loading pdf \(error)")
        }
    }
    
    
    func handleImageData(data: Data) {
        if let uiImage = UIImage(data: data) {
            selectedImage = Image(uiImage: uiImage)
        }
    }

}


// MARK: - Networking
extension EditProfileViewModel {
    /// Legacy method for backward compatibility - updates name or bio only
    func editProfile(name: String? = nil, bio: String? = nil) {
        let parameters = getParameters(name: name, bio: bio)
        
        guard !parameters.isEmpty else {
            return
        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.editProfileData(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    errorText = result.message
                    ErrorModalManager.showErrorModal(router: router, errorText: errorText)
                    
                    if let data = result.data {
                        profileData = data
                        onEditedProfile?(data)
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
    
    /// Comprehensive method to edit profile with all supported fields
    /// All parameters are optional - only provided fields will be updated
    /// - Parameters:
    ///   - username: Unique username (validated for uniqueness)
    ///   - name: Full name / Business name
    ///   - dialCode: Phone country code
    ///   - phoneNumber: Phone number
    ///   - bio: Biography/Description
    ///   - profession: Profession (Individual only)
    ///   - website: Business website URL (Business only)
    ///   - email: Business email (Business only)
    ///   - gstn: GST number (Business only)
    ///   - businessTypeID: Business type ID (Business only)
    ///   - businessSubTypeID: Business sub-type ID (Business only)
    ///   - language: Preferred language
    ///   - acceptedTerms: Terms acceptance status
    ///   - privateAccount: Account privacy setting
    ///   - notificationEnabled: Notification preference
    func editProfileComprehensive(
        username: String? = nil,
        name: String? = nil,
        dialCode: String? = nil,
        phoneNumber: String? = nil,
        bio: String? = nil,
        profession: String? = nil,
        website: String? = nil,
        email: String? = nil,
        gstn: String? = nil,
        businessTypeID: String? = nil,
        businessSubTypeID: String? = nil,
        language: String? = nil,
        acceptedTerms: Bool? = nil,
        privateAccount: Bool? = nil,
        notificationEnabled: Bool? = nil,
        completion: ((Bool, String) -> Void)? = nil
    ) {
        let parameters = buildEditProfileParameters(
            username: username,
            name: name,
            dialCode: dialCode,
            phoneNumber: phoneNumber,
            bio: bio,
            profession: profession,
            website: website,
            email: email,
            gstn: gstn,
            businessTypeID: businessTypeID,
            businessSubTypeID: businessSubTypeID,
            language: language,
            acceptedTerms: acceptedTerms,
            privateAccount: privateAccount,
            notificationEnabled: notificationEnabled
        )
        
        guard !parameters.isEmpty else {
            completion?(false, "No fields to update")
            return
        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.editProfileData(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    errorText = result.message
                    
                    let success = result.status && (200...204).contains(result.statusCode)
                    
                    if success {
                        ErrorModalManager.showErrorModal(router: router, errorText: errorText)
                        
                        if let data = result.data {
                            profileData = data
                            onEditedProfile?(data)
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: errorText)
                    }
                    
                    completion?(success, result.message)
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    let errorMessage = "Failed to update profile. Please try again."
                    ErrorModalManager.showErrorModal(router: router, errorText: errorMessage)
                    completion?(false, errorMessage)
                }
                print("❌ [EditProfileViewModel] Error editing profile: \(error)")
            }
        }
    }
    
    
    func changeProfilePic(image: UIImage) {
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.changeProfilePic(image: image)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    errorText = result.message
                    ErrorModalManager.showErrorModal(router: router, errorText: errorText)
                    
                    if let data = result.data {
                        if let image = data.profilePic?.medium {
                            profilePic = image
                        }
                        
                        if let image2 = data.profilePic?.small {
                            savedProfilePic = image2
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
}
