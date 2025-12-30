//
//  CustomCameraView.swift
//  TheHotelMedia
//
//  Created by MAC on 29/01/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct CustomCameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onPhotoCaptured: ((UIImage) -> Void)?
    var onVideoCaptured: ((URL) -> Void)?
    var maxVideoDuration: TimeInterval = 180 // 3 minutes in seconds
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = CameraViewController()
        controller.coordinator = context.coordinator
        controller.maxVideoDuration = maxVideoDuration
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    class Coordinator: NSObject {
        var parent: CustomCameraView
        
        init(_ parent: CustomCameraView) {
            self.parent = parent
        }
        
        func photoCaptured(_ image: UIImage) {
            parent.onPhotoCaptured?(image)
            parent.isPresented = false
        }
        
        func videoCaptured(_ url: URL) {
            parent.onVideoCaptured?(url)
            parent.isPresented = false
        }
        
        func cancelled() {
            parent.isPresented = false
        }
    }
}

class CameraViewController: UIViewController {
    var coordinator: CustomCameraView.Coordinator?
    var maxVideoDuration: TimeInterval = 180
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isRecording = false
    private var recordingStartTime: Date?
    private var isLongPressActive = false // Track if long press gesture is active
    
    private var shutterButton: UIButton!
    private var flipButton: UIButton!
    private var closeButton: UIButton!
    private var timerLabel: UILabel!
    private var recordingIndicator: UIView!
    
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var currentVideoDevice: AVCaptureDevice?
    private var initialZoomFactor: CGFloat = 1.0
    private var initialPanY: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = .high
        
