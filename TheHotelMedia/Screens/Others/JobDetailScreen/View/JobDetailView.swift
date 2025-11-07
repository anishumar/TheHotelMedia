//
//  JobDetailView.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import SwiftUI

struct JobDetailView: View {
    
    @StateObject var viewModel: JobDetailViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 12) {
            CustomHeaderView(title: "Job Detail".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            .background(themeManager.currentTheme.backgroundColor)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 25) {
                    singleDetailView(title: "Job Title".localized(localizationManager.language), detail: viewModel.jobdata?.title ?? "-----")
                    singleDetailView(title: "Designation".localized(localizationManager.language), detail: viewModel.jobdata?.designation ?? "-----")
                    singleDetailView(title: "Job Type".localized(localizationManager.language), detail: viewModel.jobdata?.jobType ?? "-----")
                    singleDetailView(title: "Experience".localized(localizationManager.language), detail: viewModel.jobdata?.experience ?? "-----")
                    singleDetailView(title: "Salary Offer".localized(localizationManager.language), detail: viewModel.jobdata?.salary ?? "-----")
                    singleDetailView(title: "Number of Vacancies".localized(localizationManager.language), detail: viewModel.jobdata?.numberOfVacancies ?? "-----")
                    singleDetailView(title: "Joining Date".localized(localizationManager.language), detail: DateManager.formatDate(from: viewModel.jobdata?.joiningDate ?? "-----"))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Job Description".localized(localizationManager.language))
                            .font(.custom(Constants.comicBold, size: 14))
                            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        
                        Text(viewModel.jobdata?.description ?? "")
                            .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(themeManager.currentTheme.backgroundColor)
        .overlay(alignment: .bottom) {
            Button {
                viewModel.applyForJob()
            } label: {
                Text("Apply".localized(localizationManager.language))
                    .withComicFont(16, color: .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}


// MARK: - Components
extension JobDetailView {
    private func singleDetailView(title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(.custom(Constants.comicBold, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            
            Spacer()
            
            Text(detail)
                .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
        }
    }
}

