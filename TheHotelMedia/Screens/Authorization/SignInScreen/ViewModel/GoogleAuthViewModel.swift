//
//  GoogleAuthViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 10/12/24.
//

import Foundation
import GoogleSignIn


class GoogleAuthViewModel {
    
    func handleGoogleSignIn(onReceiveToken: ((String) -> Void)?, onReceiveError: ((Error) -> Void)?) {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {return }
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        ) { signInResult, error in
            if let error = error {
                onReceiveError?(error)
                return
            }
            
            if let result = signInResult {
                // Get the ID Token
                if let idToken = result.user.idToken?.tokenString {
                    onReceiveToken?(idToken)
                }
            }
        }
    }
    
    
    func googleSignOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
}
