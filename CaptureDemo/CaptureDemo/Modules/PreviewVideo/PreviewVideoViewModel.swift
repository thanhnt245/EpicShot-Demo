//
//  PreviewVideoViewModel.swift
//  CaptureDemo
//
//  Created by Thanh Nguyen on 10/2/26.
//


import Foundation
import Combine
import Foundation
import Photos
import SwiftUI

@MainActor
final class PreviewVideoViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published var processedURL: URL?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var textPosition: TextPosition = .top
    
    private let originalURL: URL
    
    init(videoURL: URL) {
        self.originalURL = videoURL
        
        $textPosition
            .sink { [weak self] newValue in
                self?.processVideo()
            }
            .store(in: &cancellables)
    }
}

extension PreviewVideoViewModel {
    func overlayText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "\(Constants.overlayPrefixText) • \(formatter.string(from: Date()))"
    }

    func processVideo() {
        processedURL = nil
        errorMessage = nil
        isProcessing = true
        
        Task {
            do {
                let result = try await VideoProcessor.addOverlay(
                    inputURL: originalURL,
                    text: overlayText(),
                    position: textPosition
                )
                
                self.processedURL = result
                self.isProcessing = false
                
            } catch {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
            }
        }
    }
    
    func saveToLibrary() {
        guard let url = processedURL else { return }
        
        isSaving = true
        saveSuccess = false
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            
            guard status == .authorized || status == .limited else {
                Task { @MainActor in
                    self.errorMessage = "Photo library permission denied"
                    self.isSaving = false
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                
                Task { @MainActor in
                    self.isSaving = false
                    
                    if success {
                        self.saveSuccess = true
                    } else {
                        self.errorMessage = error?.localizedDescription ?? "Save failed"
                    }
                }
            }
        }
    }
}


