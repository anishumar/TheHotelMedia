//
//  BottomAlert.swift
//  HotelMedia
//
//  Created by MAC on 10/09/24.
//

import SwiftUI

struct BottomAlert: View {
    
    var message: String
    
    var body: some View {
        VStack {
            Text(message)
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.hmIndigo)
        )
        .padding(.horizontal)
        
        
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 70)
    }
}

#Preview {
    BottomAlert(message: "Enter email address.")
}
