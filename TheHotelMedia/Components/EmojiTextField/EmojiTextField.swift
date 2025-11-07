//
//  EmojiTextField.swift
//  TheHotelMedia
//
//  Created by MAC on 03/01/25.
//
import SwiftUI

//struct CustomTextField: UIViewRepresentable {
//    @Binding var text: String
//    @Binding var focus: Bool // Binding to control focus state
//    var prompt: String
//    var promptFont: UIFont
//    var promptColor: UIColor
//    var useEmojiKeyboard: Bool
//    var onSubmit: (() -> Void)? = nil
//
//    func makeUIView(context: Context) -> EmojiTextView {
//        let textView = EmojiTextView()
//        textView.delegate = context.coordinator
//        textView.font = promptFont
//        textView.textColor = promptColor
//        textView.useEmojiKeyboard = useEmojiKeyboard
//        textView.text = text.isEmpty ? prompt : text
//        textView.textColor = text.isEmpty ? promptColor.withAlphaComponent(0.5) : promptColor
//        textView.backgroundColor = .clear
//        textView.isScrollEnabled = true
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        return textView
//    }
//
//    func updateUIView(_ uiView: EmojiTextView, context: Context) {
//        uiView.useEmojiKeyboard = useEmojiKeyboard
//        if text.isEmpty && !uiView.isFirstResponder {
//            uiView.text = prompt
//            uiView.textColor = promptColor.withAlphaComponent(0.5)
//        } else if uiView.text != text {
//            uiView.text = text
//            uiView.textColor = promptColor
//        }
//
//        // Handle focus activation
//        if focus {
//            uiView.becomeFirstResponder()
//        } else {
//            uiView.resignFirstResponder()
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, UITextViewDelegate {
//        var parent: CustomTextField
//
//        init(_ parent: CustomTextField) {
//            self.parent = parent
//        }
//
//        func textViewDidBeginEditing(_ textView: UITextView) {
//            if textView.text == parent.prompt {
//                textView.text = ""
//                textView.textColor = parent.promptColor
//            }
//        }
//
//        func textViewDidEndEditing(_ textView: UITextView) {
//            if textView.text.isEmpty {
//                textView.text = parent.prompt
//                textView.textColor = parent.promptColor.withAlphaComponent(0.5)
//            }
//        }
//
//        func textViewDidChange(_ textView: UITextView) {
//            parent.text = textView.text == parent.prompt ? "" : textView.text
//        }
//    }
//}
//
//class EmojiTextView: UITextView {
//    var useEmojiKeyboard: Bool = false
//
//    override var textInputMode: UITextInputMode? {
//        if useEmojiKeyboard {
//            return UITextInputMode.activeInputModes.first(where: { $0.primaryLanguage == "emoji" })
//        }
//        return super.textInputMode
//    }
//}


struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var focus: Bool
    var prompt: String
    var promptFont: UIFont
    var promptColor: UIColor
    var useEmojiKeyboard: Bool
    var onSubmit: (() -> Void)? = nil

    func makeUIView(context: Context) -> EmojiTextView {
        let textView = EmojiTextView()
        textView.delegate = context.coordinator
        textView.font = promptFont
        textView.textColor = promptColor
        textView.useEmojiKeyboard = useEmojiKeyboard
        textView.text = text.isEmpty ? prompt : text
        textView.textColor = text.isEmpty ? promptColor.withAlphaComponent(0.5) : promptColor
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        // Set height constraint to limit to 4 lines
        if let lineHeight = textView.font?.lineHeight {
            let maxHeight = lineHeight * 4
            textView.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight).isActive = true
        }

        return textView
    }

    func updateUIView(_ uiView: EmojiTextView, context: Context) {
        uiView.useEmojiKeyboard = useEmojiKeyboard
        if text.isEmpty && !uiView.isFirstResponder {
            uiView.text = prompt
            uiView.textColor = promptColor.withAlphaComponent(0.5)
        } else if uiView.text != text {
            uiView.text = text
            uiView.textColor = promptColor
        }

        if focus && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !focus && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }

        // Update scrolling behavior
        uiView.updateScrollEnabled()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.text == parent.prompt {
                textView.text = ""
                textView.textColor = parent.promptColor
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                parent.focus = true // Sync focus back to SwiftUI
            }
            
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.prompt
                textView.textColor = parent.promptColor.withAlphaComponent(0.5)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                parent.focus = false // Sync blur back to SwiftUI
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text == parent.prompt ? "" : textView.text
            (textView as? EmojiTextView)?.updateScrollEnabled()
        }
        
    }
}

class EmojiTextView: UITextView {
    var useEmojiKeyboard: Bool = false
    private let maxLines = 4

    override var textInputMode: UITextInputMode? {
        if useEmojiKeyboard {
            return UITextInputMode.activeInputModes.first(where: { $0.primaryLanguage == "emoji" })
        }
        return super.textInputMode
    }

    override var intrinsicContentSize: CGSize {
        let fittingSize = CGSize(width: frame.width, height: .greatestFiniteMagnitude)
        let calculatedSize = sizeThatFits(fittingSize)
        let maxHeight = (font?.lineHeight ?? 0) * CGFloat(maxLines)
        return CGSize(width: calculatedSize.width, height: min(calculatedSize.height, maxHeight))
    }

    func updateScrollEnabled() {
        guard let font = self.font else { return }
        let maxHeight = font.lineHeight * CGFloat(maxLines)
        self.isScrollEnabled = self.contentSize.height > maxHeight
    }
}
