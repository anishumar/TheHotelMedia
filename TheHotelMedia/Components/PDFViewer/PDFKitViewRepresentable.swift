//
//  PDFKitViewRepresentable.swift
//  TheHotelMedia
//
//  Created by MAC on 28/11/24.
//

import SwiftUI
import PDFKit

struct PDFKitViewRepresentable: UIViewRepresentable {
    
    @Binding var url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update the document when the URL changes
        pdfView.document = PDFDocument(url: self.url)
    }
}


struct PDFKitViewFromData: UIViewRepresentable {
    @Binding var pdfData: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        }
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update the PDF if needed
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        }
    }
}

