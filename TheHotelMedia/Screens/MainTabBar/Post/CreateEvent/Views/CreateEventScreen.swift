//
//  CreateEventScreen.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Lottie

struct CreateEventScreen: View {
    
    @StateObject var viewModel: CreateEventViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @AppStorage("profilePic") var profilePic: String = ""
    @AppStorage("name") var name: String = ""
    @AppStorage("locationString") var locationString: String = ""
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                profileHeader
                VStack(spacing: 12){
                    eventImageView
                        .fullScreenCover(isPresented: $viewModel.showImagePicker){
                            PHPickerSwiftUI(config: viewModel.pickerConfig) { results in
                                viewModel.handlePickedImages(results)
                            }
                            .ignoresSafeArea()
                        }
                        .onTapGesture {
                            viewModel.showImagePicker.toggle()
                        }
                    eventNameField
                        .fullScreenCover(isPresented: $viewModel.showingCropper, content: {
                            ImageCropper(image: $viewModel.selectedImage2,
                                         cropShapeType: $viewModel.cropShapeType,
                                         presetFixedRatioType: $viewModel.presetFixedRatioType,
                                         type: $viewModel.cropperType, transformation: $viewModel.transformation, onCropped: { croppedImage in
                                viewModel.croppedImage = croppedImage
                            })
                            .ignoresSafeArea()
                        })
                    HStack {
                        startDateField
                        startTimeField
                    }
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            viewModel.showStartDatePicker.toggle()
                        }
                    }
                    
                    HStack {
                        endDateField
                        endTimeField
                    }
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            viewModel.showEndDatePicker.toggle()
                        }
                    }
                    
                    eventFormatSection
//                    ZStack {
//                        if viewModel.eventType != nil {
//                            ZStack {
//                                streamingLinkField
//                                    .transition(.move(edge: .top))
//                            }
//                            
//                        }
//                    }
//                    .zIndex(2.0)
//                    .animation(.easeIn(duration: 0.2), value: viewModel.eventType)
                    
                    if viewModel.eventType != nil {
                        streamingLinkField
                            .transition(.move(edge: .top))
                            .animation(.easeIn(duration: 0.2), value: viewModel.eventType)
                    }
                    
                    if viewModel.eventType == .offline {
                        venueNameField
                            .transition(.move(edge: .top))
                            .fullScreenCover(isPresented: $viewModel.showSearchScreen) {
                                PlacesSearchRepresentable(selectedPlace: $viewModel.selectedSearchPlace, isPresented: $viewModel.showSearchScreen)
                                    .edgesIgnoringSafeArea(.all) // Make the autocomplete view full-screen
                            }
                            .overlay {
                                Rectangle()
                                    .fill(Color.black.opacity(0.001))
                                    .onTapGesture {
                                        viewModel.showSearchScreen.toggle()
                                    }
                            }
                            .animation(.easeInOut(duration: 0.2), value: viewModel.eventType)
                    }
                    
                    descriptionField
                        .animation(.bouncy, value: viewModel.eventType)
                    
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 54)
        }
        .clipped()
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay(
            header
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .background(themeManager.currentTheme.backgroundColor)
            
            , alignment: .top
        )
        .overlay {
            ZStack {
                CustomDatePickerView(isActive: $viewModel.showStartDatePicker, selectedDate: $viewModel.datePickerFromDate, dateRange: $viewModel.startDateRange, pickerComponents: [.date, .hourAndMinute]) { date in
                    viewModel.selectedStartDate = date
                }
                
                CustomDatePickerView(isActive: $viewModel.showEndDatePicker, selectedDate: $viewModel.datePickerEndDate, dateRange: $viewModel.endDateRange, pickerComponents: [.date, .hourAndMinute]) { date in
                    viewModel.selectedEndDate = date
                }
//                if viewModel.showStartDatePicker {
//                    DatePicker(
//                        "",
//                        selection: $viewModel.selectedStartDate,
//                        in: viewModel.startDateRange,
//                        displayedComponents: [
//                            .date,
//                            .hourAndMinute
//                        ]
//                    )
//                    .datePickerStyle(.graphical)
//                    .padding()
//                    .padding(.top)
//                    .background(
//                        RoundedRectangle(cornerRadius: 20)
//                            .fill(themeManager.currentTheme.darkGray_white)
//                    )
//                    .padding()
//                    .accentColor(.hmIndigo)
//                    .overlay(alignment: .topTrailing) {
//                        Button(action: {
//                            viewModel.showStartDatePicker = false
//                        }, label: {
//                            Image(systemName: "xmark.circle.fill")
//                                .background(
//                                    Color.white
//                                        .frame(width: 14, height: 14)
//                                )
//                                .foregroundColor(.hmIndigo)
//                                .font(.title2)
//                                .clipShape(
//                                    Circle()
//                                )
//                                
//                        })
//                        .opacity(viewModel.showStartDatePicker ? 1.0 : 0.0)
//                        .offset(x: -25, y: 25)
//                    }
//                }
//                
//                if viewModel.showEndDatePicker {
//                    DatePicker(
//                        "",
//                        selection: $viewModel.datePickerEndDate,
//                        in: viewModel.endDateRange,
//                        displayedComponents: [
//                            .date,
//                            .hourAndMinute
//                        ]
//                    )
//                    .id(viewModel.updateDatePickerBool)
//                    .datePickerStyle(.graphical)
//                    .padding()
//                    .padding(.top)
//                    .background(
//                        RoundedRectangle(cornerRadius: 20)
//                            .fill(themeManager.currentTheme.darkGray_white)
//                    )
//                    .padding()
//                    .accentColor(.hmIndigo)
//                    .overlay(alignment: .topTrailing) {
//                        Button(action: {
//                            viewModel.showEndDatePicker = false
//                        }, label: {
//                            Image(systemName: "xmark.circle.fill")
//                                .background(
//                                    Color.white
//                                        .frame(width: 14, height: 14)
//                                )
//                                .foregroundColor(.hmIndigo)
//                                .font(.title2)
//                                .clipShape(
//                                    Circle()
//                                )
//                                
//                        })
//                        .opacity(viewModel.showEndDatePicker ? 1.0 : 0.0)
//                        .offset(x: -25, y: 25)
//                    }
//                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(
//                Color.black.opacity(0.5).ignoresSafeArea()
//                    .opacity(viewModel.showStartDatePicker || viewModel.showEndDatePicker ? 1.0 : 0.0)
//            )
            
            
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
                        Text("event_uploaded_successfully".localized(localizationManager.language))
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
    }
}

