//
//  RecordButton.swift
//  CaptureDemo
//
//  Created by Thanh Nguyen on 10/2/26.
//


import SwiftUI

struct RecordButton: View {
    
    let isRecording: Bool
    let progress: Double
    let action: () -> Void
    
    var body: some View {
        ZStack {
            
            // progress ring
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 6)
                .frame(width: 90, height: 90)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 90, height: 90)
                .animation(.linear(duration: 0.05), value: progress)
            
            // inner button
            Button(action: action) {
                Circle()
                    .fill(isRecording ? Color.red : Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}
