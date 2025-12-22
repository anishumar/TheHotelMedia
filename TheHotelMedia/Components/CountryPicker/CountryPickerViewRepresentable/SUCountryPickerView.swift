//
//  SUCountryPickerView.swift
//  HotelMedia
//
//  Created by MAC on 30/08/24.
//

import SwiftUI
import CountryPickerView

struct SUCountryPickerView: UIViewControllerRepresentable {
    
    @Binding var selectedCountry: Country?
    
    func makeCoordinator() -> CountryPickerViewCoordinator {
        return CountryPickerViewCoordinator(selectedCountry: $selectedCountry)
    }
    
    func makeUIViewController(context: Context) -> CountryPickerViewController {
        let countryPickerVC = CountryPickerViewController()
        countryPickerVC.delegate = context.coordinator
        return countryPickerVC
    }
    
    func updateUIViewController(_ uiViewController: CountryPickerViewController, context: Context) {
        // Handle updates if needed, such as updating the selected country
        if let country = selectedCountry {
            uiViewController.setCountry(country)
        }
    }
}

class CountryPickerViewCoordinator: NSObject, CountryPickerViewControllerDelegate {
    
    @Binding var selectedCountry: Country?
    
    init(selectedCountry: Binding<Country?>) {
        self._selectedCountry = selectedCountry
    }
    
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        selectedCountry = country
    }
}
