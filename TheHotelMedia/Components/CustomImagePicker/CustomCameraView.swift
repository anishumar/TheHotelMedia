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
    weak var coordinator: CustomCameraView.Coordinator?
    var maxVideoDuration: TimeInterval = 180
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isRecording = false
    private var recordingStartTime: Date?
    private var isLongPressActive = false // Track if long press gesture is active
    private let sessionQueue = DispatchQueue(label: "com.thehotelmedia.camera.sessionQueue")
    private var isSessionConfigured = false
    private var shouldResumeSessionOnForeground = false
    
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
        setupUI()
        setupObservers()
        checkPermissionAndConfigureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
        stopSession()
    }

    deinit {
        // Stop timer synchronously to ensure it's invalidated before deallocation
        stopTimer()
        recordingStartTime = nil
        
        // Stop recording animation
        recordingIndicator?.layer.removeAnimation(forKey: "pulse")
        recordingAnimation = nil
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        
        // Clean up capture session
        sessionQueue.sync {
            if let session = captureSession, session.isRunning {
                session.stopRunning()
            }
            // Remove all inputs and outputs
            if let session = captureSession {
                session.beginConfiguration()
                for input in session.inputs {
                    session.removeInput(input)
                }
                for output in session.outputs {
                    session.removeOutput(output)
                }
                session.commitConfiguration()
            }
            captureSession = nil
            photoOutput = nil
            videoOutput = nil
            currentVideoDevice = nil
        }
        
        // Remove preview layer
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted(_:)),
                                               name: AVCaptureSession.wasInterruptedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded(_:)),
                                               name: AVCaptureSession.interruptionEndedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError(_:)),
                                               name: AVCaptureSession.runtimeErrorNotification, object: nil)
    }

    private func checkPermissionAndConfigureSession() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            configureSessionIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    if granted {
                        self.configureSessionIfNeeded()
                        self.startSession()
                    } else {
                        self.showPermissionAlertAndClose()
                    }
                }
            }
        default:
            showPermissionAlertAndClose()
        }
    }

    private func showPermissionAlertAndClose() {
        let alert = UIAlertController(
            title: "Camera Permission",
            message: "Please allow camera access in Settings to take photos/videos.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.coordinator?.cancelled()
        })
        present(alert, animated: true)
    }

    private func configureSessionIfNeeded() {
        guard !isSessionConfigured else { return }
        isSessionConfigured = true
        sessionQueue.async { [weak self] in
            self?.setupCamera()
            // Avoid a race where viewWillAppear() calls startSession() before the session exists.
            // Starting here guarantees the session runs once configuration finishes.
            if let session = self?.captureSession, !session.isRunning {
                session.startRunning()
            }
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        captureSession = session
        
        session.beginConfiguration()
        // Use high preset for video recording (best quality for video)
        session.sessionPreset = .high
        
        // Setup camera input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            session.commitConfiguration()
            return
        }
        
        currentVideoDevice = videoDevice
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Setup audio input for video recording
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        // Setup photo output
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        // Setup video output
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, session.canAddOutput(videoOutput) {
            // Set max duration
            let maxDuration = CMTime(seconds: maxVideoDuration, preferredTimescale: 600)
            videoOutput.maxRecordedDuration = maxDuration
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()

        // Setup preview layer
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let captureSession = self.captureSession else { return }
            // Check if view is still loaded and window exists
            guard self.isViewLoaded, self.view.window != nil else { return }
            // Prevent stacking layers if the session gets reconfigured.
            self.previewLayer?.removeFromSuperlayer()
            self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.previewLayer?.videoGravity = .resizeAspectFill
            if let previewLayer = self.previewLayer {
                self.view.layer.insertSublayer(previewLayer, at: 0)
                previewLayer.frame = self.view.bounds
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Close button - Native iOS style
        closeButton = UIButton(type: .system)
        let closeImage = UIImage(systemName: "xmark.circle.fill")
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = .white
        closeButton.frame = CGRect(x: 20, y: 50, width: 44, height: 44)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // Flip camera button - Native iOS style
        flipButton = UIButton(type: .system)
        let flipImage = UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill")
        flipButton.setImage(flipImage, for: .normal)
        flipButton.tintColor = .white
        flipButton.frame = CGRect(x: view.bounds.width - 64, y: 50, width: 44, height: 44)
        flipButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
        view.addSubview(flipButton)
        
        // Timer label - Clean, native iOS style
        timerLabel = UILabel()
        timerLabel.text = "00:00"
        timerLabel.textColor = .white
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .medium)
        timerLabel.textAlignment = .center
        timerLabel.isHidden = true
        timerLabel.frame = CGRect(x: 0, y: 0, width: 60, height: 22)
        view.addSubview(timerLabel)
        
        // Recording indicator - Clean, native iOS style
        recordingIndicator = UIView()
        recordingIndicator.backgroundColor = .systemRed
        recordingIndicator.layer.cornerRadius = 3
        recordingIndicator.isHidden = true
        recordingIndicator.frame = CGRect(x: 0, y: 0, width: 6, height: 6)
        view.addSubview(recordingIndicator)
        
        // Shutter button - Native iOS camera style
        shutterButton = UIButton(type: .custom)
        shutterButton.backgroundColor = .white
        shutterButton.layer.cornerRadius = 35
        shutterButton.layer.borderWidth = 5
        shutterButton.layer.borderColor = UIColor.white.cgColor
        shutterButton.frame = CGRect(x: view.bounds.width / 2 - 35, y: view.bounds.height - 120, width: 70, height: 70)
        
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isViewLoaded else { return }
            self.updateLayout()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
    }
    
    private func updateLayout() {
        previewLayer?.frame = view.bounds
        
        // Top controls - positioned in safe area
        let topInset = view.safeAreaInsets.top
        closeButton.frame = CGRect(x: 20, y: topInset + 8, width: 44, height: 44)
        flipButton.frame = CGRect(x: view.bounds.width - 64, y: topInset + 8, width: 44, height: 44)
        
        // Timer and recording indicator - centered at top
        let timerY = topInset + 12
        timerLabel.frame = CGRect(x: view.bounds.width / 2 - 30, y: timerY, width: 60, height: 22)
        recordingIndicator.frame = CGRect(x: view.bounds.width / 2 - 3, y: timerY + 26, width: 6, height: 6)
        
        // Shutter button - bottom center with safe area
        let bottomInset = view.safeAreaInsets.bottom
        shutterButton.frame = CGRect(x: view.bounds.width / 2 - 35, y: view.bounds.height - bottomInset - 100, width: 70, height: 70)
    }
    
    @objc private func closeTapped() {
        coordinator?.cancelled()
    }
    
    @objc private func flipCamera() {
        guard !isRecording else { return }
        sessionQueue.async { [weak self] in
            guard let self, let captureSession = self.captureSession else { return }

            captureSession.beginConfiguration()

            // Remove current video input (keep audio)
            if let currentVideoInput = captureSession.inputs.compactMap({ $0 as? AVCaptureDeviceInput })
                .first(where: { $0.device.hasMediaType(.video) }) {
                captureSession.removeInput(currentVideoInput)
            }

            // Switch camera position
            self.currentCameraPosition = self.currentCameraPosition == .back ? .front : .back

            // Add new input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentCameraPosition),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                captureSession.commitConfiguration()
                return
            }

            self.currentVideoDevice = videoDevice

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            captureSession.commitConfiguration()

            // Reset zoom when flipping camera
            self.initialZoomFactor = 1.0
        }
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
        
        sessionQueue.async {
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
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
        
        sessionQueue.async { [weak self] in
            guard let self else { return }
            videoOutput.startRecording(to: videoPath, recordingDelegate: self)
        }
        isRecording = true
        recordingStartTime = Date()
        
        // Update UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isViewLoaded else { return }
            // Clean native iOS recording state
            UIView.animate(withDuration: 0.2) {
                self.shutterButton.backgroundColor = .systemRed
                self.shutterButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                self.shutterButton.layer.cornerRadius = 8
            }
            self.timerLabel.isHidden = false
            self.timerLabel.textColor = .white
            self.recordingIndicator.isHidden = false
            self.startRecordingAnimation()
            self.startTimer()
        }
    }
    
    private func stopVideoRecording() {
        guard isRecording else { return }
        
        sessionQueue.async { [weak self] in
            self?.videoOutput?.stopRecording()
        }
        isRecording = false
        
        // Stop timer and clear recording start time
        stopTimer()
        recordingStartTime = nil
        
        // Update UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isViewLoaded else { return }
            // Reset to original state with animation
            UIView.animate(withDuration: 0.2) {
                self.shutterButton.backgroundColor = .white
                self.shutterButton.transform = .identity
                self.shutterButton.layer.cornerRadius = 35
            }
            self.timerLabel.isHidden = true
            self.recordingIndicator.isHidden = true
            self.stopRecordingAnimation()
        }
    }
    
    private var timer: Timer?
    private var recordingAnimation: CAAnimation?
    
    private func startRecordingAnimation() {
        // Stop any existing animation
        stopRecordingAnimation()
        
        // Clean, subtle pulsing animation
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 0.5
        pulseAnimation.duration = 1.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .greatestFiniteMagnitude
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        recordingIndicator.layer.add(pulseAnimation, forKey: "pulse")
        recordingAnimation = pulseAnimation
    }
    
    private func stopRecordingAnimation() {
        recordingIndicator.layer.removeAnimation(forKey: "pulse")
        recordingAnimation = nil
    }
    
    private func startTimer() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.startTimer()
            }
            return
        }
        
        // Stop any existing timer first
        stopTimer()
        
        // Ensure recordingStartTime is set
        guard recordingStartTime != nil else {
            print("Warning: recordingStartTime is nil, cannot start timer")
            return
        }
        
        let newTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            guard let startTime = self.recordingStartTime else {
                timer.invalidate()
                return
            }
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = max(0, self.maxVideoDuration - elapsed)
            
            // Format elapsed time
            let minutes = Int(elapsed) / 60
            let seconds = Int(elapsed) % 60
            
            // Format remaining time
            let remainingMinutes = Int(remaining) / 60
            let remainingSeconds = Int(remaining) % 60
            
            // Update UI on main thread - Clean native style
            DispatchQueue.main.async {
                // Simple timer display
                self.timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
                
                // Subtle color change when approaching limit
                if remaining <= 3 {
                    self.timerLabel.textColor = .systemRed
                } else {
                    self.timerLabel.textColor = .white
                }
            }
            
            // Auto-stop at max duration
            if elapsed >= self.maxVideoDuration {
                DispatchQueue.main.async {
                    self.stopVideoRecording()
                }
            }
        }
        timer = newTimer
        RunLoop.current.add(newTimer, forMode: .common)
    }
    
    private func stopTimer() {
        // Timer must be invalidated on the main thread
        // Don't clear recordingStartTime here - it should only be cleared when stopping recording
        let timerToInvalidate = timer
        timer = nil
        
        if Thread.isMainThread {
            timerToInvalidate?.invalidate()
        } else {
            DispatchQueue.main.async {
                timerToInvalidate?.invalidate()
            }
        }
    }
    
    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, let session = self.captureSession else { return }
            if !session.isRunning {
                session.startRunning()
            }
        }
    }
    
    private func stopSession() {
        // Use a synchronous dispatch group to ensure cleanup completes
        let group = DispatchGroup()
        group.enter()
        sessionQueue.async { [weak self] in
            defer { group.leave() }
            guard let self, let session = self.captureSession else { return }
            if session.isRunning {
                session.stopRunning()
            }
        }
        // Wait with a timeout to avoid blocking indefinitely
        _ = group.wait(timeout: .now() + 1.0)
    }

    @objc private func appWillResignActive() {
        // If the camera view is visible and the app is backgrounding/interrupted, stop the session.
        shouldResumeSessionOnForeground = isViewLoaded && view.window != nil
        stopSession()
    }

    @objc private func appDidBecomeActive() {
        guard shouldResumeSessionOnForeground else { return }
        shouldResumeSessionOnForeground = false
        startSession()
    }

    @objc private func sessionWasInterrupted(_ notification: Notification) {
        // Treat interruption like backgrounding; we'll resume when it ends/when app becomes active.
        shouldResumeSessionOnForeground = true
    }

    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        startSession()
    }

    @objc private func sessionRuntimeError(_ notification: Notification) {
        // Common recovery path when media services reset.
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        if error.code == .mediaServicesWereReset {
            startSession()
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

