//
//  CameraView.swift
//  TheHotelMedia
//
//  Created for hold-to-record video functionality
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Camera View
struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    let onPhotoCaptured: (UIImage) -> Void
    let onVideoCaptured: (URL) -> Void
    
    // Simulator fallback
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    
    init(
        isPresented: Binding<Bool>,
        onPhotoCaptured: @escaping (UIImage) -> Void,
        onVideoCaptured: @escaping (URL) -> Void
    ) {
        self._isPresented = isPresented
        self.onPhotoCaptured = onPhotoCaptured
        self.onVideoCaptured = onVideoCaptured
        self._viewModel = StateObject(wrappedValue: CameraViewModel())
    }
    
    var body: some View {
        #if targetEnvironment(simulator)
        // Simulator: Show photo library picker instead
        simulatorFallbackView
        #else
        // Real device: Show camera
        cameraView
        #endif
    }
    
    // MARK: - Simulator Fallback View
    private var simulatorFallbackView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Camera Not Available")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Running on Simulator")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                VStack(spacing: 16) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Select Photo")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showVideoPicker = true
                    }) {
                        HStack {
                            Image(systemName: "video")
                            Text("Select Video")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            SimulatorImagePicker(isPresented: $showImagePicker) { image in
                onPhotoCaptured(image)
                isPresented = false
            }
        }
        .sheet(isPresented: $showVideoPicker) {
            SimulatorVideoPicker(isPresented: $showVideoPicker) { url in
                onVideoCaptured(url)
                isPresented = false
            }
        }
    }
    
    // MARK: - Real Camera View
    private var cameraView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Camera Preview
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()
            
            VStack {
                // Top Controls
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.toggleFlash()
                    }) {
                        Image(systemName: viewModel.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title2)
                            .foregroundColor(viewModel.flashMode == .on ? .yellow : .white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                Spacer()
                
                // Recording Timer
                if viewModel.isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .opacity(viewModel.recordingPulse ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.recordingPulse)
                        
                        Text(viewModel.recordingTimeString)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                    )
                    .padding(.bottom, 20)
                    .onAppear {
                        viewModel.recordingPulse = true
                    }
                }
                
                // Bottom Controls
                HStack(spacing: 60) {
                    // Camera Flip Button
                    Button(action: {
                        viewModel.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                    }
                    .disabled(viewModel.isRecording)
                    .opacity(viewModel.isRecording ? 0.5 : 1.0)
                    
                    // Capture/Record Button
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(viewModel.isRecording ? Color.red : Color.white)
                            .frame(width: viewModel.isRecording ? 40 : 70, height: viewModel.isRecording ? 40 : 70)
                            .cornerRadius(viewModel.isRecording ? 8 : 35)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !viewModel.isRecording {
                                    viewModel.startRecording()
                                }
                            }
                            .onEnded { _ in
                                if viewModel.isRecording {
                                    viewModel.stopRecording { url in
                                        if let url = url {
                                            onVideoCaptured(url)
                                            isPresented = false
                                        }
                                    }
                                } else {
                                    viewModel.capturePhoto { image in
                                        if let image = image {
                                            onPhotoCaptured(image)
                                            isPresented = false
                                        }
                                    }
                                }
                            }
                    )
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 60, height: 60)
                }
                .padding(.bottom, 40)
            }
            
            // Permission Denied Overlay
            if viewModel.showPermissionDenied {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Please enable camera access in Settings to use this feature.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }) {
                        Text("Open Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .onAppear {
            viewModel.checkPermissions()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}

// MARK: - Simulator Image Picker
struct SimulatorImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SimulatorImagePicker
        
        init(_ parent: SimulatorImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Simulator Video Picker
struct SimulatorVideoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onVideoSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SimulatorVideoPicker
        
        init(_ parent: SimulatorVideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoSelected(videoURL)
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Camera ViewModel
class CameraViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var recordingTimeString = "00:00"
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var showPermissionDenied = false
    @Published var recordingPulse = false
    
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput = AVCapturePhotoOutput()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    private var recordingTimer: Timer?
    private var photoCaptureCompletion: ((UIImage?) -> Void)?
    private var videoCaptureCompletion: ((URL?) -> Void)?
    
    override init() {
        super.init()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showPermissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDenied = true
        @unknown default:
            showPermissionDenied = true
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Setup video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
            videoDeviceInput = videoInput
        }
        
        // Setup audio input for video recording
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        // Setup photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        // Setup movie output
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            
            // Configure movie output connection after session starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let connection = self?.movieOutput.connection(with: .video) {
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCaptureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Verify movie output has active connections
        guard let connection = movieOutput.connection(with: .video), connection.isActive else {
            print("Error: No active video connection for recording")
            return
        }
        
        let outputPath = NSTemporaryDirectory() + UUID().uuidString + ".mov"
        let outputURL = URL(fileURLWithPath: outputPath)
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        isRecording = true
        recordingTime = 0
        updateRecordingTime()
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateRecordingTime()
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else { return }
        
        videoCaptureCompletion = completion
        movieOutput.stopRecording()
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        recordingPulse = false
    }
    
    private func updateRecordingTime() {
        recordingTime += 1
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        recordingTimeString = String(format: "%02d:%02d", minutes, seconds)
    }
    
    func switchCamera() {
        guard !isRecording else { return }
        
        session.beginConfiguration()
        
        // Remove current input
        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
        }
        
        // Switch position
        currentCameraPosition = currentCameraPosition == .back ? .front : .back
        
        // Add new input
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            videoDeviceInput = newInput
        }
        
        session.commitConfiguration()
        
        // Re-establish movie output connection after camera switch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if let connection = self?.movieOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        }
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
}

// MARK: - Photo Capture Delegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoCaptureCompletion?(nil)
            return
        }
        
        photoCaptureCompletion?(image)
    }
}

// MARK: - Video Recording Delegate
extension CameraViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Started recording to: \(fileURL)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error.localizedDescription)")
            videoCaptureCompletion?(nil)
        } else {
            print("Finished recording to: \(outputFileURL)")
            videoCaptureCompletion?(outputFileURL)
        }
    }
}