        // Setup camera input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        currentVideoDevice = videoDevice
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // Setup audio input for video recording
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // Setup photo output
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        // Setup video output
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            // Set max duration
            let maxDuration = CMTime(seconds: maxVideoDuration, preferredTimescale: 600)
            videoOutput.maxRecordedDuration = maxDuration
            captureSession.addOutput(videoOutput)
        }
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.frame = CGRect(x: 20, y: 50, width: 40, height: 40)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // Flip camera button
        flipButton = UIButton(type: .system)
        flipButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        flipButton.tintColor = .white
        flipButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        flipButton.layer.cornerRadius = 20
        flipButton.frame = CGRect(x: view.bounds.width - 60, y: 50, width: 40, height: 40)
        flipButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
        view.addSubview(flipButton)
        
        // Timer label
        timerLabel = UILabel()
        timerLabel.text = "00:00"
        timerLabel.textColor = .white
        timerLabel.font = .systemFont(ofSize: 24, weight: .bold)
        timerLabel.textAlignment = .center
        timerLabel.isHidden = true
        timerLabel.frame = CGRect(x: 0, y: 100, width: view.bounds.width, height: 40)
        view.addSubview(timerLabel)
        
        // Recording indicator
        recordingIndicator = UIView()
        recordingIndicator.backgroundColor = .red
        recordingIndicator.layer.cornerRadius = 4
        recordingIndicator.isHidden = true
        recordingIndicator.frame = CGRect(x: view.bounds.width / 2 - 30, y: 100, width: 12, height: 12)
        view.addSubview(recordingIndicator)
        
        // Shutter button
        shutterButton = UIButton(type: .custom)
        shutterButton.backgroundColor = .white
        shutterButton.layer.cornerRadius = 40
        shutterButton.layer.borderWidth = 4
        shutterButton.layer.borderColor = UIColor.white.cgColor
        shutterButton.frame = CGRect(x: view.bounds.width / 2 - 40, y: view.bounds.height - 120, width: 80, height: 80)
        
        // Add long press gesture for video (must be added first)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3 // Increased to 0.3 seconds to distinguish from tap
        longPressGesture.allowableMovement = 10 // Allow small movement
        shutterButton.addGestureRecognizer(longPressGesture)
        
        // Add tap gesture for photo (must recognize simultaneously with long press)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        tapGesture.require(toFail: longPressGesture) // Tap only works if long press fails
        shutterButton.addGestureRecognizer(tapGesture)
        
        view.addSubview(shutterButton)
        
        // Add pan gesture for zoom during video recording
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        // Update layout when view appears
        DispatchQueue.main.async {
            self.updateLayout()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
    }
    
    private func updateLayout() {
        previewLayer?.frame = view.bounds
        
        closeButton.frame = CGRect(x: 20, y: view.safeAreaInsets.top + 10, width: 40, height: 40)
        flipButton.frame = CGRect(x: view.bounds.width - 60, y: view.safeAreaInsets.top + 10, width: 40, height: 40)
        timerLabel.frame = CGRect(x: 0, y: view.safeAreaInsets.top + 60, width: view.bounds.width, height: 40)
        recordingIndicator.frame = CGRect(x: view.bounds.width / 2 - 30, y: view.safeAreaInsets.top + 60, width: 12, height: 12)
        shutterButton.frame = CGRect(x: view.bounds.width / 2 - 40, y: view.bounds.height - view.safeAreaInsets.bottom - 120, width: 80, height: 80)
    }
    
    @objc private func closeTapped() {
        coordinator?.cancelled()
    }
    
    @objc private func flipCamera() {
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        
        // Remove current input
        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
        }
        
        // Switch camera position
        currentCameraPosition = currentCameraPosition == .back ? .front : .back
        
        // Add new input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            captureSession.commitConfiguration()
            return
        }
        
        currentVideoDevice = videoDevice
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        captureSession.commitConfiguration()
        
        // Reset zoom when flipping camera
        initialZoomFactor = 1.0
    }
    
    @objc private func takePhoto() {
        // Prevent photo capture if we're recording, about to record, or long press is active
        guard let photoOutput = photoOutput, !isRecording, !isLongPressActive else { return }
        
        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let videoOutput = videoOutput else { return }
        
        switch gesture.state {
        case .began:
            isLongPressActive = true
            // Only start recording if we're not already recording
            if !isRecording {
                startVideoRecording()
            }
        case .ended, .cancelled, .failed:
            isLongPressActive = false
            // Only stop if we're actually recording
            if isRecording {
                stopVideoRecording()
            }
            // Reset zoom when recording stops
            resetZoom()
        default:
            break
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // Only allow zoom during video recording
        guard isRecording, let device = currentVideoDevice else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        // Only process vertical pan gestures (ignore horizontal)
        guard abs(velocity.y) > abs(velocity.x) else { return }
        
        switch gesture.state {
        case .began:
            initialPanY = gesture.location(in: view).y
            initialZoomFactor = device.videoZoomFactor
        case .changed:
            // Calculate zoom based on vertical translation
            // Sliding up (negative translation.y) = zoom in
            // Sliding down (positive translation.y) = zoom out
            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10.0) // Cap at 10x
            let minZoom: CGFloat = 1.0
            let zoomRange = maxZoom - minZoom
            
            // Use screen height as reference for zoom sensitivity
            // Full screen height movement = full zoom range
            let normalizedTranslation = -translation.y / view.bounds.height // Negative because up = zoom in
            let zoomDelta = normalizedTranslation * zoomRange
            
            var newZoom = initialZoomFactor + zoomDelta
            newZoom = max(minZoom, min(maxZoom, newZoom)) // Clamp between min and max
            
            // Apply zoom smoothly
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = newZoom
                device.unlockForConfiguration()
            } catch {
                print("Failed to set zoom: \(error)")
            }
        case .ended, .cancelled, .failed:
            // Update initial zoom factor for next pan gesture
            initialZoomFactor = device.videoZoomFactor
            break
        default:
            break
        }
    }
    
    private func resetZoom() {
        guard let device = currentVideoDevice else { return }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = 1.0
            device.unlockForConfiguration()
            initialZoomFactor = 1.0
        } catch {
            print("Failed to reset zoom: \(error)")
        }
    }
    
    private func startVideoRecording() {
        guard let videoOutput = videoOutput, !isRecording else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoPath = documentsPath.appendingPathComponent("temp_video_\(UUID().uuidString).mov")
        
        videoOutput.startRecording(to: videoPath, recordingDelegate: self)
        isRecording = true
        recordingStartTime = Date()
        
        // Update UI
        DispatchQueue.main.async {
            self.shutterButton.backgroundColor = .red
            self.shutterButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.timerLabel.isHidden = false
            self.recordingIndicator.isHidden = false
            self.startTimer()
        }
    }
    
    private func stopVideoRecording() {
        guard isRecording else { return }
        
        videoOutput?.stopRecording()
        isRecording = false
        
        // Update UI
        DispatchQueue.main.async {
            self.shutterButton.backgroundColor = .white
            self.shutterButton.transform = .identity
            self.timerLabel.isHidden = true
            self.recordingIndicator.isHidden = true
            self.stopTimer()
        }
    }
    
    private var timer: Timer?
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            let minutes = Int(elapsed) / 60
            let seconds = Int(elapsed) % 60
            self.timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
            
            // Auto-stop at max duration
            if elapsed >= self.maxVideoDuration {
                self.stopVideoRecording()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        recordingStartTime = nil
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        coordinator?.photoCaptured(image)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Video recording error: \(error)")
            return
        }
        
        coordinator?.videoCaptured(outputFileURL)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension CameraViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pan gesture to work simultaneously with long press
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only allow pan gesture when recording
        if gestureRecognizer is UIPanGestureRecognizer {
            return isRecording
        }
        return true
    }
}

