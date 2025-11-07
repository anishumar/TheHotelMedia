//
//  CountryHelper.swift
//  TheHotelMedia
//
//  Created by MAC on 11/03/25.
//

import Foundation
import CountryPickerView


class CountryHelper {
    
    static let shared = CountryHelper()
    let countryPicker = CountryPickerView()
    
    
    func getCountry(dialCode: String) -> Country? {
        return countryPicker.getCountryByPhoneCode(dialCode)
    }
}
