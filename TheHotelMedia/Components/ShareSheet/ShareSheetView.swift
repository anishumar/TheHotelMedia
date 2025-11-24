//
//  ShareSheetView.swift
//  TheHotelMedia
//
//  Created by MAC on 24/11/25.
//

import SwiftUI

struct ShareSheetView: View {
    let shareURL: URL
    let onShareAsStory: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ActivityViewController(
            activityItems: [shareURL.absoluteString],
            applicationActivities: [createShareAsStoryActivity()]
        )
    }
    
    private func createShareAsStoryActivity() -> ShareAsStoryActivity {
        let activity = ShareAsStoryActivity()
        activity.onShareAsStory = {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onShareAsStory()
            }
        }
        return activity
    }
}

