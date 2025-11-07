//
//  TaggedPeopleView.swift
//  TheHotelMedia
//
//  Created by MAC on 24/12/24.
//

import SwiftUI

struct TaggedPeopleView: View {
    
    @StateObject var viewModel: TaggedPeopleViewModel
    var onPressedProfile: ((String) -> Void)? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.ignoresSafeArea()
            
            if #available(iOS 16.4, *) {
                customBackground
            } else {
                Rectangle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(viewModel.taggedPeople) { people in
                        ProfileCardView(viewModel: ProfileCardViewModel(taggedProfile: people)) { id in
                            onPressedProfile?(id)
                        }
                        .onTapGesture {
                            onPressedProfile?(people.id)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.top, 34)
        }
    }
}

#Preview {
    TaggedPeopleView(viewModel: TaggedPeopleViewModel(taggedPeople: []))
}


// MARK: - Components
extension TaggedPeopleView {
    private var customBackground: some View {
        Group {
            CustomShape2()
                .fill(themeManager.currentTheme.backgroundColor)
                .offset(y: 5)
            Image(themeManager.currentTheme.SheetIndicator)
        }
    }
}
