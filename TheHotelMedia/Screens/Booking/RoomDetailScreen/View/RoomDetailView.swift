//
//  RoomDetailView.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import SwiftUI
import SDWebImageSwiftUI
import Flow

struct RoomDetailView: View {
    
    @StateObject var viewModel: RoomDetailViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let verticalGrid: [GridItem] = [
        GridItem(.flexible(), spacing: 8, alignment: .leading),
        GridItem(.flexible(), spacing: 8, alignment: .leading),
        GridItem(.flexible(), spacing: 8, alignment: .leading)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CustomHeaderView(title: "Room Details".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            .padding(.horizontal, 12)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .frame(height: Constants.screenHeight * 0.22)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            WebImage(url: URL(string: viewModel.roomData?.cover?.sourceURL ?? ""))
                                .resizable()
                                .scaledToFill()
                                .allowsHitTesting(false)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 12)
                        .onTapGesture {
                            viewModel.selectedMedia = .image(urlString: viewModel.roomData?.cover?.sourceURL ?? "")
                            viewModel.showMediaPreview = true
                        }
                        .fullScreenCover(isPresented: $viewModel.showMediaPreview, onDismiss: {
                            modifyOrientation(.portrait)
                        }, content: {
                            MediaPreviewView(media: viewModel.selectedMedia)
                                .background(BackgroundClearView())
                        })
                        .transaction { transaction in
                            transaction.disablesAnimations = true
                        }
                        
                    
                    Text(viewModel.attributedDescriptionText)
                        .withComicFont(12.5, color: themeManager.currentTheme.white08_darkGray08)
                        .padding(.horizontal, 12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        roomTypeHeaderView
                        if let amenities = viewModel.roomData?.amenitiesRef, !amenities.isEmpty {
                            amenitySectionHeaderView
                        }
                        amenitiesSection
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray06_darkGray008)
                    )
                    .padding(.horizontal, 12)
                    
                    propertyImagesSection
                    
                    VStack(alignment: .leading) {
                        Text("Some helpful facts".localized(localizationManager.language))
                            .withComicFont(16, color: themeManager.currentTheme.label)
                        
                        HStack {
                            Circle()
                                .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image("Check-in-out".localized(localizationManager.language))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                }
                            Text("Check-in/ Check-out".localized(localizationManager.language))
                                .withComicFont(14, color: themeManager.currentTheme.label)
                        }
                        
                        HStack {
                            Circle()
                                .fill(themeManager.currentTheme.label)
                                .frame(width: 2, height: 2)
                            Text("Check-in from:".localized(localizationManager.language))
                                .withComicFont(13, color: themeManager.currentTheme.white08_darkGray08)
                            Text(DateManager.convertOnlyTimeTo12HourFormat(viewModel.roomData?.checkIn ?? "") ?? "")
                                .withComicFont(13, color: themeManager.currentTheme.hmIndigo_hmIndigo05)
                        }
                        
                        HStack {
                            Circle()
                                .fill(themeManager.currentTheme.label)
                                .frame(width: 2, height: 2)
                            Text("Check-out from:".localized(localizationManager.language))
                                .withComicFont(13, color: themeManager.currentTheme.white08_darkGray08)
                            Text(DateManager.convertOnlyTimeTo12HourFormat(viewModel.roomData?.checkOut ?? "") ?? "")
                                .withComicFont(13, color: themeManager.currentTheme.hmIndigo_hmIndigo05)
                        }
                        
