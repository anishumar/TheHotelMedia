//
//  NativeImageCropper.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import UIKit
import SwiftUI
import SwiftfulRouting

struct NativeImageCropper: UIViewControllerRepresentable {
    let image: UIImage
    let aspectRatio: CGFloat? // Optional aspect ratio (e.g., 9/16 for stories)
    var router: AnyRouter? // Router for navigation
    var onCropped: ((UIImage, StoryTaggingData?) -> Void)? // Updated to include tagging data
    var onCancel: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = NativeCropViewController(image: image, aspectRatio: aspectRatio, router: router)
        viewController.onCropped = { croppedImage, taggingData in
            onCropped?(croppedImage, taggingData)
        }
        viewController.onCancel = {
            onCancel?()
        }
        return UINavigationController(rootViewController: viewController)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

enum CropAspectRatio: String, CaseIterable {
    case original = "Original"
    case square = "Square"
    case story = "Story (9:16)"
    case landscape = "Landscape (16:9)"
    case portrait = "Portrait (4:5)"
    case freeform = "Freeform"
    
    var ratio: CGFloat? {
        switch self {
        case .original, .freeform:
            return nil
        case .square:
            return 1.0
        case .story:
            return 9.0 / 16.0
        case .landscape:
            return 16.0 / 9.0
        case .portrait:
            return 4.0 / 5.0
        }
    }
}

class NativeCropViewController: UIViewController {
    let image: UIImage
    let initialAspectRatio: CGFloat?
    var router: AnyRouter?
    var onCropped: ((UIImage, StoryTaggingData?) -> Void)?
    var onCancel: (() -> Void)?
    
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var overlayView: UIView!
    private var cropRect: CGRect = .zero
    private var currentAspectRatio: CropAspectRatio = .story
    private var rotationAngle: CGFloat = 0
    private var originalImage: UIImage
    
    // Toolbar views
    private var aspectRatioButton: UIButton!
    private var rotateButton: UIButton!
    private var resetButton: UIButton!
    private var zoomInButton: UIButton!
    private var zoomOutButton: UIButton!
    private var toolbarStackView: UIStackView!
    
