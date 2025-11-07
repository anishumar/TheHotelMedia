
//  Razorpay.swift
//  TheHotelMedia
//
//  Created by MAC on 22/10/24.


import SwiftUI
import Razorpay

struct RazorpayView: UIViewControllerRepresentable {
    @Binding var name: String
    @Binding var app_name: String
    @Binding var description: String
    @Binding var image: String
    @Binding var themeColor: String
    @Binding var currency: String
    @Binding var order_id: String
    @Binding var amount: String
    @Binding var phoneNumber: String
    @Binding var email: String
    var onPaymentSuccess: (PaymentSuccessModel) -> Void
    var onPaymentError: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPaymentSuccess: onPaymentSuccess, onPaymentError: onPaymentError)
    }

    func makeUIViewController(context: Context) -> RazorpayViewController {
        let viewController = RazorpayViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: RazorpayViewController, context: Context) {
        uiViewController.name = name
        uiViewController.app_name = app_name
        uiViewController.descriptions = description
        uiViewController.image = image
        uiViewController.themeColor = themeColor
        uiViewController.currency = currency
        uiViewController.order_id = order_id
        uiViewController.amount = amount
        uiViewController.phoneNumber = phoneNumber
        uiViewController.email = email
        
    }

    class Coordinator: NSObject,RazorpayViewControllerDelegate {
        
        var onPaymentSuccess: (PaymentSuccessModel) -> Void
        var onPaymentError: (String) -> Void

        init(onPaymentSuccess: @escaping (PaymentSuccessModel) -> Void, onPaymentError: @escaping (String) -> Void) {
            self.onPaymentSuccess = onPaymentSuccess
            self.onPaymentError = onPaymentError
        }

        
        func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {
            let paymentId = response?["razorpay_payment_id"] as! String
            let rezorSignature = response?["razorpay_signature"] as! String
            
            onPaymentSuccess(PaymentSuccessModel(paymentID: paymentId, signature: rezorSignature))
            dismissScreen()
        }
        
        func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
            onPaymentError(str)
            dismissScreen()
        }
        
        
        func dismissScreen() {
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}


struct PaymentSuccessModel {
    let paymentID: String
    let signature: String
}
