//
//  BusinessTypeAndRatingView.swift
//  TheHotelMedia
//
//  Created by MAC on 20/12/24.
//

import SwiftUI

struct BusinessTypeAndRatingView: View {
    
    var rating: Double?
    var type: String = ""
    var subType: String = ""
    
    var body: some View {
        HStack {
            if !subType.isEmpty {
                Text("\(type) - \(subType)")
                    .lineLimit(1)
            } else {
                Text(type)
                    .lineLimit(1)
            }
            
            
            if let rating {
                if rating > 0 {
                    HStack(spacing: 2) {
                        Text("(")
                        Image("RatingStar")
                            .renderingMode(.template)
                            .foregroundColor(rating.getStarColor())
                            .frame(height: 12)
                        
                        Text("\(String(format: "%.1f", rating))")
                        Text(")")
                        
                        
                    }
                    .font(.custom(Constants.comicFont, size: 11))
                    .foregroundColor(rating.getStarColor())
                }
            }
            
        }
        .padding(.trailing, subType.isEmpty ? 0 : 40)
    }
}

#Preview {
    BusinessTypeAndRatingView(rating: 2)
}
