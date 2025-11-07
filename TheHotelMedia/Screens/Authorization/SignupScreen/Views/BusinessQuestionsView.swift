//
//  BusinessQuestionsView.swift
//  HotelMedia
//
//  Created by MAC on 23/08/24.
//

import SwiftUI
import ActivityIndicatorView

struct BusinessQuestionsView: View {
    
    @StateObject var viewModel: BusinessQuestionsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 37) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("business_related_questions".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 20))
                        .foregroundColor(themeManager.currentTheme.label)
                    
                    VStack (alignment: .leading, spacing: 26){
                        
                        ForEach(viewModel.questionArray) { model in
                            DropDownMenuView(
                                viewModel: DropDownMenuViewModel(model: model)) { selectedAnswer in
                                    let model = BusinessQuestionPost(questionID: model.id, answer: selectedAnswer)
                                    
                                    if let index = viewModel.answersArray.firstIndex(where: { answer in
                                        return answer.questionID == model.questionID
                                    }) {
                                        viewModel.answersArray.remove(at: index)
                                        viewModel.answersArray.insert(model, at: index)
                                    }
                                    
                                    print(viewModel.answersArray)
                                }
                                .zIndex((viewModel.counter - Double(viewModel.questionArray.firstIndex(where: {$0 == model})!)))
                        }
                        if !viewModel.questionArray.isEmpty {
                            bottomButtonSection
                                .zIndex(Double(-viewModel.answersArray.count - 1))
                        }
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 12)
            .padding(.bottom, 30)
        }
        .clipped()
        .background(
            BackgroundImageView()
        )
        .onAppear {
            viewModel.addSubscribers()
            
            if viewModel.dataArray.isEmpty && viewModel.questionArray.isEmpty && viewModel.answersArray.isEmpty {
                viewModel.getQuestions()
            }
        }
        .onDisappear {
            viewModel.dataArray.removeAll()
            viewModel.cancelSubscriptions()
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        
    }
}

// MARK: - Preview
struct BusinessQuestionsView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        BusinessQuestionsView(viewModel: BusinessQuestionsViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components
extension BusinessQuestionsView {
    
    private var bottomButtonSection: some View {
        ZStack {
            VStack {
                Button(action: {
                    viewModel.dismissScreen()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo04_hmIndigo08)
                            .frame(width: 48)
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .tint(.white)
                    }
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            
            VStack {
                CircleProgressButton(progress: .constant(100))
                    .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                    .onTapGesture {
                        if !viewModel.nextButtonDisabled {
                            viewModel.postAnswers()
                        } else {
                            viewModel.errorText = "please_select_an_answer_for_all_the_questions".localized(localizationManager.language)
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: viewModel.errorText)
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
}
