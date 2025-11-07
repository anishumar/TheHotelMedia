//
//  ProfileCardViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 16/10/24.
//

import Foundation


class ProfileCardViewModel: ObservableObject {
    
    @Published var profile: SearchProfileData?
    @Published var taggedProfile: TaggedRef?
    @Published var name: String = ""
    @Published var businessType: String = ""
    @Published var businessTypeIcon: String = ""
    @Published var profilePic: String = ""
    @Published var username: String = ""
    @Published var addressString: String = ""
    @Published var accountType: String = ""
    @Published var role: String = ""
    
    init(profile: SearchProfileData? = nil, taggedProfile: TaggedRef? = nil) {
        self.profile = profile
        self.taggedProfile = taggedProfile
        
        if let profile, let role = profile.role {
            self.role = role
        } else if let taggedProfile, let role = taggedProfile.role {
            self.role = role
        }
    }
    
    
}
