//
//  BusinessDetailView.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import SwiftUI
import Flow
import ActivityIndicatorView

enum BusinessDetailField {
    case name
    case address
    case contact
    case website
    case email
    case gst
    case hotelstar
    case description
}

enum HotelStar: String {
    case star3 = "3 Star"
    case star4 = "4 Star"
    case star5 = "5 Star"
}

struct BusinessDetailView: View {
    // MARK: - Properties
    
    @StateObject var viewModel: BusinessDetailViewModel
    @FocusState var focusedField: BusinessDetailField? 
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    var body: some View {
        ZStack {
            BackgroundImageView()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 37){
                    Image("Logo")
                        .resizable()
                        .frame(width: 92, height: 92)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 26) {
                        title
                        let businessHeader = "\((viewModel.selectedType.name ?? "").localized(localizationManager.language)) \("name".localized(localizationManager.language))"
                        nameField(title: businessHeader, placeholder: businessHeader, icon: viewModel.selectedType.icon ?? "")
                            
                        addressField
                            .focused($focusedField, equals: .address)
                            .overlay {
                                Rectangle()
                                    .fill(.black.opacity(0.001))
                                    .onTapGesture {
                                        viewModel.showPlaceSearch.toggle()
                                    }
                            }
                            .fullScreenCover(isPresented: $viewModel.showPlaceSearch) {
                                PlacesSearchRepresentable(selectedPlace: $viewModel.selectedPlace, isPresented: $viewModel.showPlaceSearch)
                                    .edgesIgnoringSafeArea(.all) // Make the autocomplete view full-screen
                            }
                        
                        contactField
                            
                        websiteField
                            .focused($focusedField, equals: .website)
                        emailField
                            .focused($focusedField, equals: .email)
                        gstField
                            .focused($focusedField, equals: .gst)
                        subTypeField
                            .overlay(
                                dropDownMenu
                                , alignment: .top
                            )
                            .zIndex(1)
                            
                        descriptionField
                            .focused($focusedField, equals: .description)
                        bottomButtonSection
                        
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            keyboardButtons
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, CGFloat(viewModel.subTypesArray.count) * 5)
            }
            .clipped()
        }
        .onAppear {
            viewModel.addSubscribers()
            viewModel.getSubTypes()
        }
        .onDisappear {
            viewModel.cancelSubcriptions()
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
    
    
}

// MARK: - Preview
struct BusinessDetailView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        BusinessDetailView(
            viewModel: BusinessDetailViewModel(router: router, selectedType: TypeModel(id: "", icon: "", name: ""))
        )
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Functions
extension BusinessDetailView {
    func nextField() {
        switch focusedField {
        case .name:
            focusedField = .address
        case .address:
            focusedField = .contact
        case .contact:
            focusedField = .website
        case .website:
            focusedField = .email
        case .email:
            focusedField = .gst
        case .gst:
            focusedField = .hotelstar
        case .hotelstar:
            focusedField = .description
        case .description:
            focusedField = .name
        case nil:
            focusedField = .name
        }
    }
    
    
    func previousField() {
        switch focusedField {
        case .name:
            focusedField = .description
        case .address:
            focusedField = .name
        case .contact:
            focusedField = .address
        case .website:
            focusedField = .contact
        case .email:
            focusedField = .website
        case .gst:
            focusedField = .email
        case .hotelstar:
            focusedField = .gst
        case .description:
            focusedField = .hotelstar
        case nil:
            focusedField = .name
        }
    }
}


// MARK: - Components
extension BusinessDetailView {
    
    private var dropDownMenu: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial.opacity(0.99))