// MARK: - Preview

struct CreateEventScreen_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        
        CreateEventScreen(viewModel: CreateEventViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension CreateEventScreen {
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
            
            Text("create_event".localized(localizationManager.language).capitalized)
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                if viewModel.postButtonDisabled {
                    viewModel.showErrorMessage()
                } else {
                    viewModel.createEvent()
                }
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
                    .opacity(viewModel.hightlightButton ? 1.0 : 0.5)
            })
            .disabled(viewModel.showLoadingAnimation)
        }
        .padding(.top, 16)
    }
    
    
    private var profileHeader: some View {
        HStack (spacing: 15) {
            ZStack {
                Circle()
                    .fill(.hmPeach)
                    .frame(width: 42)
                
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: 39)
                    .overlay(
                        WebImage(url: URL(string: profilePic), content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                        }, placeholder: {
                            Image("NoProfilePic")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                        })
                            
                    )
                
            }
            
            
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundColor(themeManager.currentTheme.label)
                
                HStack(spacing: 2) {
                    Text(locationString)
                        .font(.custom(Constants.comicFont, size: 10))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.trailing, 20)
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
    
    
    private var eventImageView: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(themeManager.currentTheme.darkGray06_darkGray008)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .overlay(
                ZStack {
                    if let image = viewModel.croppedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                        
                    } else {
                        Image("PhotoBig")
                            .resizable()
//                            .renderingMode(.template)
//                            .font(.system(size: 54))
//                            .foregroundColor()
                            .scaledToFit()
                            .frame(width: 54)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray06_darkGray008)
            )
    }
    
    
    private var startDateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("start_date".localized(localizationManager.language))
            HStack(spacing: 0) {
                Image("CalendarIcon")
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                Text(viewModel.startDateString.isEmpty ? "Start Date" : viewModel.startDateString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 46)
            .background(
                ZStack {
                    CapsuleBackground(height: 46, borderColor: viewModel.selectedStartDate != nil ? .hmIndigo : .hmDarkerGray, backgroundColor: themeManager.currentTheme.darkGray05_white)
                }
            )
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var endDateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("end_date".localized(localizationManager.language))
            HStack(spacing: 0) {
                Image("CalendarIcon")
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                Text(viewModel.endDateString.isEmpty ? "End Date" : viewModel.endDateString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 46)
            .background(
                ZStack {
                    CapsuleBackground(height: 46, borderColor: viewModel.selectedEndDate == nil ? .hmDarkerGray : .hmIndigo, backgroundColor: themeManager.currentTheme.darkGray05_white)
                }
            )
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    
    private var startTimeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("start_time".localized(localizationManager.language))
            HStack(spacing: 0) {
                Image("WatchIcon")
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                Text(viewModel.startTimeString.isEmpty ? "Start Time" : viewModel.startTimeString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 46)
            .background(
                ZStack {
                    CapsuleBackground(height: 46, borderColor: viewModel.selectedStartDate != nil ? .hmIndigo : .hmDarkerGray, backgroundColor: themeManager.currentTheme.darkGray05_white)
                }
            )
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var endTimeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("end_time".localized(localizationManager.language))
            HStack(spacing: 0) {
                Image("WatchIcon")
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                Text(viewModel.endTimeString.isEmpty ? "End Time" : viewModel.endTimeString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 46)
            .background(
                ZStack {
                    CapsuleBackground(height: 46, borderColor: viewModel.selectedEndDate == nil ? .hmDarkerGray : .hmIndigo, backgroundColor: themeManager.currentTheme.darkGray05_white)
                }
            )
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var eventFormatSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("event_format".localized(localizationManager.language))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            HStack {
                onlineButton
                offlineButton
            }
        }
        .font(.custom(Constants.comicFont, size: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var onlineButton: some View {
        HStack {
            Text("online".localized(localizationManager.language))
                .foregroundColor(viewModel.eventType == .online && !themeManager.darkThemeActive ? .white : themeManager.currentTheme.white06_darkGray06)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(
            CapsuleBackground(height: 46, borderColor: viewModel.eventType == .online ? .hmIndigo : .hmDarkerGray, backgroundColor: viewModel.eventType == .online && !themeManager.darkThemeActive ? .hmIndigo : themeManager.currentTheme.darkGray05_white)
        )
        .onTapGesture {
            viewModel.eventType = .online
        }
    }
    
    
    private var offlineButton: some View {
        HStack {
            Text("offline".localized(localizationManager.language))
                .foregroundColor(viewModel.eventType == .offline && !themeManager.darkThemeActive ? .white : themeManager.currentTheme.white06_darkGray06)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(
            CapsuleBackground(height: 46, borderColor: viewModel.eventType == .offline ? .hmIndigo : .hmDarkerGray, backgroundColor: viewModel.eventType == .offline && !themeManager.darkThemeActive ? .hmIndigo : themeManager.currentTheme.darkGray05_white)
        )
        .onTapGesture {
            viewModel.eventType = .offline
        }
    }
    
    
    private var eventNameField: some View {
        GrayTextField(
            textfieldText: $viewModel.eventNameFieldText,
            title: "event_name".localized(localizationManager.language),
            placeholder: "enter_event_name".localized(localizationManager.language),
            leftIcon: "EventIcon",
            textInputCapitalization: .characters,
            rightIcon: .constant("")
            )
    }
    
    
    private var streamingLinkField: some View {
        GrayTextField(
            textfieldText: $viewModel.streamingLinkText,
            title: "add_streaming_link".localized(localizationManager.language) + "\(viewModel.eventType == .offline ? " (\("optional".localized(localizationManager.language)))" : "")",
            placeholder: "add_streaming_link".localized(localizationManager.language),
            leftIcon: "StreamingIcon",
            rightIcon: .constant("")
        )
    }
    
    
    private var venueNameField: some View {
        GrayTextField(
            textfieldText: $viewModel.venueNameFieldText,
            title: "event_venue".localized(localizationManager.language),
            placeholder: "enter_venue_name".localized(localizationManager.language),
            leftIcon: "VenueIcon",
            rightIcon: .constant("")
        )
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
    
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("description".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.descriptionFieldText)
                    .scrollContentBackground(.hidden)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                    .frame(height: 120)
                    .padding(10)
                    .background(themeManager.currentTheme.darkGray05_white)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(style: .init(lineWidth: 1))
                            .fill(viewModel.descriptionFieldText.isEmpty ? .hmDarkerGray : .hmIndigo)
                    )
                    .overlay(alignment: .topLeading, content: {
                        if viewModel.descriptionFieldText.isEmpty {
                            Text("description".localized(localizationManager.language))
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                                .offset(x: 16, y: 16)
                        }
                    })
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            doneButton
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
