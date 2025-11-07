//
//  ReportView.swift
//  TheHotelMedia
//
//  Created by MAC on 04/12/24.
//

import SwiftUI

struct ReportView: View {
    
    @StateObject var viewModel: ReportViewModel
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .center, spacing: 35) {
            VStack(spacing: 20) {
                Capsule()
                    .fill(.hmIndigo)
                    .frame(width: 50, height: 4)
                Text("report".localized(localizationManager.language))
                    .withComicFont(16, color: themeManager.currentTheme.label)
            }
            
            VStack(spacing: 10) {
                
                
                if viewModel.reportType == "post" {
                    Text("why_are_you_reporting_this_post".localized(localizationManager.language))
                        .font(.custom(Constants.comicBold, size: 16))
                        .foregroundColor(themeManager.currentTheme.label)
                } else if viewModel.reportType == "user" {
                    Text("why_are_you_reporting_this_user".localized(localizationManager.language))
                        .font(.custom(Constants.comicBold, size: 16))
                        .foregroundColor(themeManager.currentTheme.label)
                } else {
                    Text("why_are_you_reporting_this_comment".localized(localizationManager.language))
                        .font(.custom(Constants.comicBold, size: 16))
                        .foregroundColor(themeManager.currentTheme.label)
                }
                
                Text("Your report is anonymous. If someone is in immediate danger, call the local emergency services – don't wait.".localized(localizationManager.language))
                    .withComicFont(12, color: themeManager.currentTheme.white06_darkGray06)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if viewModel.reportType == "post" {
                        ForEach(viewModel.postReasonList, id: \.self) { reason in
                            Text(reason)
                                .withComicFont(14, color: themeManager.currentTheme.label)
                                .onTapGesture {
                                    viewModel.reportPost(id: viewModel.reportID, reason: reason)
                                }
                        }
                    } else if viewModel.reportType == "user" {
                        ForEach(viewModel.userReasonList, id: \.self) { reason in
                            Text(reason)
                                .withComicFont(14, color: themeManager.currentTheme.label)
                                .onTapGesture {
                                    viewModel.reportUser(id: viewModel.reportID, reason: reason)
                                }
                        }
                    } else {
                        ForEach(viewModel.commentReasons, id: \.self) { reason in
                            Text(reason)
                                .withComicFont(14, color: themeManager.currentTheme.label)
                                .onTapGesture {
                                    viewModel.reportComment(id: viewModel.reportID, reason: reason)
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.darkGray_white.ignoresSafeArea())
        .onReceive(viewModel.$dismiss, perform: { newValue  in
            if newValue {
                dismiss()
            }
        })
    }
}

#Preview {
    ReportView(viewModel: ReportViewModel(reportID: "", reportType: "post"))
}
