//
//  MantisCropperView.swift
//  TheHotelMedia
//
//  Created by MAC on 17/10/24.
//

import UIKit
import SwiftUI
import Mantis


enum ImageCropperType {
    case normal
    case noRotaionDial
}

struct ImageCropper: UIViewControllerRepresentable {
    @Binding var image: UIImage
    @Binding var cropShapeType: Mantis.CropShapeType
    @Binding var presetFixedRatioType: Mantis.PresetFixedRatioType
    @Binding var type: ImageCropperType
    @Binding var transformation: Transformation?
    var onCropped: ((UIImage) -> Void)?
    
    @Environment(\.presentationMode) var presentationMode
    
    class Coordinator: CropViewControllerDelegate {
        func cropViewControllerDidFailToCrop(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            
        }
        
        func cropViewControllerDidBeginResize(_ cropViewController: Mantis.CropViewController) {
            
        }
        
        func cropViewControllerDidEndResize(_ cropViewController: Mantis.CropViewController, original: UIImage, cropInfo: Mantis.CropInfo) {
            
        }
        
        var parent: ImageCropper
        
        init(_ parent: ImageCropper) {
            self.parent = parent
        }
        
        func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
//            parent.image = cropped
            parent.transformation = transformation
            parent.onCropped?(cropped)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        switch type {
        case .normal:
            return makeNormalImageCropper(context: context)
        case .noRotaionDial:
            return makeImageCropperHiddingRotationDial(context: context)
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

extension ImageCropper {
    func makeNormalImageCropper(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.cropShapeType = cropShapeType
        config.presetFixedRatioType = presetFixedRatioType
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }
    
    func makeImageCropperHiddingRotationDial(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.showRotationDial = false
        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.delegate = context.coordinator

        return cropViewController
    }
    
//    func makeImageCropperWithoutAttachedToolbar(context: Context) -> UIViewController {
//        var config = Mantis.Config()
//        config.showAttachedCropToolbar = false
//        config.cropToolbarConfig.toolbarButtonOptions = [.all]
//        let cropViewController: CustomViewController = Mantis.cropViewController(image: image!, config: config)
//        cropViewController.delegate = context.coordinator
//
//        return UINavigationController(rootViewController: cropViewController)
//    }
}
