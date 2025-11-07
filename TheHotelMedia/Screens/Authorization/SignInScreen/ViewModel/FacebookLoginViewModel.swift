//
//  FacebookLoginViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import Foundation
import FacebookLogin


struct FacebookLoginModel {
    var id = UUID().uuid
    var fist_name: String = ""
    var name: String = ""
    var email: String = ""
}


class FacebookLoginViewModel: ObservableObject{
    
    let facebookLoginManager = LoginManager()
    @Published var error: String? = nil
    @Published var facebookToken: String? = nil
    
    func logIn(onReceiveToken: ((String) -> Void)?, onReceiveError: ((Error) -> Void)?) {
        
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {return }
        
        facebookLoginManager.logIn(permissions: ["public_profile", "email"], from: presentingViewController) { result, error in
            if let token = result?.token?.tokenString {
                onReceiveToken?(token)
                
            } else if let error {
                onReceiveError?(error)
            }
        }
    }
    
    func logOut(){
        // Do logOut
    }
}
