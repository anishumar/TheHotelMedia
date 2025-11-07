//
//  CountryPickerViewController.swift
//  HotelMedia
//
//  Created by MAC on 30/08/24.
//

import UIKit
import CountryPickerView

protocol CountryPickerViewControllerDelegate: AnyObject {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country)
}

class CountryPickerViewController: UIViewController {
    
    var countryPickerView: CountryPickerView!
    weak var delegate: CountryPickerViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        UINavigationBar.appearance().tintColor = UIColor(ThemeManager.shared.currentTheme.label)
        loadCountryPickerView()
        configureTapGesture()
    }

    private func loadCountryPickerView() {
        countryPickerView = CountryPickerView()
        countryPickerView.delegate = self
    }
    
    private func configureTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(showCountriesList))
        view.addGestureRecognizer(tap)
    }
    
    @objc func showCountriesList() {
        countryPickerView.showCountriesList(from: self)
    }
    
}


extension CountryPickerViewController: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        delegate?.countryPickerView(countryPickerView, didSelectCountry: country)
    }
}
