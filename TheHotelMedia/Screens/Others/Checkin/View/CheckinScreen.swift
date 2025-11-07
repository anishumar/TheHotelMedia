//
//  CheckinScreen.swift
//  TheHotelMedia
//
//  Created by MAC on 01/10/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct CheckinScreen: View {
    
    @StateObject var viewModel: CheckinViewModel
    @StateObject var locationManager = LocationManager()
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let height = UIScreen.main.bounds.height
        VStack {
            if locationManager.currentLocation != nil {
                mapView
            }
            
            Rectangle()
                .fill(themeManager.currentTheme.darkGray_hmwhite)
                .frame(height: height * 0.4)
                .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
        .frame(maxHeight: .infinity)
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.currentLocation, perform: { value in
            if let value {
                viewModel.getPlaces(location: value)
            }
        })
        .overlay(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.currentTheme.darkGray_hmwhite)
                .frame(height: height * 0.45)
                .overlay {
                    bottomSection
                }
        }
        .overlay(alignment: .top) {
            header
                .padding(.horizontal, 16)
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}


// MARK: -  Preview
struct CheckinScreen_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        CheckinScreen(viewModel: CheckinViewModel(router: router))
    }
}



// MARK: - Components
extension CheckinScreen {
    private var header: some View {
        HStack {
            Button(action: {
                viewModel.dismissScreen()
            }, label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    
                    Text("check_in".localized(localizationManager.language))
                        .font(.custom(Constants.comicBold, size: 18))
                        .foregroundColor(.white)
                        .padding(.leading, 10)
                }
            })
            
            Spacer()
                
            Button(action: {
                viewModel.showSearchScreen.toggle()
            }, label: {
                Image("MapSearch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            })
        }
    }
    
    
    private func searchPlaceButtonView(place: Place) -> some View {
        HStack {
            Circle()
                .fill(.white)
                .frame(width: 40 , height: 40)
                .overlay {
                    WebImage(url: URL(string: place.icon ?? ""))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26 , height: 26)
                }
                .padding(.horizontal    , 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name?.capitalized ?? "")
                    .font(.custom(Constants.comicFont, size: 14))
                    .lineLimit(1)
                Text(place.vicinity ?? "")
                    .font(.custom(Constants.comicFont, size: 10))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 16)
        }
        .frame(height: 60)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        themeManager.currentTheme.hmIndigo_hmIndigo05
//                        .shadow(.inner(color: .black, radius: 6))
//                        .shadow(.inner(color: .black, radius: 4))
//                        .shadow(.inner(color: .black, radius: 2))
                    )
//                RoundedRectangle(cornerRadius: 24)
//                    .stroke(lineWidth: 2)
//                    .fill(.hmDarkestGray)
            }
        )
    }
    
    
    private var bottomSection: some View {
        VStack(alignment: .leading) {
            Text("suggested_nearby_places".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 16))
                .foregroundColor(themeManager.currentTheme.label)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(viewModel.places, id: \.self.placeID) { place in
                        searchPlaceButtonView(place: place)
                            .onTapGesture {
                                viewModel.selectedPlaceFromList = place
                            }
                    }
                }
            }
        }
        .padding()
    }
    
    
    private var mapView: some View {
        GoogleMapView(currentLocation: $locationManager.currentLocation, markLocation: .constant(nil), markers: viewModel.markers)
            .id(viewModel.refreshMap)
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Adjust the map height as needed
            .animation(.easeInOut(duration: 0.5), value: locationManager.currentLocation)
            .fullScreenCover(isPresented: $viewModel.showSearchScreen) {
                PlacesSearchRepresentable(selectedPlace: $viewModel.selectedSearchPlace, isPresented: $viewModel.showSearchScreen)
                    .edgesIgnoringSafeArea(.all) // Make the autocomplete view full-screen
            }
    }
}
