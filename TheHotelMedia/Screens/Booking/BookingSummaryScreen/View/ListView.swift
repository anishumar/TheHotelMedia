//
//  ListView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/03/25.
//

import SwiftUI

struct ListView: View {
    
    @Binding var posts: [PostData]
    
    var body: some View {
        List(posts) { post in
            Text("hello")
        }
    }
}
