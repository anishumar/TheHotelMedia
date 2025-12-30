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
    
    private var shutterButton: UIButton!
    private var flipButton: UIButton!
    private var closeButton: UIButton!
    private var timerLabel: UILabel!
    private var recordingIndicator: UIView!
    
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
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
        
        // Add tap gesture for photo
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        shutterButton.addGestureRecognizer(tapGesture)
        
        // Add long press gesture for video
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.1
        shutterButton.addGestureRecognizer(longPressGesture)
        
        view.addSubview(shutterButton)
        
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
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        captureSession.commitConfiguration()
    }
    
    @objc private func takePhoto() {
        guard let photoOutput = photoOutput, !isRecording else { return }
        
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
            startVideoRecording()
        case .ended, .cancelled:
            stopVideoRecording()
        default:
            break
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

