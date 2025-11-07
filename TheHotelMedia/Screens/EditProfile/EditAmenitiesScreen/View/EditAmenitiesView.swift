//
//  EditAmenitiesView.swift
//  HotelMedia
//
//  Created by MAC on 12/09/24.
//

import SwiftUI

struct EditAmenitiesView: View {
    
    @StateObject var viewModel: EditAmenitiesViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 26) {
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
                        }
                        .zIndex((viewModel.counter - Double(viewModel.questionArray.firstIndex(where: {$0 == model})!)))
                }
                Spacer(minLength: viewModel.spacing)
            }
            .padding(.top, 60)
            .padding(.horizontal, 12)
            
        }
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay(alignment: .top) {
            header
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .background(themeManager.currentTheme.backgroundColor)
        }
        .onAppear {
            viewModel.addSubscribers()
            viewModel.getQuestions()
        }
        .onDisappear {
            viewModel.cancelSubscriptions()
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}

// MARK: - Preview
struct EditAmenitiesView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditAmenitiesView(viewModel: EditAmenitiesViewModel(router: router, selectedAnswers: []))
            .environmentObject(LocalizationManager.shared)
    }
}



// MARK: - Components
extension EditAmenitiesView {
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    viewModel.dismissScreen()
                }
            
            Text("business_related_questions".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                viewModel.postAnswers()
            }, label: {
                Circle()
                    .fill(.hmIndigo.opacity(0.5))
                    .frame(width: 28)
                    .overlay(
                        Image("Tick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    )
            })
        }
        .padding(.top, 16)
    }
}
