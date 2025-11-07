//
//  RatingStarView.swift
//  HotelMedia
//
//  Created by MAC on 31/07/24.
//

import SwiftUI

struct RatingStarView: View {
    
    var rating: Double
    var spacing: CGFloat?
    var roundDown: Double
    var fraction: Double
    var intRating: Int
    var grayStar: Int
    
    init(rating: CGFloat, spacing: CGFloat? = nil) {
        self.rating = rating
        self.spacing = spacing
        roundDown = floor(rating)
        fraction = rating - roundDown
        intRating = Int(roundDown)
        
        let double = 5 - rating
        let roundDown2 = floor(double)
        grayStar = Int(roundDown2)
    }
    
    var body: some View {
        HStack(spacing: spacing ?? 8) {
            ForEach(0..<intRating) { index in
                Image("RatingStar")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.yellow)
                    .scaledToFit()
            }
            
            if fraction != 0 {
                FractionalStar(fraction: CGFloat(fraction))
            }
            
            
            ForEach(0..<grayStar) { _ in
                Image("RatingStar")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.hmLightGray)
                    .scaledToFit()
            }
        }
    }
}

#Preview {
    RatingStarView(rating: 3.7)
}