    init(image: UIImage, aspectRatio: CGFloat?, router: AnyRouter? = nil) {
        self.image = image
        self.originalImage = image
        self.initialAspectRatio = aspectRatio
        self.router = router
        super.init(nibName: nil, bundle: nil)
        
        // Set initial aspect ratio based on parameter
        if let ratio = aspectRatio {
            if abs(ratio - 1.0) < 0.01 {
                currentAspectRatio = .square
            } else if abs(ratio - (9.0/16.0)) < 0.01 {
                currentAspectRatio = .story
            } else if abs(ratio - (16.0/9.0)) < 0.01 {
                currentAspectRatio = .landscape
            } else if abs(ratio - (4.0/5.0)) < 0.01 {
                currentAspectRatio = .portrait
            } else {
                currentAspectRatio = .freeform
            }
        } else {
            currentAspectRatio = .freeform
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCropRect()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup scroll view
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Setup image view
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        // Setup overlay view (crop frame)
        overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.isUserInteractionEnabled = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        // Create mask layer for crop area
        let maskLayer = CAShapeLayer()
        overlayView.layer.mask = maskLayer
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            
            overlayView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
        
        // Setup toolbar
        setupToolbar()
        
        // Update mask after layout
        DispatchQueue.main.async {
            self.updateCropRect()
            self.updateMask()
            self.centerImage()
        }
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        // Set navigation bar style
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationItem.title = "Crop Image"
    }
    
    private func setupToolbar() {
        // Create toolbar container
        let toolbarContainer = UIView()
        toolbarContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toolbarContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbarContainer)
        
        // Create stack view for buttons
        toolbarStackView = UIStackView()
        toolbarStackView.axis = .horizontal
        toolbarStackView.distribution = .equalSpacing
        toolbarStackView.alignment = .center
        toolbarStackView.spacing = 20
        toolbarStackView.translatesAutoresizingMaskIntoConstraints = false
        toolbarContainer.addSubview(toolbarStackView)
        
        // Aspect Ratio Button
        aspectRatioButton = createToolbarButton(
            title: currentAspectRatio.rawValue,
            action: #selector(aspectRatioTapped)
        )
        
        // Rotate Button
        rotateButton = createToolbarButton(
            icon: "rotate.right",
            action: #selector(rotateTapped)
        )
        
        // Reset Button
        resetButton = createToolbarButton(
            icon: "arrow.counterclockwise",
            action: #selector(resetTapped)
        )
        
        // Zoom In Button
        zoomInButton = createToolbarButton(
            icon: "plus.magnifyingglass",
            action: #selector(zoomInTapped)
        )
        
        // Zoom Out Button
        zoomOutButton = createToolbarButton(
            icon: "minus.magnifyingglass",
            action: #selector(zoomOutTapped)
        )
        
        toolbarStackView.addArrangedSubview(aspectRatioButton)
        toolbarStackView.addArrangedSubview(rotateButton)
        toolbarStackView.addArrangedSubview(resetButton)
        toolbarStackView.addArrangedSubview(zoomInButton)
        toolbarStackView.addArrangedSubview(zoomOutButton)
        
        NSLayoutConstraint.activate([
            toolbarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbarContainer.heightAnchor.constraint(equalToConstant: 80),
            
            toolbarStackView.centerXAnchor.constraint(equalTo: toolbarContainer.centerXAnchor),
            toolbarStackView.centerYAnchor.constraint(equalTo: toolbarContainer.centerYAnchor),
            toolbarStackView.leadingAnchor.constraint(greaterThanOrEqualTo: toolbarContainer.leadingAnchor, constant: 20),
            toolbarStackView.trailingAnchor.constraint(lessThanOrEqualTo: toolbarContainer.trailingAnchor, constant: -20)
        ])
    }
    
