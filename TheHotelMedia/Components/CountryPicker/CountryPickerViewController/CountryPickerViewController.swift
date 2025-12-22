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
        countryPickerView.showCountryCodeInView = false
        countryPickerView.showPhoneCodeInView = true
        self.view.addSubview(countryPickerView)
        
        countryPickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countryPickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            countryPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            countryPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            countryPickerView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureTapGesture() {
       // let tap = UITapGestureRecognizer(target: self, action: #selector(showCountriesList))
       // view.addGestureRecognizer(tap)
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

extension CountryPickerViewController {
    func setCountry(_ country: Country) {
        countryPickerView.setCountryByCode(country.code)
    }
}
