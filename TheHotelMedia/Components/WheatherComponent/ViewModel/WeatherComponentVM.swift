//
//  WheatherComponentVM.swift
//  TheHotelMedia
//
//  Created by MAC on 10/01/25.
//

import SwiftUI
import Combine


class WeatherComponentVM: ObservableObject {
    
    let dataManager = WeatherDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var weatherData: WeatherModel? = nil
    @Published var aqiData: AQIModel? = nil
    @Published var temp: Int? = nil
    @Published var weatherType: String? = nil
    @Published var aqiString: String? = nil
    @Published var aqiInt: Int? = nil
    @Published var currentHeader: String = ""
    let locationManager = LocationManager()
    var currentLocationCancellable: AnyCancellable? = nil
    var headerList: [String] = []
    var headerCount: Int = 0
    
    init() {
        addLocationSubscriber()
        addSubscribers()
        locationManager.requestLocation()
    }
    
    
    func addSubscribers() {
        $weatherData
            .sink { [weak self] data in
                guard let self else { return }
                if let data {
                    if let weather = data.weather, !weather.isEmpty {
                        weatherType = weather[0].main?.lowercased()
                        headerList.append("weather")
                        headerCount = headerList.count
                        withAnimation(.linear) {
                            self.currentHeader = "weather"
                        }
                    }
                    
                    if let main = data.main {
                        if let temp = main.feelsLike {
                            let celsiusTemp = temp - 273
                            
                            self.temp = Int(celsiusTemp)
                        }
                    }
                    
                }
            }
            .store(in: &cancellables)
        
        $aqiData
            .sink { [weak self] data in
                guard let self else { return }
                if let data {
                    if let list = data.list, !list.isEmpty {
                        let aqiData = list[0]
                        
                        if let main = aqiData.main, let aqi = main.aqi {
                            aqiString = getAQIQuality(aqi: aqi)
                            headerList.append("aqiRating")
                            headerCount = headerList.count
                        }
                        
                        if let components = aqiData.components {
                            if let pm2_5 = components["pm2_5"] {
                                self.aqiInt = pm2_5.toAQI()
                                headerList.append("aqi")
                                headerCount = headerList.count
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    
    func addLocationSubscriber() {
        currentLocationCancellable = locationManager.$currentLocation.sink(receiveValue: { [weak self] coordinates in
            guard let self else { return }
            
            if let coordinates {
                let lat = coordinates.latitude.magnitude
                let lng = coordinates.longitude.magnitude
                
                getWeather(lat: lat, lng: lng)
                getAQI(lat: lat, lng: lng)
                currentLocationCancellable = nil
            }
        })
    }
    
    
    func getAQIQuality(aqi: Int) -> String {
        switch aqi {
        case 1:
            return "Good"
            
        case 2:
            return "Fair"
            
        case 3:
            return "Moderate"
            
        case 4:
            return "Poor"
            
        case 5:
            return "Very Poor"
            
        default:
            return "Unknown"
        }
    }
}


// MARK: - Networking
extension WeatherComponentVM {
    
    func getWeather(lat: Double, lng: Double) {
        Task {
            do {
                let data = try await dataManager.getWeatherData(lat: lat, lng: lng)
                
                await MainActor.run {
                    weatherData = data
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func getAQI(lat: Double, lng: Double) {
        Task {
            do {
                let data = try await dataManager.getAQIData(lat: lat, lng: lng)
                
                await MainActor.run {
                    aqiData = data
                }
                
            } catch {
                
            }
        }
    }
}


// MARK: - Double Extension
extension Double {
    func toAQI() -> Int {
        switch self {
        case 0.0...12.0:
            return calculateAqiForRange(pm25: self, lowConcentration: 0.0, highConcentration: 12.0, lowAqi: 0, highAqi: 50)
        case 12.1...35.4:
            return calculateAqiForRange(pm25: self, lowConcentration: 12.1, highConcentration: 35.4, lowAqi: 51, highAqi: 100)
        case 35.5...55.4:
            return calculateAqiForRange(pm25: self, lowConcentration: 35.5, highConcentration: 55.4, lowAqi: 101, highAqi: 150)
        case 55.5...150.4:
            return calculateAqiForRange(pm25: self, lowConcentration: 55.5, highConcentration: 150.4, lowAqi: 151, highAqi: 200)
        case 150.5...250.4:
            return calculateAqiForRange(pm25: self, lowConcentration: 150.5, highConcentration: 250.4, lowAqi: 201, highAqi: 300)
        case 250.5...350.4:
            return calculateAqiForRange(pm25: self, lowConcentration: 250.5, highConcentration: 350.4, lowAqi: 301, highAqi: 400)
        case 350.5...500.4:
            return calculateAqiForRange(pm25: self, lowConcentration: 350.5, highConcentration: 500.4, lowAqi: 401, highAqi: 500)
        default:
            return 600
        }
    }
    
    private func calculateAqiForRange(pm25: Double, lowConcentration: Double, highConcentration: Double, lowAqi: Int, highAqi: Int) -> Int {
        return Int(((pm25 - lowConcentration) / (highConcentration - lowConcentration) * Double(highAqi - lowAqi)) + Double(lowAqi))
    }
}
