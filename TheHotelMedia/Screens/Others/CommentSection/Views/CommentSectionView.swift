//
//  CommentSectionView.swift
//  HotelMedia
//
//  Created by MAC on 01/08/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct CommentSectionView: View {
    
    @Binding var showScreen: Bool
    @Binding var newComment: String
    @Binding var replyComment: Comment?
    @StateObject var viewModel: CommentSectionViewModel
    var isEmbedded: Bool = false
    var onPressedProfile: ((String) -> Void)? = nil
    var onPressedReply: ((Comment) -> Void)? = nil
    var onReportComment: ((String) -> Void)? = nil
    var onAddComment: (() -> Void)? = nil
    @StateObject var keyboardHeightHelper = KeyboardHeightHelper()
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            
            ZStack(alignment: .bottom) {
                ZStack(alignment: .top) {
                    if #available(iOS 16.4, *), !isEmbedded {
                        customBackground
                    } else {
                        Rectangle()
                            .fill(isEmbedded ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.darkGray_hmwhite)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    VStack(spacing: 16) {
                        if !isEmbedded {
                            header
                        }
                        if !viewModel.comments.isEmpty {
                            if isEmbedded {
                                allCommentsList
                                    .sheet(isPresented: $viewModel.showReportScreen, content: {
                                        ReportView(viewModel: ReportViewModel(reportID: viewModel.selectedCommentID, reportType: "comment", onReport: { message in
                                            //                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                                            //                                        ErrorModalManager.showErrorModal(router: viewModel.router, errorText: message)
                                            //                                    }
                                            viewModel.reportMessage = message
                                            withAnimation(.easeInOut(duration: 0.8)) {
                                                viewModel.showReportMessage = true
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                withAnimation(.easeInOut) {
                                                    viewModel.showReportMessage = false
                                                }
                                            }
                                            onReportComment?(message)
                                            print(message)
                                        }))
                                        .environmentObject(themeManager)
                                        .presentationDragIndicator(.hidden)
                                        .presentationDetents([.fraction(Constants.getReportSheetHeight())])
                                    })
                            } else {
                                mainSection
                                    .sheet(isPresented: $viewModel.showReportScreen, content: {
                                        ReportView(viewModel: ReportViewModel(reportID: viewModel.selectedCommentID, reportType: "comment", onReport: { message in
                                            //                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                                            //                                        ErrorModalManager.showErrorModal(router: viewModel.router, errorText: message)
                                            //                                    }
                                            viewModel.reportMessage = message
                                            withAnimation(.easeInOut(duration: 0.8)) {
                                                viewModel.showReportMessage = true
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                withAnimation(.easeInOut) {
                                                    viewModel.showReportMessage = false
                                                }
                                            }
                                            print(message)
                                        }))
                                        .environmentObject(themeManager)
                                        .presentationDragIndicator(.hidden)
                                        .presentationDetents([.fraction(Constants.getReportSheetHeight())])
                                    })
                            }
                            
                        } else {
                            EmptyScreenView(image: "NoComments", title: "no_comments_yet".localized(localizationManager.language), color: isEmbedded ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.darkGray_hmwhite)
                                .opacity(viewModel.showLoadingIndicator ? 0.0 : 1.0)
                        }
                        
                    }
                    .padding(.top, isEmbedded ? 8 : 34)
                    .padding(.horizontal, viewModel.comments.isEmpty || isEmbedded ? 0 : 16)
                    .overlay {
                        CustomProgressView(showIndicator: $viewModel.showLoadingIndicator, backgroundColor: .black.opacity(0.001))
                    }
                    .overlay {
                        ZStack(alignment: .topTrailing) {
                            if viewModel.showCommentOptions {
                                themeManager.currentTheme.black05_white05
                                    .padding(.top, isEmbedded ? 0 : 5)
                                    .onTapGesture {
                                        viewModel.showCommentOptions.toggle()
                                    }
                                VStack(spacing: 6) {
                                    capsuleButtonView(title: "report".localized(localizationManager.language))
                                        .onTapGesture {
                                            viewModel.showReportScreen = true
                                            viewModel.showCommentOptions.toggle()
                                        }
                                    
                                    capsuleButtonView(title: "delete".localized(localizationManager.language))
                                        .onTapGesture {
                                            viewModel.deleteComment(commentID: viewModel.selectedCommentID)
                                            viewModel.showCommentOptions.toggle()
                                        }
                                }
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(themeManager.currentTheme.darkGray08_hmIndigo08)
                                )
                                .offset(x: -16, y: viewModel.selectedYOffset + 30)
                            }
                        }
                    }
                    .overlay {
                        if keyboardHeightHelper.keyboardHeight > 0 {
                            Rectangle()
                                .fill(.black.opacity(0.001))
                                .onTapGesture {
                                    viewModel.keyboardHeight = 0
                                    endEditing()
                                }
                        }
                    }
                }
                .coordinateSpace(name: "SheetSpace")
                if !isEmbedded {
                    bottomSection
                }
            }
                        
        }
        .overlay(alignment: .bottom, content: {
            if viewModel.showReportMessage {
                BottomAlert(message: viewModel.reportMessage)
                    .transition(.move(edge: .bottom))
            }
        })
        .onReceive(viewModel.$dismiss, perform: { newValue in
            if newValue {
                dismiss()
            }
        })
        .onChange(of: newComment) { newValue in
            if !newValue.isEmpty {
                viewModel.postComment(comment: newValue) {
                    onAddComment?()
                }
            }
        }
        .onChange(of: replyComment) { newValue in
            viewModel.replyingComment = newValue
        }
    }
}