                        Text("Languages spoken".localized(localizationManager.language))
                            .withComicFont(14, color: themeManager.currentTheme.label)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    
                    VStack(alignment: .leading) {
                        HFlow {
                            ForEach(viewModel.roomData?.languageSpoken ?? []) { language in
                                HStack {
                                    ImageLoaderView(urlString: (language.flag ?? "").replacingOccurrences(of: "http://ec2-43-205-43-21.ap-south-1.compute.amazonaws.com", with: "https://staging.thehotelmedia.com"))
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                    
                                    Text(language.name ?? "")
                                        .withComicFont(13, color: themeManager.currentTheme.label)
                                }
                                .padding(8)
                                .background(
                                    Capsule()
                                        .fill(themeManager.currentTheme.mediumGray_mediumGray012)
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 80)
                }
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay(alignment: .bottom, content: {
            HStack {
                VStack(alignment: .leading) {
                    Text(DateManager.formatStayDates(fromDate: viewModel.bookingDetail.fromDate, toDate: viewModel.bookingDetail.toDate))
                        .withComicFont(12, color: Color.hmWhite.opacity(0.8))
                    
                    Group {
                        if viewModel.currentRoomCount == 1 {
                            Text(String(format: "₹%.0f", viewModel.perRoomPrice))
                        } else {
                            Text("\(String(format: "₹%.0f", viewModel.perRoomPrice)) * \(viewModel.currentRoomCount) = \(String(format: "₹%.0f", viewModel.perRoomPrice * Double(viewModel.currentRoomCount)))")
                        }
                    }
                    .withComicFont(16, color: Color.hmWhite)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                HStack {
                    HStack(spacing: 10) {
                        Button {
                            guard viewModel.currentRoomCount > viewModel.minRoom else { return }
                            viewModel.currentRoomCount -= 1
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.hmIndigo)
                                Image("Minus")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(4.5)
                            }
                            .frame(width: 24, height: 24)
                        }
                        .opacity(viewModel.currentRoomCount <= viewModel.minRoom ? 0.5 : 1.0)
                        .disabled(viewModel.currentRoomCount <= viewModel.minRoom)
                        
                        Text("\(viewModel.currentRoomCount)")
                            .withComicFont(14, color: themeManager.currentTheme.white_hmIndigo)
                        
                        Button {
//                            guard viewModel.currentRoomCount < viewModel.maxRoom else { return }
                            viewModel.currentRoomCount += 1
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.hmIndigo)
                                Image("Plus")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(4.5)
                            }
                            .frame(width: 24, height: 24)
                        }
//                        .opacity(viewModel.currentRoomCount >= viewModel.maxRoom ? 0.5 : 1.0)
//                        .disabled(viewModel.currentRoomCount >= viewModel.maxRoom)
                    }
                    .padding(8)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme.hmIndigo05_white)
                    )
                    
                    Button {
                        guard let verified = viewModel.checkInData.user?.mobileVerified else {
                            viewModel.showCheckoutScreen()
                            return
                        }
                        
                        if verified {
                            viewModel.showCheckoutScreen()
                        } else {
                            withAnimation(.easeInOut) {
                                viewModel.showContactModal = true
                            }
                        }
                    } label: {
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo05_white)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.currentTheme.white_hmIndigo)
                            }
                    }
                }
            }
            .padding(10)
            .background(
                ZStack {
                    Capsule()
                        .fill(themeManager.currentTheme.black_hmIndigo)
                    Capsule()
                        .stroke(lineWidth: 1)
                        .fill(LinearGradient(colors: [Color.hmDarkerGray, Color.hmDarkerGray.opacity(0.6), .clear, Color.hmDarkerGray.opacity(0.6), Color.hmDarkerGray], startPoint: .leading, endPoint: .trailing))
                }
               
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        })
        .overlay(content: {
            ZStack {
                if viewModel.showContactModal || viewModel.showVerifyModal {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                viewModel.showContactModal = false
                            }
                        }
                }
                
                phoneNumberModal
                verifyModal
            }
        })
        .overlay(content: {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        })
        .onOpenURL { url in
            switch url.scheme {
            case "readmore":
//                guard let host = url.host, host == viewModel.data.id ?? "" else { return }
                viewModel.isExpanded.toggle()
                viewModel.getAttributedDescription(id: "room-detail", descriptionText: viewModel.descriptionText)
                
            default:
                break
            }
        }
    }
}