    private func createToolbarButton(title: String? = nil, icon: String? = nil, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 8
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        } else if let icon = icon {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
            button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func updateCropRect() {
        let viewWidth = scrollView.bounds.width
        let viewHeight = scrollView.bounds.height
        
        let cropWidth: CGFloat
        let cropHeight: CGFloat
        
        let aspectRatio = currentAspectRatio.ratio ?? initialAspectRatio
        
        if let aspectRatio = aspectRatio {
            // Use specified aspect ratio
            if viewWidth / viewHeight > aspectRatio {
                cropHeight = viewHeight
                cropWidth = cropHeight * aspectRatio
            } else {
                cropWidth = viewWidth
                cropHeight = cropWidth / aspectRatio
            }
        } else {
            // Freeform - use image aspect ratio or fit to screen
            let imageAspectRatio = image.size.width / image.size.height
            if viewWidth / viewHeight > imageAspectRatio {
                cropHeight = viewHeight
                cropWidth = cropHeight * imageAspectRatio
            } else {
                cropWidth = viewWidth
                cropHeight = cropWidth / imageAspectRatio
            }
        }
        
        cropRect = CGRect(
            x: (viewWidth - cropWidth) / 2,
            y: (viewHeight - cropHeight) / 2,
            width: cropWidth,
            height: cropHeight
        )
        
        // Update scroll view content size based on image
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let cropAspectRatio = cropWidth / cropHeight
        
        var contentWidth: CGFloat
        var contentHeight: CGFloat
        
        // Calculate content size to fill crop area while maintaining aspect ratio
        if imageAspectRatio > cropAspectRatio {
            // Image is wider - fit height to crop height
            contentHeight = cropHeight
            contentWidth = contentHeight * imageAspectRatio
        } else {
            // Image is taller - fit width to crop width
            contentWidth = cropWidth
            contentHeight = contentWidth / imageAspectRatio
        }
        
        // Ensure content is at least as large as crop area (so we can zoom out)
        contentWidth = max(contentWidth, cropWidth)
        contentHeight = max(contentHeight, cropHeight)
        
        scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
        
        // Set image view frame to match content size
        imageView.frame = CGRect(origin: .zero, size: CGSize(width: contentWidth, height: contentHeight))
        
        // Set initial zoom scale to fit the crop area
        let scaleX = cropWidth / contentWidth
        let scaleY = cropHeight / contentHeight
        let minScale = min(scaleX, scaleY)
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 4.0
        
        // Set initial zoom
        scrollView.zoomScale = minScale
        
        // Update content offset after a brief delay to ensure layout is complete
        DispatchQueue.main.async {
            self.scrollView.contentOffset = CGPoint(
                x: max(0, (self.scrollView.contentSize.width - self.scrollView.bounds.width) / 2),
                y: max(0, (self.scrollView.contentSize.height - self.scrollView.bounds.height) / 2)
            )
            self.centerImage()
        }
    }
    
    private func centerImage() {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame
        
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
    
    private func updateMask() {
        guard let maskLayer = overlayView.layer.mask as? CAShapeLayer else { return }
        
        let path = UIBezierPath(rect: overlayView.bounds)
        let cropPath = UIBezierPath(rect: cropRect)
        path.append(cropPath)
        path.usesEvenOddFillRule = true
        
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
    }
    
    @objc private func cancelTapped() {
        onCancel?()
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        // Get the original image (before any rotation transforms)
        let imageToCrop = originalImage
        
        // Get current state
        let zoomScale = scrollView.zoomScale
        let contentOffset = scrollView.contentOffset
        let imageViewFrame = imageView.frame
        
        // Crop rect is in scroll view's coordinate system
        let cropRectInScrollView = cropRect
        
        // Convert crop rect from scroll view coordinates to image view coordinates
        // The crop rect's origin is relative to the scroll view's bounds
        // We need to account for:
        // 1. Content offset (how much we've scrolled)
        // 2. Zoom scale (how much the image is zoomed)
        
        let cropXInImageView = (cropRectInScrollView.origin.x - contentOffset.x) / zoomScale
        let cropYInImageView = (cropRectInScrollView.origin.y - contentOffset.y) / zoomScale
        let cropWidthInImageView = cropRectInScrollView.width / zoomScale
        let cropHeightInImageView = cropRectInScrollView.height / zoomScale
        
        // Now convert from image view coordinates to actual image pixel coordinates
        let imageSize = imageToCrop.size
        let imageViewSize = imageViewFrame.size
        
        // Calculate scale factors
        let scaleX = imageSize.width / imageViewSize.width
        let scaleY = imageSize.height / imageViewSize.height
        
        // Convert to image coordinates
        var finalCropRect = CGRect(
            x: cropXInImageView * scaleX,
            y: cropYInImageView * scaleY,
            width: cropWidthInImageView * scaleX,
            height: cropHeightInImageView * scaleY
        )
        
        // Round to integer pixels
        finalCropRect = finalCropRect.integral
        
        // Clamp to image bounds
        finalCropRect.origin.x = max(0, min(finalCropRect.origin.x, imageSize.width))
        finalCropRect.origin.y = max(0, min(finalCropRect.origin.y, imageSize.height))
        finalCropRect.size.width = min(finalCropRect.width, imageSize.width - finalCropRect.origin.x)
        finalCropRect.size.height = min(finalCropRect.height, imageSize.height - finalCropRect.origin.y)
        
        // Ensure we have valid dimensions
        guard finalCropRect.width > 0 && finalCropRect.height > 0,
              finalCropRect.maxX <= imageSize.width,
              finalCropRect.maxY <= imageSize.height else {
            print("❌ Invalid crop rect: \(finalCropRect), image size: \(imageSize)")
            onCancel?()
            return
        }
        
        // Crop the image
        guard let cgImage = imageToCrop.cgImage?.cropping(to: finalCropRect) else {
            print("❌ Failed to crop image")
            onCancel?()
            return
        }
        
        // Create cropped image
        var finalImage = UIImage(cgImage: cgImage, scale: imageToCrop.scale, orientation: imageToCrop.imageOrientation)
        
        // Apply rotation if needed
        if rotationAngle != 0 {
            finalImage = rotateImage(finalImage, by: rotationAngle) ?? finalImage
        }
        
        print("✅ Crop successful: cropRect=\(finalCropRect), imageSize=\(imageSize), resultSize=\(finalImage.size)")
        
        // If router is provided, push edit view directly without dismissing first
        if let router = router {
            // Dismiss crop view without animation, then immediately push edit view
            dismiss(animated: false) {
                // Push edit story view immediately after dismissing crop view
                router.showScreen(.push) { editRouter in
                    EditStoryImageView(
                        viewModel: EditStoryImageViewModel(router: editRouter, image: finalImage),
                        returnedImage: { editedImage, taggingData in
                            // Call the onCropped callback with both image and tagging data
                            // This will be handled by MainTabBarViewModel to call postStory
                            self.onCropped?(editedImage, taggingData)
                        },
                        onDismissed: {
                            // Edit view dismissed
                        }
                    )
                    .environmentObject(ThemeManager.shared)
                    .environmentObject(LocalizationManager.shared)
                    .navigationBarBackButtonHidden()
                }
            }
        } else {
            // Fallback: call callback and dismiss
            onCropped?(finalImage, nil)
            dismiss(animated: true)
        }
    }
    
    // MARK: - Toolbar Actions
    
    @objc private func aspectRatioTapped() {
        let alert = UIAlertController(title: "Aspect Ratio", message: "Choose an aspect ratio", preferredStyle: .actionSheet)
        
        for ratio in CropAspectRatio.allCases {
            alert.addAction(UIAlertAction(title: ratio.rawValue, style: .default) { [weak self] _ in
                self?.currentAspectRatio = ratio
                self?.aspectRatioButton.setTitle(ratio.rawValue, for: .normal)
                self?.updateCropRect()
                self?.updateMask()
                self?.centerImage()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = aspectRatioButton
            popover.sourceRect = aspectRatioButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func rotateTapped() {
        rotationAngle += 90
        if rotationAngle >= 360 {
            rotationAngle = 0
        }
        
        // Rotate the displayed image
        UIView.animate(withDuration: 0.3) {
            self.imageView.transform = CGAffineTransform(rotationAngle: self.rotationAngle * .pi / 180)
        }
    }
    
    @objc private func resetTapped() {
        rotationAngle = 0
        imageView.transform = .identity
        imageView.image = originalImage
        
        // Reset zoom
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        
        // Reset to initial aspect ratio
        if let initialRatio = initialAspectRatio {
            if abs(initialRatio - 1.0) < 0.01 {
                currentAspectRatio = .square
            } else if abs(initialRatio - (9.0/16.0)) < 0.01 {
                currentAspectRatio = .story
            } else {
                currentAspectRatio = .freeform
            }
        } else {
            currentAspectRatio = .freeform
        }
        
        aspectRatioButton.setTitle(currentAspectRatio.rawValue, for: .normal)
        
        DispatchQueue.main.async {
            self.updateCropRect()
            self.updateMask()
            self.centerImage()
        }
    }
    
    @objc private func zoomInTapped() {
        let newZoom = min(scrollView.zoomScale * 1.5, scrollView.maximumZoomScale)
        scrollView.setZoomScale(newZoom, animated: true)
    }
    
    @objc private func zoomOutTapped() {
        let newZoom = max(scrollView.zoomScale / 1.5, scrollView.minimumZoomScale)
        scrollView.setZoomScale(newZoom, animated: true)
    }
    
    private func rotateImage(_ image: UIImage, by degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: radians)
        image.draw(in: CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        ))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension NativeCropViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