// MARK: - Preview
struct CommentSectionView_Previews: PreviewProvider {
    static var previews: some View {
        CommentSectionView(showScreen: .constant(true), newComment: .constant(""), replyComment: .constant(nil), viewModel: CommentSectionViewModel(postID: "", totalComments: 0))
    }
}



// MARK: - Components

extension CommentSectionView {
    
    private var customBackground: some View {
        Group {
            CustomShape2()
                .fill(themeManager.currentTheme.darkGray_hmwhite)
                .offset(y: 5)
            Image(themeManager.currentTheme.SheetIndicator)
                .offset(y: 2)
        }
    }
    
    
    private func capsuleButtonView(title: String) -> some View {
        Text(title)
            .font(.custom(Constants.comicFont, size: 11))
            .foregroundColor(themeManager.currentTheme.label)
            .frame(width: 74, height: 26, alignment: .center)
            .background(
                ZStack {
                    Capsule()
                        .fill(themeManager.currentTheme.darkGray05_white)
                    Capsule()
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                }
            )
    }
    
    
    private var mainSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            allCommentsList
        }
        .clipped()
    }
    
    
    private var allCommentsList: some View {
        LazyVStack(spacing: 24) {
            ForEach(viewModel.comments) { comment in
                let index = viewModel.comments.firstIndex(where: {$0.id == comment.id })
                CommentView(viewModel: CommentViewModel(comment: comment)) {
                    viewModel.likeAComment(commentID: comment.id ?? "")
                } onPressedReply: {
                    if isEmbedded {
                        onPressedReply?(comment)
                    }
                    viewModel.replyingComment = comment
                    
                } onPressedEllipsis: {
                    if let index {
                        viewModel.selectedYOffset = viewModel.commentsYOffset[index]
                        viewModel.selectedCommentID = comment.id ?? ""
                        viewModel.showCommentOptions = true
                    }
                } onPressedReplyEllipsis: { offset, selectedCommentID in
                    viewModel.selectedYOffset = offset
                    viewModel.selectedCommentID = selectedCommentID
                    viewModel.showCommentOptions = true
                } onPressedProfile: { userID in
                    onPressedProfile?(userID)
                }
                .onAppear {
                    if let lastComment = viewModel.comments.last {
                        if lastComment.id == comment.id {
                            viewModel.pageNo += 1
                            viewModel.getComments()
                        }
                    }
                }
                .overlay(
                    GeometryReader { geo in
                        Color.black.opacity(0.0001)
                            .preference(key: VisibleRectanglePreferenceKey.self, value: geo.frame(in: .named("SheetSpace")))
                            .allowsHitTesting(false)
                    }
                )
                .onPreferenceChange(VisibleRectanglePreferenceKey.self) { frame in
                    if let index {
                        viewModel.commentsYOffset[index] = frame.minY
                    }
                }
            }
            Rectangle()
                .fill(isEmbedded ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.darkGray_hmwhite)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
        }
        .id(viewModel.refreshData)
    }
    
    
    private var header: some View {
        Group {
            // header
            Text(viewModel.totalComments > 0 ? "\(viewModel.totalComments) \("comments".localized(localizationManager.language))" : "no_comments".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.label)
            
            // divider
            Rectangle()
                .fill(themeManager.currentTheme.white02_darkGray02)
                .frame(height: 1)
        }
    }
    
    
    private var bottomSection: some View {
//        ZStack {
//            
//        }
//        .frame(maxHeight: .infinity, alignment: .bottom)
        VStack(spacing: 2) {
            if let replyingName = viewModel.replyingName,
               let replyProfilePic = viewModel.replyingProfilePic {
                HStack {
                    WebImage(url: URL(string: replyProfilePic), content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                            .padding(.leading, 16)
                            .padding(.trailing, 10)
                    }, placeholder: {
                        Image("NoProfilePic")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                            .padding(.leading, 16)
                            .padding(.trailing, 10)
                    })
                    
                    Text("Replying to \(replyingName)")
                        .lineLimit(1)
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "xmark")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .onTapGesture {
                            viewModel.replyingComment = nil
                        }
                }
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(themeManager.currentTheme.mediumGray_hmIndigo)
                )
                .padding(.horizontal, 16)
            }
            bottomMainPart(height: 44)
                .padding(.bottom, 12)
                .padding(.horizontal, 16)
                .background(themeManager.currentTheme.darkGray_white)
        }
        .offset(y: viewModel.keyboardHeight)
        .onReceive(keyboardHeightHelper.$keyboardHeight) { height in
            viewModel.keyboardHeight = -height
        }