// MARK: - Components
extension RoomDetailView {
    private func amenityView(title: String) -> some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(.white)
                    .padding(2)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.hmIndigo)
            }
            .frame(width: 16, height: 16)
            
            Text(title)
                .withComicFont(10, color: themeManager.currentTheme.white08_darkGray08)
                .lineLimit(1)
        }
    }
    
    
    private func moreView(count: Int) -> some View {
        HStack(spacing: 4) {
            Image("Plus")
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 16))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .scaledToFill()
                .padding(2.5)
                .frame(width: 16, height: 16)
            
            Text("\(count) more")
                .withComicFont(10, color: themeManager.currentTheme.white08_darkGray08)
        }
    }
    
    
    private var roomTypeHeaderView: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(.hmIndigo)
                
                Image("Bed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            .frame(width: 28, height: 28)
            
            Text(viewModel.roomData?.title ?? "")
                .withComicFont(16, color: themeManager.currentTheme.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var amenitySectionHeaderView: some View {
        HStack {
            Text("Amenities".localized(localizationManager.language))
                .withComicFont(14, color: themeManager.currentTheme.white08_darkGray08)
            
            Spacer()
            
            Button {
                viewModel.showAllAmenities.toggle()
            } label: {
                Text("See all".localized(localizationManager.language))
                    .withComicFont(14, color: themeManager.currentTheme.hmIndigo_hmIndigo05)
            }
            .sheet(isPresented: $viewModel.showAllAmenities) {
                AllAmenitiesView(viewModel: AllAmenitiesViewModel(amenities: viewModel.roomData?.amenitiesRef ?? []))
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.fraction(0.7)])
            }
        }
    }
    
    
    private var amenitiesSection: some View {
        LazyVGrid(columns: verticalGrid, alignment: .leading) {
            if let amenities = viewModel.roomData?.amenitiesRef {
                if amenities.count > 9 {
                    ForEach(0..<8) { index in
                        amenityView(title: amenities[index].name ?? "")
                    }
                    
                    moreView(count: amenities.count - 8)
                    
                } else {
                    ForEach(0..<amenities.count) { index in
                        amenityView(title: amenities[index].name ?? "")
                    }
                }
            }
        }
    }
    
    
    private var propertyImagesSection: some View {
        VStack(alignment: .leading) {
            Text("Property Images".localized(localizationManager.language))
                .withComicFont(16, color: themeManager.currentTheme.label)
                .padding(.horizontal, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(viewModel.roomData?.roomImagesRef ?? []) { ref in
                        ImageLoaderView(urlString: ref.sourceURL ?? "")
                            .frame(width: Constants.screenHeight * 0.19, height: Constants.screenHeight * 0.19)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .onTapGesture {
                                viewModel.selectedMedia = .image(urlString: ref.sourceURL ?? "")
                                viewModel.showMediaPreview = true
                            }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
    
    
    private var keyboardButton: some View {
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
    
    
    private var otpField: some View {
        TextField(
            "",
            text: $viewModel.otpFieldText,
            prompt: Text("Enter verification code".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        )
        .keyboardType(.numberPad)
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.label)
        .padding(.leading, 16)
        .frame(maxWidth: .infinity)
//        .toolbar {
//            ToolbarItemGroup(placement: .keyboard ) {
//                keyboardButtons
//            }
//        }
    }
    
    
    private var resendButton: some View {
        Button(action: {
            viewModel.startTimer()
            viewModel.requestOtp(resend: true)
        }, label: {
            Text("Resend OTP".localized(localizationManager.language))
                .withComicFont(14, color: themeManager.currentTheme.label)
        })
        .padding(.trailing, 16)
    }
    
    
    private var otpFieldSection: some View {
        var phoneNumber: String = viewModel.toVerifyDialCode + " "
        for _ in 0..<5 {
            phoneNumber.append("X")
        }
        
        return VStack(alignment: .leading, spacing: 5) {
            Text("Enter the OTP you received to \(phoneNumber)")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .onAppear {
                    
                }
            
            HStack {
                otpField
                if viewModel.countDownEnded {
                    resendButton
                } else {
                    countDownTimer
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                CapsuleBackground(
                    height: 48,
                    borderWidth: 1,
                    borderColor: themeManager.currentTheme.mediumGray_mediumGray03,
                    backgroundColor: themeManager.currentTheme.darkGray05_white
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var countDownTimer: some View {
        Text("resend_in".localized(localizationManager.language) + "\(viewModel.counter)sec")
            .font(.custom(Constants.comicFont, size: 14))
            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            .padding(.trailing, 16)
    }
    
    
    private var phoneNumberModal: some View {
        ZStack {
            if viewModel.showContactModal {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Phone number!")
                        .withComicFont(16, color: themeManager.currentTheme.label)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ContactTextField(contactText: $viewModel.toVerifyPhoneNumber, selectedCountry: $viewModel.selectedCountry, isBold: true, title: "Phone number", placeholder: "Phone number")
                        Text("A 5 digit OTP will be sent via SMS to verify your mobile number.")
                            .withComicFont(10, color: themeManager.currentTheme.white06_darkGray06)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Button {
                        viewModel.requestOtp()
                        endEditing()
                    } label: {
                        Text("Proceed".localized(localizationManager.language))
                            .withComicFont(16, color: .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                            )
                    }
                    .padding(.bottom, 16)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            keyboardButton
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray_white)
//                        .fill(.ultraThinMaterial)
                )
                .padding()
                .transition(AnyTransition.push(from: .trailing))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    

    private var verifyModal: some View {
        ZStack {
            if viewModel.showVerifyModal {
                VStack(alignment: .leading, spacing: 12) {
                    Text("OTP Verification")
                        .withComicFont(16, color: themeManager.currentTheme.label)
                    
                    otpFieldSection
                    
                    Button {
                        viewModel.verifyOtp()
                    } label: {
                        Text("Next".localized(localizationManager.language))
                            .withComicFont(16, color: .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                            )
                    }
                    .padding(.bottom, 16)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            keyboardButton
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.darkGray_white)
//                        .fill(.ultraThinMaterial)
                )
                .padding()
                .transition(AnyTransition.push(from: .trailing))
                .onAppear {
                    viewModel.startTimer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

