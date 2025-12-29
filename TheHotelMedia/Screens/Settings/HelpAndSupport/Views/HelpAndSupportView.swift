//
//  HelpAndSupportView.swift
//  HotelMedia
//
//  Created by MAC on 19/08/24.
//

import SwiftUI

enum HelpandSupportTab: String {
    case faqs
    case contactUs
}

enum QuestionFilter: String {
    case general
    case account
    case privacy
    case content
}


struct HelpAndSupportView: View {
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject var viewModel: HelpAndSupportViewModel
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    
    @AppStorage("name") var name: String = ""
    @AppStorage("emailID") var emailID: String = ""
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            CustomHeaderView(title: "help_and_support".localized(localizationManager.language)) {
                viewModel.dismissScreen()
            }
            VStack(spacing: 12) {
                tabButtonSection
                VStack {
                    if viewModel.currentTab == .faqs {
                        faqTab
                    } else {
                        contactUsTab
                    }
                }
            }
            
            
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        
    }
}

// MARK: - Preview
struct HelpAndSupportView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        HelpAndSupportView(viewModel: HelpAndSupportViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension HelpAndSupportView {
    private func tabButton(type: HelpandSupportTab) -> some View {
        HStack {
            Text(type.rawValue.localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 13.8))
                .foregroundColor(viewModel.currentTab == type ? themeManager.currentTheme.label : themeManager.currentTheme.white06_darkGray06)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.001))
        .onTapGesture {
            viewModel.currentTab = type
        }
    }
    
    
    private var tabButtonSection: some View {
        VStack(spacing: 6) {
            HStack {
                tabButton(type: .faqs)
                tabButton(type: .contactUs)
            }
            HStack {
                Rectangle()
                    .fill(themeManager.currentTheme.label)
                    .frame(width: (UIScreen.main.bounds.width / 2) - 16, height: 1.5)
                    .animation(.smooth, value: viewModel.currentTab)
            }
            .frame(maxWidth: .infinity, alignment: viewModel.currentTab == .faqs ? .leading : .trailing)
        }
        .padding(.horizontal, 2)
    }
    
    
    private func filterButton(type: QuestionFilter, width: CGFloat) -> some View {
        Text(type.rawValue.localized(localizationManager.language).capitalized)
            .font(.custom(Constants.comicFont, size: 12))
            .foregroundColor(viewModel.currentFilter == type ? .white : themeManager.currentTheme.white06_darkGray06)
            .frame(width: width, height: 32)
            .background(
                CapsuleBackground(
                    height: 32,
                    borderWidth: viewModel.currentFilter == type ? 0.75 : 1.2,
                    borderColor: viewModel.currentFilter == type ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.darkThemeActive ? .hmDarkerGray : .clear,
                    backgroundColor: viewModel.currentFilter == type ? themeManager.currentTheme.hmIndigo07_hmIndigo : themeManager.currentTheme.darkGray06_mediumGray03
                )
            )
            .onTapGesture {
                viewModel.currentFilter = type
            }
        
    }
    
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17))
                .fontWeight(.semibold)
            
            TextField(
                "",
                text: $viewModel.searchFieldText,
                prompt: Text("search".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            )
            .foregroundStyle(themeManager.currentTheme.label)
            .frame(maxWidth: .infinity)
            
        }
        .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
        .frame(height: 46)
        .padding(.horizontal, 16)
        .background(
            CapsuleBackground(backgroundColor: themeManager.currentTheme.darkGray05_white)
        )
    }
    
    
    private func questionView(question: QuestionAnswer) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(question.question ?? "")
                    .font(.custom(Constants.comicFont, size: 12))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.001))
                
                Image(themeManager.currentTheme.Chevron_right)
                    .rotationEffect(Angle(degrees: question.isExpanded == nil ? 90 : question.isExpanded == false ? 90 : 270))
                
            }
            
            
            
            if let isExpanded = question.isExpanded {
                if isExpanded {
                    Rectangle()
                        .fill(.hmDarkerGray)
                        .frame(height: question.isExpanded == nil ? 0 : question.isExpanded == true ? 1 : 0)
                    
                    Text(question.answer ?? "")
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.black.opacity(0.001))
                        .scaleEffect(y: question.isExpanded == nil ? 0 : question.isExpanded == true ? 1 : 0, anchor: .top)
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray05_white)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(themeManager.currentTheme.mediumGray_hmIndigo)
            }
        )
    }
    
    
    private var faqTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    let width = (UIScreen.main.bounds.width - 54) / 4
                    filterButton(type: .general, width: width)
                    filterButton(type: .account, width: width)
                    filterButton(type: .privacy, width: width)
                    filterButton(type: .content, width: width)
                }
                .frame(height: 34)
                
                searchField
                if viewModel.currentFilter == .general {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.generalQuestions) { question in
                            questionView(question: question)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        viewModel.toggleExpansion(for: question)
                                    }
                                }
                                .onAppear {
                                    if let lastQuestion = viewModel.generalQuestions.last {
                                        if lastQuestion.id == question.id {
                                            viewModel.generalPageNo += 1
                                            viewModel.getFaqs(type: .general, isPagination: true )
                                        }
                                    }
                                }
                        }
                    }
                } else if viewModel.currentFilter == .account {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.accountQuestions) { question in
                            questionView(question: question)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        viewModel.toggleExpansion(for: question)
                                    }
                                }
                                .onAppear {
                                    if let lastQuestion = viewModel.accountQuestions.last {
                                        if lastQuestion.id == question.id {
                                            viewModel.accountpageNo += 1
                                            viewModel.getFaqs(type: .account, isPagination: true )
                                        }
                                    }
                                }
                        }
                    }
                    
                } else if viewModel.currentFilter == .privacy {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.privacyQuestions) { question in
                            questionView(question: question)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        viewModel.toggleExpansion(for: question)
                                    }
                                }
                                .onAppear {
                                    if let lastQuestion = viewModel.privacyQuestions.last {
                                        if lastQuestion.id == question.id {
                                            viewModel.privacyPageNo += 1
                                            viewModel.getFaqs(type: .privacy, isPagination: true )
                                        }
                                    }
                                }
                                
                        }
                    }
                    
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.contentQuestions) { question in
                            questionView(question: question)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        viewModel.toggleExpansion(for: question)
                                    }
                                }
                                .onAppear {
                                    if let lastQuestion = viewModel.contentQuestions.last {
                                        if lastQuestion.id == question.id {
                                            viewModel.contentPageNo += 1
                                            viewModel.getFaqs(type: .content, isPagination: true )
                                        }
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    
    private var whatsappButton: some View {
        HStack(spacing: 10) {
            Image("Whatsapp")
                .resizable().renderingMode(.template)
                .font(.system(size: 22))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .padding(.leading, 10)
            Text("whatsapp".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.001))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 15)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray05_white)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            }
        )
        .padding(1)
    }
    
    
    private var nameView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("name".localized(localizationManager.language))
            
            HStack {
                if viewModel.enterFields {
                    Text(name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onAppear {
                            viewModel.nameFieldText = name
                        }
                } else {
                    TextField("", text: $viewModel.nameFieldText, prompt: Text("name".localized(localizationManager.language)).font(.custom(Constants.comicFont, size: 14)))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .textContentType(.name)
                }
                
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.darkGray05_white)
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                }
            )
            .padding(1)
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
    }
    
    
    private var emailView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("email".localized(localizationManager.language))
            
            HStack {
                if viewModel.enterFields {
                    Text(emailID)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.hmIndigo)
                        .onAppear {
                            viewModel.emailFieldText = emailID
                        }
                    
                } else {
                    TextField("", text: $viewModel.emailFieldText, prompt: Text("email".localized(localizationManager.language)).font(.custom(Constants.comicFont, size: 14)))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                }
                
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.darkGray05_white)
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                }
            )
            .padding(1)
        }
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
    }
    
    
    private var messageField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("message".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.descriptionFieldText)
                    .scrollContentBackground(.hidden)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                    .frame(height: 110)
                    .padding(10)
                    .background(themeManager.currentTheme.darkGray05_white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(style: .init(lineWidth: 1))
                            .foregroundStyle(viewModel.descriptionFieldText.isEmpty ? Color.hmDarkerGray : Color.hmIndigo)
                    )
                    .overlay(alignment: .topLeading, content: {
                        if viewModel.descriptionFieldText.isEmpty {
                            Text("message".localized(localizationManager.language))
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                                .offset(x: 16, y: 16)
                        }
                        
                    })
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(1)
    }
    
    
    private var contactUsTab: some View {
        VStack(spacing: 12) {
            whatsappButton
                .onTapGesture {
                    viewModel.openWhatsapp()
                }
            Text("or".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            nameView
            emailView
            messageField
            VStack {
                CircleProgressButton(progress: .constant(100), lineWidth: 3.5)
                    .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        viewModel.contactUs(name: viewModel.enterFields ? name : viewModel.nameFieldText, email: viewModel.enterFields ? emailID : viewModel.emailFieldText, message: viewModel.descriptionFieldText)
                    }
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    
    private var keyboardButtons: some View {
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
}