//        .animation(.linear(duration: 0.1), value: keyboardHeightHelper.keyboardHeight)

    }
    
    
    private func bottomMainPart(height: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 14) {
            commentField
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(themeManager.currentTheme.darkGray_white)
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(lineWidth: 1)
                            .fill(.hmIndigo.opacity(0.7))
                    }
                )
            sendButton(height: height)
            
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 8)
        
        
    }
    
    
    private var commentField: some View {
        TextField(
            "Comment Field",
            text: $viewModel.commentFieldText,
            prompt: Text("add_comment".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08),
            axis: .vertical
        )
        .lineLimit(4)
        .onSubmit {
            viewModel.commentFieldText.append("\n")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        
    }
    
    
    private var commentTextView: some View {
        HStack {
            Text(viewModel.commentFieldText.isEmpty ? "add_comment".localized(localizationManager.language).capitalized : viewModel.commentFieldText)
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundColor(.white.opacity(0.7))
                
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
        .onTapGesture {
        }
    }
    
    
    private var emojiButton: some View {
        Button(action: {
            
        }, label: {
            Image("Smily")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.white.opacity(0.7))
                .scaledToFit()
                .frame(width: 25, height: 25)
                .padding(.trailing, 16)
        })
    }
    
    
    private func sendButton(height: CGFloat) -> some View {
        Button(action: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                viewModel.postComment()
                viewModel.keyboardHeight = 0
                endEditing()
            }
        }, label: {
            Image(themeManager.currentTheme.AddComment)
                .resizable()
                .scaledToFit()
                .frame(height: height)
        })
    }
}
