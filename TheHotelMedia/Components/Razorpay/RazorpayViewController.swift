//
//  RazorpayViewController.swift
//  TheHotelMedia
//
//  Created by MAC on 22/10/24.
//

import UIKit
import Razorpay
import Combine


protocol RazorpayViewControllerDelegate: AnyObject {
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?)
    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?)
}

class RazorpayViewController: UIViewController {
    
    // Keep a strong reference to the UIWindow to prevent it from being deallocated
    static var razorpayWindow: UIWindow?
    
    var name: String?
    var app_name: String?
    var descriptions: String?
    var image: String?
    var themeColor: String?
    var currency: String?
    var order_id: String?
    var amount: String?
    var email: String?
    var phoneNumber: String?
    var razorpay: RazorpayCheckout!
    weak var delegate: RazorpayViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Constants.razorpayKey)
        razorpay = RazorpayCheckout.initWithKey(Constants.razorpayKey, andDelegateWithData: self)
        configureTapGesture()
    }

    
    private func configureTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(showRazorPay))
        view.addGestureRecognizer(tap)
    }
    
    @objc func showRazorPay() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            guard let name,
                  let app_name,
                  let descriptions,
                  let image,
                  let themeColor,
                  let currency,
                  let order_id,
                  let amount,
                  let email,
                  let phoneNumber else { return }
            
            let options: [String: Any] = [
                "name": name,
                "app_name": app_name,
                "description": descriptions,
                "image": image,
                "theme.color": themeColor,
                "currency": currency,
                "order_id": order_id,
                "amount": amount,
                "prefill" : [
                    "email": email,
                    "contact": phoneNumber
                ],
                "retry": [
                    "enabled": true,
                    "max_count": 4
                ]
            ]
//            razorpay.open(options)
            if let topController = UIViewController.getTopViewController() {
                self.razorpay.open(options, displayController: topController)
            }
        }
    }
}


extension RazorpayViewController: RazorpayPaymentCompletionProtocolWithData {
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {
        delegate?.onPaymentSuccess(payment_id, andData: response)
        
    }
    
    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        delegate?.onPaymentError(code, description: description, andData: response)
    }
}



extension UIViewController {
    static func getTopViewController(base: UIViewController? = nil) -> UIViewController? {
        let rootVC = base ?? (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController)

        if let nav = rootVC as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        } else if let tab = rootVC as? UITabBarController,
                  let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        } else if let presented = rootVC?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return rootVC
    }
}


// MARK: - Razorpay Manager with UIWindow
class RazorpayWindowManager: NSObject, RazorpayPaymentCompletionProtocolWithData {
    private var razorpay: RazorpayCheckout?
    private var razorpayWindow: UIWindow?
    private var originalWindow: UIWindow?

    // Callbacks for handling success & error
//    @Published var onPaymentSuccess: (String, [AnyHashable: Any]?)?
//    @Published var onPaymentSuccess: ((String, [AnyHashable: Any]?) -> Void)?
//    @Published var onPaymentError: ((Int32, String, [AnyHashable: Any]?) -> Void)?

    // Razorpay Key and initialization
    private let razorpayKey = Constants.razorpayKey
    
    override init() {
        super.init()
        razorpay = RazorpayCheckout.initWithKey(razorpayKey, andDelegateWithData: self)
    }

    // Function to create Razorpay payment options
    private func razorpayOptions(amount: String, orderId: String, email: String, phoneNumber: String, currency: String, name: String, description: String, image: String) -> [String: Any] {
        return [
            "name": name,
            "app_name": name,
            "description": description,
            "image": image,
            "amount": amount,
            "currency": currency,
            "order_id": orderId,
            "prefill": [
                "email": email,
                "contact": phoneNumber
            ],
            "theme": ["color": "#082C50"]
        ]
    }


    // Show Razorpay checkout in a new UIWindow
    func presentRazorpay(amount: String, orderId: String, email: String, phoneNumber: String, currency: String, name: String, description: String, image: String) {
        // Ensure there's an active UIWindowScene
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("Failed to access UIWindowScene.")
            return
        }

        // Store reference to the current key window
        originalWindow = scene.windows.first(where: { $0.isKeyWindow })

        originalWindow?.isHidden = true
        // Create a new UIWindow for Razorpay checkout
        razorpayWindow = UIWindow(windowScene: scene)
        let vc = UIViewController()
        razorpayWindow?.rootViewController = vc
        razorpayWindow?.windowLevel = .normal
        razorpayWindow?.isHidden = false

        // Razorpay options setup
        let options = razorpayOptions(amount: amount, orderId: orderId, email: email, phoneNumber: phoneNumber, currency: currency, name: name, description: description, image: image)

        // Open Razorpay checkout in the new window
        if let rootVC = razorpayWindow?.rootViewController {
            razorpay?.open(options, displayController: rootVC)
            print("Razorpay checkout opened with options: \(options)")
        } else {
            print("Failed to get root view controller for Razorpay.")
        }
    }
    
    

    // MARK: - Razorpay Payment Handlers
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            // Post notification with payment data
            NotificationCenter.default.post(
                name: .razorpayPaymentSuccess,
                object: nil,
                userInfo: ["payment_id": payment_id, "response": response as Any]
            )
            self.dismissRazorpay()
        }
    }

    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            // Post notification with error data
            NotificationCenter.default.post(
                name: .razorpayPaymentError,
                object: nil,
                userInfo: ["code": code, "description": str, "response": response as Any]
            )
            self.dismissRazorpay()
        }
    }

    private func dismissRazorpay() {
        // Ensure the Razorpay checkout is dismissed
        if let rootVC = razorpayWindow?.rootViewController {
            rootVC.dismiss(animated: true, completion: nil)
        }

        // Hide and nil the razorpayWindow
        if let window = razorpayWindow {
            window.isHidden = true
            window.windowScene = nil
            razorpayWindow = nil
            print("Razorpay checkout dismissed successfully.")
        }

        // Restore the original window
        originalWindow?.isHidden = false
        originalWindow?.windowLevel = .normal + 1
        originalWindow?.makeKeyAndVisible()
        originalWindow = nil
    }
}


extension Notification.Name {
    static let razorpayPaymentSuccess = Notification.Name("RazorpayPaymentSuccess")
    static let razorpayPaymentError = Notification.Name("RazorpayPaymentError")
}
