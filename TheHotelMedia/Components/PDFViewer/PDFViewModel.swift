//
//  PDFViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 16/01/25.
//

import Foundation


class PDFViewModel: ObservableObject {
    
    @Published var downloadingMedia: Bool = false
    @Published var shareURL: URL = URL(string: "https://thehotelmedia.com/post")!
    @Published var isSharePresented: Bool = false
    
    let downloadManager = FileDownloadManager.shared
    
    func downloadPDF(url: URL, pdfTitle: String = "") {
        downloadingMedia = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "THM-PDF-\(dateString).\(url.pathExtension)"
        downloadManager.downloadFile(from: url.absoluteString, fileName: pdfTitle.isEmpty ? fileName : pdfTitle) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let savedUrl):
                DispatchQueue.main.async {
                    self.shareURL = savedUrl
                    self.isSharePresented.toggle()
                    self.downloadingMedia = false
                }
                
            case .failure( _):
                DispatchQueue.main.async {
                    self.downloadingMedia = false
                }
            }
        }
    }
}
