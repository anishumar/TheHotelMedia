//
//  BusinessDetailViewModel.swift
//  HotelMedia
//
//  Created by MAC on 06/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import CountryPickerView
import PhoneNumberKit
import GooglePlaces
import CoreLocation


final class BusinessDetailViewModel: ObservableObject {
    
    let router: AnyRouter
    let selectedType: TypeModel
    let dataManager = BusinessSubTypeDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var possibleLength: Int = 10
    @Published var hotelNameFieldText: String = ""
    @Published var addressFieldText: String = ""
    @Published var contactFieldText: String = ""
    @Published var websiteFieldText: String = ""
    @Published var emailFieldText: String = ""
    @Published var gstFieldText: String = ""
    @Published var hotelStarFieldText: String = ""
    @Published var amenitiesFieldText: String = ""
    @Published var descriptionFieldText: String = ""
    @Published var hotelLogo: String = ""
    @Published var selectedAmenities: [String] = []
    @Published var nextButtonDisabled: Bool = false
    @Published var hotelStarRightIcon: String? = "chevron.down"
    @Published var hotelStar: String? = nil
    @Published var dropDownOpen: Bool = false
    @Published var dropDownList: [String] = []
    @Published var amenities: [String] = []
    @Published var selectedCountry: Country?
    @Published var errorMessage: String = ""
    @Published var subTypesArray: [SubTypeModel] = []
    @Published var selectedSubType: SubTypeModel? = nil
    @Published var showLoadingIndicator: Bool = false
    @Published var selectedPlace: GMSPlace?
    @Published var showPlaceSearch = false
    @Published var selectedAddress: Address? = nil
    @Published var dialCode: String = "+91"
    
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    let localizationManager = LocalizationManager.shared
    
    init(router: AnyRouter, selectedType: TypeModel) {
        self.router = router
        self.selectedType = selectedType
        dropDownList = [
            "3 Star",
            "4 Star",
            "5 Star",
            "6 Star",
            "7 Star"
        ]
        
        amenities = [
            "Free Breakfast",
            "Free Parking",
            "Free Wifi",
            "Gym",
            "Swimming pool"
        ]
    }
    
