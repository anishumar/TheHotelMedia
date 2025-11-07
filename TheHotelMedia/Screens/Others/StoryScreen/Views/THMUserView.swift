//
//  THMUserView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct THMUserView: View {
    
    var isMyStory: Bool
    var image: String
    var name: String
    var date: String
    
    var onRightButtonPressed: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        HStack(spacing: Constants.UserView.hStackSpace) {
            
            VStack {
                Image(systemName: "chevron.left")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(.hmIndigo.opacity(0.7))
                            .allowsHitTesting(true)
                    )
            }
            .overlay {
                Rectangle()
                    .fill(.black.opacity(0.001))
                    .frame(width: 50, height: 50)
                    .onTapGesture {
//                        NotificationCenter.default.post(name: .replaceCurrentItemTHM, object: nil)
                        onDismiss?()
                    }
            }
            
            
            WebImage(url: URL(string: image))
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                if !isMyStory {
                    Text(name)
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(.hmGrayMedium)
                }
                
                Text(DateManager.getPostedAgoTime(date: date, language: localizationManager.language))
                    .font(.custom(Constants.comicFont, size: isMyStory ? 16 : 11))
                    .foregroundColor(.hmGrayMedium)
            }
            
            Spacer()
            
            if isMyStory {
                VStack {
                    Image("BinIcon2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(.hmIndigo.opacity(0.7))
                        )
                }
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.001))
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            onRightButtonPressed?()
                        }
                }
                
            } else {
                VStack(spacing: 3) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(.white)
                            .frame(width: 3)
                    }
                }
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(.hmIndigo.opacity(0.7))
                )
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.001))
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            onRightButtonPressed?()
                        }
                }
            }
        }
        .padding(.horizontal)
    }
}

