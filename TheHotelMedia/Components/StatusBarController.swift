//
//  StatusBarController.swift
//  TheHotelMedia
//
//  Created by MAC on 04/02/25.
//

import SwiftUI

struct StatusBarController: UIViewControllerRepresentable {
    let style: UIStatusBarStyle

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        uiViewController.overrideUserInterfaceStyle = (style == .lightContent) ? .dark : .light
        uiViewController.setNeedsStatusBarAppearanceUpdate()
    }
}

