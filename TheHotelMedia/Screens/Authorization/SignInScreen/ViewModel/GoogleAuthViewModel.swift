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
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            onReceiveError?(NSError(domain: "GoogleAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find presenting view controller"]))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        ) { signInResult, error in
            if let error = error {
                onReceiveError?(error)
                return
            }
            
            guard let result = signInResult else {
                onReceiveError?(NSError(domain: "GoogleAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in result is nil"]))
                return
            }
            
            guard let idToken = result.user.idToken?.tokenString else {
                onReceiveError?(NSError(domain: "GoogleAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve ID token from Google"]))
                return
            }
            
            if let tokenData = idToken.components(separatedBy: ".").dropFirst().first,
               let decodedData = Data(base64Encoded: tokenData.padding(toLength: ((tokenData.count + 3) / 4) * 4, withPad: "=", startingAt: 0)),
               let json = try? JSONSerialization.jsonObject(with: decodedData) as? [String: Any] {
                print("🔍 ID Token Payload:")
                print("   Audience (aud): \(json["aud"] ?? "not found")")
                print("   Issuer (iss): \(json["iss"] ?? "not found")")
                print("   Email: \(json["email"] ?? "not found")")
                print("   Expected aud: 156125638721-eeh3s3mk2te4g38d3emuif6mqnlb7e15.apps.googleusercontent.com")
            }
            
            print("✅ Google ID Token retrieved successfully (length: \(idToken.count) characters)")
            
            onReceiveToken?(idToken)
        }
    }
    
    
    func googleSignOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
}