    func addSubscribers() {
        $hotelNameFieldText
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .combineLatest($addressFieldText)
            .map { (string1, string2) -> Bool in
                return !string1.isEmpty && !string2.isEmpty ? true : false
            }
            .combineLatest($contactFieldText)
            .map { [weak self] (bool, string1) -> Bool in
                guard let self else { return false }
                return bool && string1.count == possibleLength
            }
            .combineLatest($websiteFieldText)
            .map { [weak self] (bool, string1) -> Bool in
                guard let self else { return false }
                
                if string1.isEmpty && bool {
                    return true
                } else if isValidURL(string1) && bool {
                    return true
                } else {
                    return false
                }
                
            }
            .combineLatest($emailFieldText)
            .map { [weak self] (bool, emailText) -> Bool in
                guard let self else { return false }
                
                return bool && isValidEmail(emailText)
            }
            .combineLatest($gstFieldText)
            .map { [weak self] (bool, string1) in
                guard let self else { return false }
                
                if string1.isEmpty && bool {
                    return true
                } else if isValidGSTIN(string1) && bool {
                    return true
                } else {
                    return false
                }
                
            }
            .combineLatest($selectedSubType)
            .map { (bool, subtype) in
                return bool && subtype != nil
            }
            .combineLatest($descriptionFieldText)
            .map { (bool, string1) in
                return bool && !string1.isEmpty
            }
            .sink { [weak self] bool in
                guard let self else { return }
                
                nextButtonDisabled = !bool
            }
            .store(in: &cancellables)
        
        $selectedCountry
            .sink { [weak self] country in
                guard let self else { return }
                if let country {
                    let symbol = country.code
                    possibleLength = getPossibleLengths(symbol: symbol)
                    dialCode = country.phoneCode
                    contactFieldText = contactFieldText
                }
            }
            .store(in: &cancellables)
        
        $selectedPlace
            .sink { [weak self] place in
                guard let self else { return }
                if let place {
                    AddressManager.shared.fetchAddressFromGMSPlace(place: place) { [weak self] address in
                        guard let self else { return }
                        selectedAddress = address
                    }
                }
            }
            .store(in: &cancellables)
        
        $selectedAddress
            .sink { [weak self] address in
                guard let self else { return }
                if let address {
                    let addressString = "\(address.street ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                    addressFieldText = addressString
                }
            }
            .store(in: &cancellables)
    }
    
    
    func showNextScreen() {
        router.showScreen(.push) { router in
            ManagerDetailView(viewModel: ManagerDetailViewModel(router: router, businessData: self.getBusinessData()))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[a-z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    
    private func isValidGSTIN(_ gstin: String) -> Bool {
        return gstin.count == 15
    }
    
    
    func isValidURL(_ urlString: String) -> Bool {
        
        let pattern = "((?:http|https)://)?(?:[\\w\\d\\-_]+\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: urlString.utf16.count)
        return regex.firstMatch(in: urlString, options: [], range: range) != nil
        
//        guard let url = URL(string: urlString),
//              url.scheme != nil,
//              url.host != nil else {
//            return false
//        }
//        return true
    }
    
    
    private func getPossibleLengths(symbol: String) -> Int {
        let phoneNumberUtility = PhoneNumberUtility()
        if let phoneNo = phoneNumberUtility.metadata(for: symbol)?.mobile?.exampleNumber {
            let count = phoneNo.count
            return count
        }
        
        return 10
    }
    
    
    func showErrorModal() {
        router.showModal(transition: .move(edge: .bottom)) {
            BottomAlert(message: self.errorMessage)
        }
        print(self.errorMessage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) {
            self.router.dismissModal()
            self.errorMessage = ""
        }
    }
    
    
    func setErrorMessage() {
        if hotelNameFieldText.isEmpty {
//            errorMessage = "Enter \(selectedType.name ?? "") name."
            errorMessage = "enter_business_name".localized(localizationManager.language)
            return
            
        } else if addressFieldText.isEmpty {
            errorMessage = "select_your_business_address".localized(localizationManager.language)
            return
            
        } else if contactFieldText.count != possibleLength {
            errorMessage = "please_enter_a_valid_contact_number".localized(localizationManager.language)
            return
            
        } else if !websiteFieldText.isEmpty && !isValidURL(websiteFieldText) {
            errorMessage = "please_enter_a_valid_website_link".localized(localizationManager.language)
            return
            
        } else if emailFieldText.isEmpty {
            errorMessage = "enter_your_email_address".localized(localizationManager.language)
            return
            
        } else if !emailFieldText.isEmpty && !isValidEmail(emailFieldText) {
            errorMessage = "please_enter_a_valid_email_address".localized(localizationManager.language)
            return
            
        } else if !gstFieldText.isEmpty && !isValidGSTIN(gstFieldText) {
            errorMessage = "please_enter_a_valid_GSTIN".localized(localizationManager.language)
            return
            
        } else if selectedSubType == nil {
            errorMessage = "please_select_a_subtype".localized(localizationManager.language)
            return
            
        } else if descriptionFieldText.isEmpty {
            errorMessage = "enter_your_bio".localized(localizationManager.language)
            return
            
        }
    }
    
    
    func cancelSubcriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    
    func getBusinessData() -> BusinessData {
        return BusinessData(
            email: nil,
            name: nil,
            accountType: "business",
            dialCode: nil,
            phoneNumber: nil,
            password: nil,
            businessName: hotelNameFieldText,
            businessEmail: emailFieldText,
            businessPhoneNumber: contactFieldText,
            businessDialCode: dialCode,
            businessType: selectedType.id,
            businessSubType: selectedSubType?.id,
            businessDescription: descriptionFieldText,
            businessWebsite: websiteFieldText,
            gstn: gstFieldText,
            street: selectedAddress?.street,
            city: selectedAddress?.city,
            state: selectedAddress?.state,
            zipCode: selectedAddress?.zipCode,
            country: selectedAddress?.country,
            lng: "\(selectedAddress?.lng ?? 0)",
            lat: "\(selectedAddress?.lat ?? 0)",
            placeID: selectedPlace?.placeID
        )
    }
}


// MARK: - Networking
extension BusinessDetailViewModel {
    
    func getSubTypes() {
//        guard networkMonitor.isConnected else {
//            errorMessage = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getBusinessSubType(id: selectedType.id ?? "")
                
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
                if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                    if let data = result.data {
                        await MainActor.run {
                            subTypesArray = data
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


// MARK: - Reverse Geocoding
extension BusinessDetailViewModel {
    
    func fetchAddressFromGMSPlace(place: GMSPlace, completion: @escaping (Address?) -> Void) {
        let geocoder = CLGeocoder()
        
        // Get the coordinates from the GMSPlace
        let location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        
        // Perform reverse geocoding to get address
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                print("Reverse geocoding failed: \(error?.localizedDescription ?? "No error information")")
                completion(nil)
                return
            }
            
            // Create the Address model
            let address = Address(
                street: placemark.thoroughfare,      // Street name
                city: placemark.locality,            // City name
                state: placemark.administrativeArea, // State or region
                zipCode: placemark.postalCode,       // Postal code
                country: placemark.country,          // Country
                lat: place.coordinate.latitude,      // Latitude from GMSPlace
                lng: place.coordinate.longitude      // Longitude from GMSPlace
            )
            
            // Return the address model
            completion(address)
        }
    }
    
}
