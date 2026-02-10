//
//  PreviewVideoView.swift
//  CaptureDemo
//
//  Created by Thanh Nguyen on 10/2/26.
//

import SwiftUI
import AVKit

struct PreviewVideoView: View {
    
    @StateObject private var viewModel: PreviewVideoViewModel
    
    init(videoURL: URL) {
        _viewModel = StateObject(wrappedValue: PreviewVideoViewModel(videoURL: videoURL))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            if let url = viewModel.processedURL {
                VideoPlayer(player: AVPlayer(url: url))
                
                Button {
                    viewModel.saveToLibrary()
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("Save to Library")
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if viewModel.saveSuccess {
                    Text("✅ Saved successfully")
                        .foregroundStyle(.green)
                }
            }
            
            else if viewModel.isProcessing {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Processing video...")
                }
                Spacer()
            }
            
            else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text("Error")
                        .font(.title2)
                        .foregroundStyle(.red)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        viewModel.processVideo()
                    }
                }
            }
            Spacer()
            Picker("", selection: $viewModel.textPosition) {
                ForEach(TextPosition.allCases, id: \.self) { pos in
                    Text(pos.rawValue).tag(pos)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .padding()
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.processVideo()
        }
    }
}
