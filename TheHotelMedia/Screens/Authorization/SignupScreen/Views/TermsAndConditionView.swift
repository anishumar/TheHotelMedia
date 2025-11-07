//
//  TermsAndConditionView.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import SwiftUI
import ActivityIndicatorView
import UniformTypeIdentifiers

struct TermsAndConditionView: View {
    
    @StateObject var viewModel: TermsAndConditionViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("isIndividual") var isIndividual: Bool = true
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    @State private var termsText: String = ""
    @State private var isExpanded: Bool = false
    @State private var attributedText = AttributedString()
    
    var body: some View {
        ZStack {
            BackgroundImageView()
            
            VStack(spacing: 30) {
                Image("Logo")
                    .resizable()
                    .frame(width: 92, height: 92)
                    .padding(.top, 20)
                
                VStack(alignment: .leading) {
                    Text("terms_and_conditions".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 20))
                        .foregroundStyle(themeManager.currentTheme.label)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            Text(attributedText)
                                .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                                .onOpenURL { url in
                                    handleCustomURL(url: url)
                                }

                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: viewModel.termsAndConditionsAgreed ? "checkmark.square.fill" : "square")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(.hmIndigo)
                                    .frame(width: 24, height: 24)
                                    .background(.black.opacity(0.001))
                                    .onTapGesture {
                                        viewModel.termsAndConditionsAgreed.toggle()
                                    }
                                
                                Text("i_have_read_and_agree_to_the_terms_and_conditions".localized(localizationManager.language))
                                    .font(.custom(Constants.rubikLight, size: 16))
                                    .foregroundStyle(themeManager.currentTheme.label)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom)
                        }
                        
                    }
                    .clipped()
                    
                    bottomButtonSection
                }
                .padding(.horizontal, 16)
            }
        }
//        .preferredColorScheme(.dark)
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .onAppear {
            loadAndParseTextFile()
        }
        .onOpenURL { url in
            switch url.scheme {
            case "readmore":
                isExpanded.toggle()
                loadAndParseTextFile()
            default:
                break
            }
        }
    }
}


// MARK: - Preview

struct TermsAndConditionView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        TermsAndConditionView(viewModel: TermsAndConditionViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Functions
extension TermsAndConditionView {
    
    
    private func loadAndParseTextFile() {
        
        var fileName: String = "terms"
        
        if localizationManager.language == .gujarati {
            fileName = "terms_gu"
        } else if localizationManager.language == .marathi {
            fileName = "terms_mr"
        } else if localizationManager.language == .hindi {
            fileName = "terms_hi"
        } else if localizationManager.language == .kannada {
            fileName = "terms_kn"
        } else if localizationManager.language == .telugu {
            fileName = "terms_te"
        }
        
        guard let path = Bundle.main.path(forResource: fileName, ofType: "txt"),
              let content = try? String(contentsOfFile: path) else {
            print("Failed to load terms.txt")
            return
        }
        attributedText = getAttributedDescription(from: content, isExpanded: isExpanded)
    }
    
    
    private func getAttributedDescription(from fullText: String, isExpanded: Bool) -> AttributedString {
        var finalAttributedString = AttributedString()
        
        // Determine the text length based on `isExpanded`
        let displayText = isExpanded ? fullText : String(fullText.prefix(1500))

        let lines = displayText.components(separatedBy: "\n")
        for line in lines {
            var attributedLine = AttributedString(line)
            
            // Apply default font and color for normal text
            attributedLine.foregroundColor = themeManager.currentTheme.white06_darkGray06
            attributedLine.font = .custom(Constants.comicFont, size: 14)

            // Bold Headings (lines starting with ##)
            if line.starts(with: "##") {
                attributedLine = AttributedString(line.replacingOccurrences(of: "##", with: "").trimmingCharacters(in: .whitespaces))
                attributedLine.foregroundColor = themeManager.currentTheme.label
                attributedLine.font = .custom(Constants.comicFont, size: 14).bold()
            } else {
                // Detect URLs, Emails, and Phone Numbers and apply them
                attributedLine = detectLinks(in: line)
            }

            finalAttributedString.append(attributedLine)
            finalAttributedString.append(AttributedString("\n")) // Add new line
        }

        // Add "Read More" or "Read Less" at the end
        let readMoreOrLessText = isExpanded ? "...Read less" : "...Read more"
        var readMoreAttributedString = AttributedString(readMoreOrLessText)
        readMoreAttributedString.foregroundColor = .hmIndigo
        readMoreAttributedString.font = .custom(Constants.comicFont, size: 14).bold()
        readMoreAttributedString.link = URL(string: "readmore://") // Add tappable link

        finalAttributedString.append(readMoreAttributedString)

        return finalAttributedString
    }



    private func detectLinks(in text: String) -> AttributedString {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var attributedString = AttributedString(trimmedText)

        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        if let detector = try? NSDataDetector(types: types.rawValue) {
            let nsText = trimmedText as NSString
            let matches = detector.matches(in: trimmedText, options: [], range: NSRange(location: 0, length: nsText.length))

            for match in matches {
                if let range = Range(match.range, in: trimmedText) {
                    let matchedText = String(trimmedText[range])
                    if let attributedRange = attributedString.range(of: trimmedText[range]) {
                        // Handle Links (URLs)
                        if match.resultType == .link, let url = URL(string: matchedText) {
                            attributedString[attributedRange].link = url
                            attributedString[attributedRange].foregroundColor = .hmIndigo.opacity(0.7)
                            attributedString[attributedRange].font = .custom(Constants.comicFont, size: 14)
                        }
                        // Handle Phone Numbers
                        else if match.resultType == .phoneNumber {
                            let phoneNumber = matchedText
                            attributedString[attributedRange].link = URL(string: "tel://\(phoneNumber)")
                            attributedString[attributedRange].foregroundColor = .hmIndigo.opacity(0.7)
                            attributedString[attributedRange].font = .custom(Constants.comicFont, size: 14)
                        }
                        // Handle Emails
                        else if matchedText.contains("@") {
                            attributedString[attributedRange].link = URL(string: "mailto://\(matchedText)")
                            attributedString[attributedRange].foregroundColor = .hmIndigo.opacity(0.7)
                            attributedString[attributedRange].font = .custom(Constants.comicFont, size: 14)
                        }
                    }
                }
            }
        }

        return attributedString
    }

    
    
    private func handleCustomURL(url: URL) {
        if url.scheme == "tel" {
            // Handle phone number
            let phoneNumber = url.host ?? ""
            print("Dialing phone number: \(phoneNumber)")
            if let dialURL = URL(string: "tel://\(phoneNumber)") {
                UIApplication.shared.open(dialURL)
            }
        } else if url.scheme == "sendMail" {
            // Handle email
            let email = "contact@thehotelmedia.com"
            
            // Define the subject and body for the email
            let subject = "Hello"
            let body = "This is a test email."
            
            // URL encode the subject and body to make sure special characters are handled properly
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            // Construct the mailto URL
            let mailURLString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"
            
            if let mailURL = URL(string: mailURLString) {
                if UIApplication.shared.canOpenURL(mailURL) {
                    UIApplication.shared.open(mailURL, options: [:], completionHandler: nil)
                }
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            // Open web URL
            UIApplication.shared.open(url)
        } else {
            print("Custom action for URL: \(url)")
        }
    }
}


// MARK: - Components

extension TermsAndConditionView {
    
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
                    .opacity(viewModel.termsAndConditionsAgreed ? 1 : 0.6)
                    .onTapGesture {
                        if viewModel.termsAndConditionsAgreed {
                            viewModel.acceptTerms()
                        }
                    }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}
