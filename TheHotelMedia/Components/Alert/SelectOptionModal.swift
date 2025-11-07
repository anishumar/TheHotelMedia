//
//  SelectOptionModal.swift
//  TheHotelMedia
//
//  Created by MAC on 19/09/24.
//

import SwiftUI

struct SelectOptionModal: View {
    
    var options: [String] = []
    var onSelectOption: ((String) -> Void)?
    
    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .font(.custom(Constants.comicFont, size: 18))
                        .foregroundColor(.white)
                        .onTapGesture {
                            haptics(.light)
                            onSelectOption?(option)
                        }
                    
                    if option != options.last {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.9))
            )
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.hmIndigo.opacity(0.5))
            )
            .padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5).ignoresSafeArea())
    }
}

#Preview {
    SelectOptionModal(options: ["Landscape", "Portrait", "Square"])
}
