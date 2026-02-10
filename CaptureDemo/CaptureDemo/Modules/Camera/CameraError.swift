//
//  CameraError.swift
//  CaptureDemo
//
//  Created by Thanh Nguyen on 10/2/26.
//

import Foundation

enum CameraError: LocalizedError {
    case cameraPermissionDenied
    case microphonePermissionDenied
    case cameraNotAvailable
    case microphoneNotAvailable
    case sessionConfigurationFailed
    case recordingFailed(String)
    case switchCameraFailed

    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "Camera access is required to record videos. Please enable camera access in Settings."
        case .microphonePermissionDenied:
            return "Microphone access is required to record audio. Please enable microphone access in Settings."
        case .cameraNotAvailable:
            return "Camera is not available on this device."
        case .microphoneNotAvailable:
            return "Microphone is not available on this device."
        case .sessionConfigurationFailed:
            return "Failed to configure camera session. Please try again."
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        case .switchCameraFailed:
            return "Failed to switch camera. Please try again."
        }
    }
}

enum CameraState {
    case loading
    case ready
    case error(CameraError)
}
