//
//  WeatherView.swift
//  TheHotelMedia
//
//  Created by MAC on 10/01/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct WeatherView: View {
    
    @StateObject var viewModel = WeatherComponentVM()
    private let timer = Timer.publish(every: 8.0, on: .main, in: .common).autoconnect()
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            ZStack {
                if viewModel.currentHeader == "weather" {
                    weatherHeader
                }
            }
            .transition(.fade)
//            .transition(.asymmetric(insertion: .fade(duration: 2.0), removal: .fade(duration: 1.0)))
            
            ZStack {
                if viewModel.currentHeader == "aqiRating" {
                    aqiRatingHeader
                }
            }
            .transition(.fade)
//            .transition(.asymmetric(insertion: .fade(duration: 2.0), removal: .fade(duration: 1.0)))
            
            ZStack {
                if viewModel.currentHeader == "aqi" {
                    aqiHeader
                }
            }
            .transition(.fade)
//            .transition(.asymmetric(insertion: .fade(duration: 2.0), removal: .fade(duration: 1.0)))
        }
        .onReceive(timer) { value in
            guard viewModel.headerCount > 0 else { return }
            
            if let index = viewModel.headerList.firstIndex(of: viewModel.currentHeader) {
                if viewModel.headerCount - 1 <= index {
                    withAnimation(.linear) {
                        viewModel.currentHeader = ""
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.linear) {
                            viewModel.currentHeader = viewModel.headerList[0]
                        }
                    }
                } else {
                    withAnimation(.linear) {
                        viewModel.currentHeader = ""
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.linear) {
                            viewModel.currentHeader = viewModel.headerList[index + 1]
                        }
                    }
                }
            }
        }
        
    }
}

#Preview {
    WeatherView()
}

// MARK: - Date Extension
extension Date {
    func isDaytime() -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: self)
        
        if let hour = components.hour {
            return hour >= 6 && hour < 18 // Daytime is between 6 AM (inclusive) and 6 PM (exclusive)
        }
        
        return false // Default to false if the hour couldn't be determined
    }
}


// MARK: - Components
extension WeatherView {
    
    private var weatherHeader: some View {
        HStack(alignment: .center, spacing: 0) {
            if let weatherType = viewModel.weatherType {
                if weatherType == "clear" {
                    if Date().isDaytime() {
                        WebImage(url: Bundle.main.url(forResource: "clear", withExtension: "gif"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 31, height: 31)
                    } else {
                        WebImage(url: Bundle.main.url(forResource: "night", withExtension: "gif"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 31, height: 31)
                    }
                } else {
                    WebImage(url: Bundle.main.url(forResource: weatherType, withExtension: "gif"))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 31, height: 31)
                }
                
            }
            
            if let temp = viewModel.temp {
                let degreeSymbol = "\u{00B0}"
                Text("\(temp) \(degreeSymbol)C")
                    .withComicFont(16, color: themeManager.currentTheme.label)
                    .offset(y: viewModel.weatherType == "clear" ? 0 : 4)
            }
        }
    }
    
    private var aqiRatingHeader: some View {
        HStack(alignment: .center, spacing: 0) {
            WebImage(url: Bundle.main.url(forResource: "hormone", withExtension: "gif"))
                .resizable()
                .scaledToFit()
                .frame(width: 31, height: 31)
            
            if let aqiString = viewModel.aqiString {
                Text(aqiString)
                    .withComicFont(16, color: themeManager.currentTheme.label)
                    .offset(y: 4)
            }
        }
    }
    
    
    private var aqiHeader: some View {
        HStack(alignment: .center, spacing: 0) {
            Image("AQI")
                .renderingMode(.template)
                .font(.system(size: 31))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(width: 31, height: 31)
            
            if let aqiInt = viewModel.aqiInt {
                Text("\(aqiInt)")
                    .withComicFont(16, color: themeManager.currentTheme.label)
                    .offset(y: 2)
            }
        }
    }
}