//                .preferredColorScheme(.dark)
            RoundedRectangle(cornerRadius: 25)
                .stroke(lineWidth: 1)
                .foregroundColor(.hmDarkerGray)
            VStack {
                ForEach(viewModel.subTypesArray) { subType in
                    HStack {
                        if viewModel.selectedType.name == "Hotel" {
                            Image("RatingStar")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(.yellow)
                                .frame(width: 18, height: 16)
                                .padding(.leading, 10)
                        }
                            
                        Text(subType.name ?? "")
                            .font(.custom(Constants.comicFont, size: 18))
                            .foregroundColor(viewModel.selectedSubType?.id == subType.id ? .white.opacity(0.6) : themeManager.currentTheme.white06_darkGray06)
                            .padding(.leading, 12)
                        
                        Spacer()
                    }
                    
                    .frame(height: 46)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedSubType?.id == subType.id ? themeManager.currentTheme.hmIndigo07_hmIndigo : .black.opacity(0.001))
                    )
                    .onTapGesture {
                        viewModel.selectedSubType = subType
                        viewModel.dropDownOpen = false
                    }
                    
                }
            }
            .padding(.vertical, 8)
            
        }
            .frame(maxWidth: .infinity)
            .scaleEffect(y: viewModel.dropDownOpen ? 1 : 0, anchor: .top)
            .offset(y: 75)
            .animation(.easeIn(duration: 0.2), value: viewModel.dropDownOpen)
            .padding(.vertical, 8)
    }
    
    
    private var subTypeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            let titleString = "\((viewModel.selectedType.name ?? "").localized(localizationManager.language)) \("type".localized(localizationManager.language))"
            Text(titleString)
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            HStack {
                if viewModel.selectedType.name == "Hotel" && viewModel.selectedSubType != nil {
                    Image("RatingStar")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.yellow)
                        .frame(width: 18, height: 16)
                        .padding(.leading, 10)
                }
                
                Text(viewModel.selectedSubType == nil ? titleString : viewModel.selectedSubType?.name ?? "")
                    .foregroundStyle(viewModel.hotelStar == nil ? themeManager.currentTheme.white06_darkGray06 : themeManager.currentTheme.label)
                    .font(.custom(Constants.comicFont, size: viewModel.hotelStar == nil ? 14 : 18))
                
                Spacer()
                    .background(.black.opacity(0.001))
                
                
                Image(systemName: "chevron.down")
                    .fontWeight(.semibold)
                    .rotationEffect(Angle(degrees: viewModel.dropDownOpen ? 180 : 0))
                    .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                    .animation(.smooth, value: viewModel.dropDownOpen)
            }
            .frame(height: 46)
            .padding(.horizontal, 16)
            .background(
                CapsuleBackground(
                    height: 46,
                    borderColor: viewModel.selectedSubType != nil ? .hmIndigo : .hmDarkerGray,
                    backgroundColor: themeManager.currentTheme.darkGray05_white
                )
            )
            .onTapGesture {
                viewModel.dropDownOpen.toggle()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var keyboardButtons: some View {
        HStack {
            
            Button(action: {
                previousField()
            }, label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(themeManager.currentTheme.label)
            })
            
            Button(action: {
                nextField()
            }, label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.currentTheme.label)
            })
            
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
    
    
    private var title: some View {
        Group {
            Text("business_details".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 20))
                .foregroundStyle(themeManager.currentTheme.label)
        }
    }
    
    
    private var descriptionBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.hmDarkerGray.opacity(0.5))
            
            RoundedRectangle(cornerRadius: 25)
                .stroke(lineWidth: 2)
                .fill(viewModel.descriptionFieldText.isEmpty ? .hmDarkerGray : .hmIndigo)
        }
    }
    
    
    private var photoField: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color.hmDarkerGray.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(lineWidth: 2)
                    .foregroundStyle(Color.hmDarkerGray)
                    
            )
            .overlay(
                Image("PhotoBig")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            )
    }
    
    
    private var bottomButtonSection: some View {
        ZStack {
            VStack {
                Button(action: {
                    viewModel.dismissScreen()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo04_hmIndigo08)
                            .frame(width: 48)
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .tint(.white)
                    }
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            
            VStack {
                CircleProgressButton(progress: .constant(100))
                    .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                    .onTapGesture {
                        if !viewModel.nextButtonDisabled {
                            viewModel.showNextScreen()
                        } else {
                            viewModel.setErrorMessage()
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: viewModel.errorMessage)
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
    
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("bio".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
            
            ZStack(alignment: .topLeading) {
//                if viewModel.descriptionFieldText.isEmpty {
//                    Text("bio".localized(localizationManager.language))
//                        .font(.custom(Constants.comicFont, size: 14))
//                        .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
//                        .offset(x: 16, y: 16)
//                }
                
                TextEditor(text: $viewModel.descriptionFieldText)
                    .scrollContentBackground(.hidden)
//                    .background(themeManager.currentTheme.darkGray05_white)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                    .frame(height: 120)
                    .padding(10)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(style: .init(lineWidth: 1))
                            .foregroundStyle(viewModel.descriptionFieldText.isEmpty ? .hmDarkerGray : .hmIndigo)
                    )
                    .overlay(alignment: .topLeading) {
                        if viewModel.descriptionFieldText.isEmpty {
                            Text("bio".localized(localizationManager.language))
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                                .offset(x: 16, y: 16)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var photoFieldSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("upload_high_quality".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(Color.white.opacity(0.6))
            VStack(spacing: 21) {
                HStack(spacing: 21) {
                    photoField
                    photoField
                }
                
                HStack(spacing: 21) {
                    photoField
                    photoField
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private func nameField(title: String, placeholder: String, icon: String) -> some View {
        GrayTextField(
            textfieldText: $viewModel.hotelNameFieldText,
            title: title,
            placeholder: placeholder,
            leftIcon: icon,
            isURL: true,
            rightIcon: .constant(nil)
        )
        .focused($focusedField, equals: .name)
    }
    
    
    private var logoField: some View {
        GrayTextField(
            textfieldText: $viewModel.hotelLogo,
            title: "hotel_logo".localized(localizationManager.language),
            placeholder: "hotel_logo".localized(localizationManager.language),
            leftIcon: "PhotoIcon",
            rightIcon: .constant(nil)
        )
            .overlay(
                ZStack {
                    HalfCapsule()
                        .fill(.white.opacity(0.2))
                        .frame(width: 75, height: 46)
                    Button(action: {
                        
                    }, label: {
                        Text("browse".localized(localizationManager.language))
                            .foregroundStyle(.white)
                            .font(.custom(Constants.comicFont, size: 14))
                    })
                }
                
                , alignment: .bottomTrailing
            )
    }
    
    
    private var addressField: some View {
        GrayTextField(
            textfieldText: $viewModel.addressFieldText,
            title: "address".localized(localizationManager.language),
            placeholder: "address".localized(localizationManager.language),
            leftIcon: "LocationPin3",
            keyboardtype: .namePhonePad,
            rightIcon: .constant(nil)
        )
    }
    
    
    private var contactField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("contact_number".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                
            HStack(spacing: 5) {
                if let image = viewModel.selectedCountry?.flag {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                        .overlay(
                            SUCountryPickerView(selectedCountry: $viewModel.selectedCountry)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                } else {
                    Image("IndiaFlag")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .overlay(
                            SUCountryPickerView(selectedCountry: $viewModel.selectedCountry)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                    
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                
                TextField(
                    "",
                    text: $viewModel.contactFieldText,
                    prompt:
                        Text("contact_number".localized(localizationManager.language))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .font(.custom(Constants.comicFont, size: 14))
                )
                .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                .focused($focusedField, equals: .contact)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity)
                .onChange(of: viewModel.contactFieldText) { newValue in
                    // Enforce character limit while typing
                    if newValue.count > 10 {
                        viewModel.contactFieldText = String(newValue.prefix(10))
                    }
                }
                
            }
            .padding(.leading, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                CapsuleBackground(height: 46, borderColor: viewModel.contactFieldText.isEmpty ? .hmDarkerGray : .hmIndigo, backgroundColor: themeManager.currentTheme.darkGray05_white)
            )
            
        }
    }
    
    
    private var websiteField: some View {
        GrayTextField(
            textfieldText: $viewModel.websiteFieldText,
            title: "\("website_link".localized(localizationManager.language)) (\("optional".localized(localizationManager.language)))",
            placeholder: "website_link".localized(localizationManager.language),
            leftIcon: "LinkIcon2",
            keyboardtype: .URL,
            textInputCapitalization: .never,
            rightIcon: .constant(nil)
        )
    }
    
    
    private var emailField: some View {
        GrayTextField(
            textfieldText: $viewModel.emailFieldText,
            title: "email".localized(localizationManager.language),
            placeholder: "email".localized(localizationManager.language),
            leftIcon: "MessageIcon2",
            keyboardtype: .emailAddress,
            textInputCapitalization: .never,
            rightIcon: .constant(nil)
        )
    }
    
    
    private var gstField: some View {
        GrayTextField(
            textfieldText: $viewModel.gstFieldText,
            title: "\("gstn".localized(localizationManager.language)) (\("optional".localized(localizationManager.language)))",
            placeholder: "\("gstn".localized(localizationManager.language))",
            leftIcon: "PercentageIcon2",
            textInputCapitalization: .characters,
            hasCharcterLimit: true,
            characterLimit: 15,
            rightIcon: .constant(nil)
        )
    }
    
    
    private var hotelStarField: some View {
        GrayTextField(
            textfieldText: $viewModel.hotelStarFieldText,
            title: "Hotel star rating (e.g 4 star)",
            placeholder: "Select Hotel star rating",
            leftIcon: "StarIcon2",
            keyboardtype: .numberPad,
            rightIcon: $viewModel.hotelStarRightIcon
        ){
            viewModel.hotelStarRightIcon = viewModel.hotelStarRightIcon == "chevron.up" ? "chevron.down" : "chevron.up"
        }
    }
    
    
    private var amenitiesField: some View {
        GrayTextField(
            textfieldText: $viewModel.amenitiesFieldText,
            title: "Amenities",
            placeholder: "",
            leftIcon: "StarIcon",
            rightIcon: .constant(nil)
        )
        
    }
    
    
    private var amenitiesView: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            Text("Amenities")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 11) {
                    amenitiesButton(title: "Free Breakfast")
                    amenitiesButton(title: "Free Parking")
                    amenitiesButton(title: "Free Wifi")
                }
                HStack(spacing: 11){
                    amenitiesButton(title: "Gym")
                    amenitiesButton(title: "Swimming pool")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    private var amenitiesView2: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Amenities")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(.white.opacity(0.6))
            HFlow {
                ForEach(viewModel.amenities, id: \.self) { amenity in
                    amenitiesButton(title: amenity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    
    private func amenitiesButton(title: String) -> some View {
        HStack {
            Text(title)
                .font(.custom(Constants.comicFont, size: 13))
                .foregroundStyle(viewModel.selectedAmenities.contains(title) ? .white : .white.opacity(0.6))
                .frame(height: 35)
        }
        .padding(.horizontal, 13)
        .background(
            CapsuleBackground(
                height: 35,
                borderColor: viewModel.selectedAmenities.contains(title) ? .hmIndigo : .hmDarkerGray,
                backgroundColor: viewModel.selectedAmenities.contains(title) ? .hmIndigo.opacity(0.5) : .hmDarkestGray.opacity(0.5)
            )
        )
        .onTapGesture {
            viewModel.selectedAmenities.contains(title) ? viewModel.selectedAmenities.removeAll(where: {$0 == title}) : viewModel.selectedAmenities.append(title)
        }
        .padding(.trailing, 4)
        .padding(.vertical, 2)
    }
    
}

