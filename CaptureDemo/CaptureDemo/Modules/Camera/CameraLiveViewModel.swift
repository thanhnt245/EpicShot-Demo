//
//  CameraLiveViewModel.swift
//  CaptureDemo
//
//  Created by Thanh Nguyen on 10/2/26.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

final class CameraLiveViewModel: NSObject, ObservableObject {
    @Published var currentPosition: AVCaptureDevice.Position = .back
    @Published var isRecording = false
    @Published var recordedURL: URL?
    @Published var recordProgress: Double = 0
    @Published var cameraState: CameraState = .loading
    @Published var currentError: CameraError?

    let session = AVCaptureSession()

    private var videoInput: AVCaptureDeviceInput?
    private var recordTimer: Timer?
    private let maxDuration: Double = Constants.videoMaxDuration
    private var startTime: Date?
    
    private let movieOutput = AVCaptureMovieFileOutput()
    private let cameraActionQueue = DispatchQueue.global()
    private let mainQueue = DispatchQueue.main
    
    override init() {
        super.init()
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError),
            name: AVCaptureSession.runtimeErrorNotification,
            object: session
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: AVCaptureSession.wasInterruptedNotification,
            object: session
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: AVCaptureSession.interruptionEndedNotification,
            object: session
        )
    }

    @objc private func sessionRuntimeError(notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }

        print("Capture session runtime error: \(error)")

        DispatchQueue.main.async {
            self.setError(.sessionConfigurationFailed)
        }

        // Try to restart the session if possible
        if error.code == .mediaServicesWereReset {
            cameraActionQueue.async {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }
    }

    @objc private func sessionWasInterrupted(notification: Notification) {
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
           let reasonIntegerValue = userInfoValue.integerValue,
           let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {

            print("Capture session was interrupted with reason \(reason)")

            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                // Handle gracefully - stop recording if in progress
                if isRecording {
                    DispatchQueue.main.async {
                        self.stopRecording()
                    }
                }
            }
        }
    }

    @objc private func sessionInterruptionEnded(notification: Notification) {
        print("Capture session interruption ended")
    }

    private func checkPermissions() async -> Bool {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        // Check camera permission
        switch cameraStatus {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                await MainActor.run {
                    setError(.cameraPermissionDenied)
                }
                return false
            }
        case .denied, .restricted:
            await MainActor.run {
                setError(.cameraPermissionDenied)
            }
            return false
        case .authorized:
            break
        @unknown default:
            await MainActor.run {
                setError(.cameraPermissionDenied)
            }
            return false
        }

        // Check microphone permission
        switch microphoneStatus {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if !granted {
                await MainActor.run {
                    setError(.microphonePermissionDenied)
                }
                return false
            }
        case .denied, .restricted:
            await MainActor.run {
                setError(.microphonePermissionDenied)
            }
            return false
        case .authorized:
            break
        @unknown default:
            await MainActor.run {
                setError(.microphonePermissionDenied)
            }
            return false
        }

        return true
    }

    private func setError(_ error: CameraError) {
        currentError = error
        cameraState = .error(error)
    }

    private func clearError() {
        currentError = nil
        cameraState = .ready
    }

    func setupSession() async {
        // Check permissions first
        guard await checkPermissions() else { return }

        await MainActor.run {
            cameraState = .loading
        }

        do {
            try await configureSession()
            await MainActor.run {
                clearError()
            }
        } catch {
            await MainActor.run {
                if let cameraError = error as? CameraError {
                    setError(cameraError)
                } else {
                    setError(.sessionConfigurationFailed)
                }
            }
        }
    }

    private func configureSession() async throws {
        session.beginConfiguration()
        for input in session.inputs {
            session.removeInput(input)
        }
        for output in session.outputs {
            session.removeOutput(output)
        }
        session.sessionPreset = .high

        // Setup video input
        guard let device = getCamera(position: currentPosition) else {
            session.commitConfiguration()
            throw CameraError.cameraNotAvailable
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch {
            session.commitConfiguration()
            throw CameraError.cameraNotAvailable
        }

        guard session.canAddInput(videoInput) else {
            session.commitConfiguration()
            throw CameraError.sessionConfigurationFailed
        }

        session.addInput(videoInput)
        self.videoInput = videoInput

        // Setup audio input
        if let mic = AVCaptureDevice.default(for: .audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: mic)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                }
            } catch {
                // Audio is optional, continue without it but log the issue
                print("Warning: Could not add audio input: \(error)")
            }
        }

        // Setup movie output
        guard session.canAddOutput(movieOutput) else {
            session.commitConfiguration()
            throw CameraError.sessionConfigurationFailed
        }

        session.addOutput(movieOutput)
        session.commitConfiguration()
    }
    
    func startSession() {
        Task {
            await setupSession()

            // Only start the session if setup was successful
            if case .ready = cameraState {
                cameraActionQueue.async {
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                }
            }
        }
    }

    func retrySetup() {
        Task {
            await setupSession()

            if case .ready = cameraState {
                cameraActionQueue.async {
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                }
            }
        }
    }
    
    func stopSession() {
        cameraActionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func switchCamera() {
        guard case .ready = cameraState else {
            setError(.switchCameraFailed)
            return
        }

        guard let currentInput = videoInput else {
            setError(.switchCameraFailed)
            return
        }

        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back

        guard let newDevice = getCamera(position: newPosition) else {
            setError(.cameraNotAvailable)
            return
        }

        let newInput: AVCaptureDeviceInput
        do {
            newInput = try AVCaptureDeviceInput(device: newDevice)
        } catch {
            setError(.switchCameraFailed)
            return
        }

        session.beginConfiguration()

        // Remove current input
        session.removeInput(currentInput)

        // Try to add new input
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            videoInput = newInput
            currentPosition = newPosition
            session.commitConfiguration()
        } else {
            // Revert to previous input if new one failed
            session.addInput(currentInput)
            session.commitConfiguration()
            setError(.switchCameraFailed)
        }
    }
    
    func startRecording() {
        guard case .ready = cameraState else {
            setError(.recordingFailed("Camera not ready"))
            return
        }

        guard !isRecording else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).mov")

        // Clear any previous errors before starting
        if currentError != nil {
            clearError()
        }

        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true

        startTime = Date()
        recordProgress = 0
        startProgressTimer()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        movieOutput.stopRecording()
        isRecording = false
        stopProgressTimer()
        recordProgress = 0
    }
    
    private func getCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera,
                                for: .video,
                                position: position)
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        
        recordTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self,
                  let start = self.startTime else { return }
            
            let elapsed = Date().timeIntervalSince(start)
            self.recordProgress = min(elapsed / self.maxDuration, 1.0)
            
            // auto stop at 10s
            if elapsed >= self.maxDuration {
                self.stopRecording()
            }
        }
    }

    private func stopProgressTimer() {
        recordTimer?.invalidate()
        recordTimer = nil
    }

}

extension CameraLiveViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {

        mainQueue.async {
            if let error = error {
                print("Recording failed with error: \(error.localizedDescription)")
                self.setError(.recordingFailed(error.localizedDescription))
            } else {
                self.recordedURL = outputFileURL
                // Clear any previous errors on successful recording
                if self.currentError != nil {
                    self.clearError()
                }
            }
        }
    }
}
