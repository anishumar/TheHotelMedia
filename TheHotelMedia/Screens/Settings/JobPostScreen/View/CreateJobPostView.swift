//
//  CreateJobPostView.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import SwiftUI
import Lottie

struct CreateJobPostView: View {
    
    @StateObject var viewModel: CreateJobPostViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 12) {
            CustomHeaderView(title: "Post Job".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            .background(themeManager.currentTheme.backgroundColor)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    GrayTextField(textfieldText: $viewModel.titleFieldText, title: "Job Title".localized(localizationManager.language), placeholder: "Job Title".localized(localizationManager.language), leftIcon: "", textInputCapitalization: .characters, rightIcon: .constant(nil))
                    
                    DropDownMenuView2(viewModel: DropDownMenuViewModel2(model: viewModel.designationModel), selectedFontSize: 14, optionFontSize: 16, selectedColor: themeManager.currentTheme.white06_darkGray06) { designation in
                        viewModel.selectedDesignation = designation
                    }
                    .zIndex(5)
                    descriptionField
                    DropDownMenuView2(viewModel: DropDownMenuViewModel2(model: viewModel.jobTypeModel), selectedFontSize: 14, optionFontSize: 16, selectedColor: themeManager.currentTheme.white06_darkGray06) { jobType in
                        viewModel.selectedJobType = jobType
                    }
                    .zIndex(4)
                    DropDownMenuView2(viewModel: DropDownMenuViewModel2(model: viewModel.experienceModel), selectedFontSize: 14, optionFontSize: 16, selectedColor: themeManager.currentTheme.white06_darkGray06) { experience in
                        viewModel.selectedExperience = experience
                    }
                    .zIndex(3)
                    DropDownMenuView2(viewModel: DropDownMenuViewModel2(model: viewModel.salaryModel), selectedFontSize: 14, optionFontSize: 16, selectedColor: themeManager.currentTheme.white06_darkGray06, onSelected: { salary in
                        viewModel.selectedSalary = salary
                    }, isOpen: { isOpen in
                        
                    })
                    .zIndex(2)
                    DropDownMenuView2(viewModel: DropDownMenuViewModel2(model: viewModel.vacancyModel), selectedFontSize: 14, optionFontSize: 16, selectedColor: themeManager.currentTheme.white06_darkGray06, onSelected: { vacancy in
                        viewModel.selectedVacancy = vacancy
                    }, isOpen: { isOpen in
                        if isOpen {
                            let hiddenOptions = viewModel.vacancyModel.answer.count - 3
                            
                            if hiddenOptions > 0 {
                                viewModel.bottomSpacing = CGFloat(hiddenOptions) * 60
                            }
                            
                        } else {
                            viewModel.bottomSpacing = 0
                        }
                    })
                    .zIndex(1)
                    
                    joiningDateField
                    
                    Button {
                        viewModel.createJobPost()
                    } label: {
                        Text("Submit".localized(localizationManager.language))
                            .withComicFont(16, color: .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                            )
                    }
                    .padding(.bottom, 16 + viewModel.bottomSpacing)
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 20)
        .background(themeManager.currentTheme.backgroundColor)
        .overlay {
            ZStack {
                if viewModel.showJoiningDatePicker {
                    joiningPickerView
                        .transition(.push(from: .top))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.black.opacity(0.5).ignoresSafeArea()
                    .opacity(viewModel.showJoiningDatePicker ? 1.0 : 0.0)
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            viewModel.showJoiningDatePicker = true
                        }
                    }
            )
            
            
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay(content: {
            ZStack {
                if viewModel.isBookingSuccessful {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        LottieView(animation: .named("Animation-Uploaded"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                            .animationDidFinish { completed in
                                viewModel.isBookingSuccessful = false
                                viewModel.dismissScreen()
                            }
                            .scaleEffect(1.5)
                        Spacer()
                        Text(viewModel.successMessage)
                            .withComicFont(12, color: .white)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 8)
                    }
                    .frame(width: 240, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.hmDarkerGray.opacity(0.3))
                    )
                }
            }
        })
    }
}


// MARK: - Components
extension CreateJobPostView {
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Job Description".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.descriptionFieldText)
                    .scrollContentBackground(.hidden)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                    .frame(height: 120)
                    .padding(10)
                    .background(themeManager.currentTheme.darkGray05_white)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(style: .init(lineWidth: 1))
                            .fill(viewModel.descriptionFieldText.isEmpty ? .hmDarkerGray : .hmIndigo)
                    )
                    .overlay(alignment: .topLeading, content: {
                        if viewModel.descriptionFieldText.isEmpty {
                            Text("Job Description".localized(localizationManager.language))
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                                .offset(x: 16, y: 16)
                        }
                    })
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var doneButton: some View {
        HStack {
            
            Spacer()
            Button(action: {
                endEditing()
            }, label: {
                Text("done".localized(localizationManager.language))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                    
            })
        }
    }
    
    
    private var joiningDateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Joining Date".localized(localizationManager.language))
            HStack(spacing: 0) {
                Text(DateManager.convertDateToddMMMyyyyFormat(date: viewModel.selectedJoiningDate))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Image("CalendarIcon")
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            viewModel.showJoiningDatePicker = true
                        }
                    }
            }
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(
                ZStack {
                    CapsuleBackground(height: 46, borderColor: .hmDarkerGray, backgroundColor: themeManager.currentTheme.darkGray05_white)
                }
            )
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var joiningPickerView: some View {
        DatePicker(
            "",
            selection: $viewModel.selectedJoiningDate,
            in: viewModel.fromDateRange,
            displayedComponents: [
                .date
            ]
        )
        .datePickerStyle(.graphical)
        .padding()
        .padding(.top)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.currentTheme.darkGray_white)
        )
        .padding()
        .accentColor(.hmIndigo)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "xmark.circle.fill")
                .background(
                    Color.white
                        .frame(width: 14, height: 14)
                )
                .foregroundColor(.hmIndigo)
                .font(.title2)
                .clipShape(
                    Circle()
                )
                .onTapGesture {
                    withAnimation(.bouncy) {
                        viewModel.showJoiningDatePicker = false
                    }
                }
                .opacity(viewModel.showJoiningDatePicker ? 1.0 : 0.0)
                .offset(x: -25, y: 25)
        }
    }
}

