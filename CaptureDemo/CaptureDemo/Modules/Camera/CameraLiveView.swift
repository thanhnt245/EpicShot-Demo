//
//  CameraLiveView.swift
//  CaptureDemo
//
//  Created by Thanh Nguyen on 10/2/26.
//

import SwiftUI
import UIKit

struct CameraLiveView: View {
    @StateObject var viewModel = CameraLiveViewModel()
    @State private var navigatePreview = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            // Camera Preview (only show when ready)
            if case .ready = viewModel.cameraState {
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()
            } else {
                // Background for error/loading states
                Color.black
                    .ignoresSafeArea()
            }

            // Main content overlay
            switch viewModel.cameraState {
            case .loading:
                loadingView
            case .ready:
                readyStateView
            case .error(let error):
                errorView(error)
            }
        }
        .onAppear { viewModel.startSession() }
        .onDisappear { viewModel.stopSession() }
        .onChange(of: viewModel.recordedURL) { _, newValue in
            if newValue != nil {
                navigatePreview = true
            }
        }
        .navigationDestination(isPresented: $navigatePreview) {
            if let url = viewModel.recordedURL {
                PreviewVideoView(videoURL: url)
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Setting up camera...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private var readyStateView: some View {
        VStack {
            HStack {
                Spacer()

                Button {
                    viewModel.switchCamera()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 22, weight: .bold))
                        .padding(12)
                        .background(.black.opacity(0.5))
                        .clipShape(Circle())
                        .foregroundStyle(.white)
                }
                .padding(.trailing, 20)
                .padding(.top, 20)
            }
            Spacer()

            RecordButton(
                isRecording: viewModel.isRecording,
                progress: viewModel.recordProgress
            ) {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private func errorView(_ error: CameraError) -> some View {
        VStack(spacing: 24) {
            // Error icon
            Image(systemName: errorIcon(for: error))
                .font(.system(size: 64))
                .foregroundColor(.white)
                .opacity(0.8)

            VStack(spacing: 12) {
                Text(errorTitle(for: error))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Action buttons
            VStack(spacing: 12) {
                switch error {
                case .cameraPermissionDenied, .microphonePermissionDenied:
                    Button("Open Settings") {
                        openSettings()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                default:
                    Button("Try Again") {
                        viewModel.retrySetup()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func errorIcon(for error: CameraError) -> String {
        switch error {
        case .cameraPermissionDenied:
            return "camera.fill"
        case .microphonePermissionDenied:
            return "mic.fill"
        case .cameraNotAvailable:
            return "camera.fill"
        case .microphoneNotAvailable:
            return "mic.fill"
        case .sessionConfigurationFailed:
            return "exclamationmark.triangle.fill"
        case .recordingFailed:
            return "record.circle.fill"
        case .switchCameraFailed:
            return "arrow.triangle.2.circlepath.camera.fill"
        }
    }

    private func errorTitle(for error: CameraError) -> String {
        switch error {
        case .cameraPermissionDenied:
            return "Camera Access Required"
        case .microphonePermissionDenied:
            return "Microphone Access Required"
        case .cameraNotAvailable:
            return "Camera Not Available"
        case .microphoneNotAvailable:
            return "Microphone Not Available"
        case .sessionConfigurationFailed:
            return "Camera Setup Failed"
        case .recordingFailed:
            return "Recording Failed"
        case .switchCameraFailed:
            return "Camera Switch Failed"
        }
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Custom Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    CameraLiveView()
}
