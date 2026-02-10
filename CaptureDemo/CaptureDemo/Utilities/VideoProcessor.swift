//
//  VideoProcessor.swift
//  CaptureDemo
//
//  Created by Thanh Nguyen on 10/2/26.
//


import AVFoundation
import UIKit

enum VideoProcessError: Error, LocalizedError {
    case noVideoTrack
    case cannotCreateExportSession
    case exportFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .noVideoTrack: return "No video track found"
        case .cannotCreateExportSession: return "Cannot create export session"
        case .exportFailed: return "Video export failed"
        case .cancelled: return "Export cancelled"
        }
    }
}

enum TextPosition: String, CaseIterable {
    case top = "Top"
    case center = "Center"
    case bottom = "Bottom"
}

final class VideoProcessor {
    
    static func addOverlay(
        inputURL: URL,
        text: String,
        position: TextPosition = .top
    ) async throws -> URL {
        
        let asset = AVURLAsset(url: inputURL)
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoProcessError.noVideoTrack
        }
        
        let composition = AVMutableComposition()
        
        guard let compTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw VideoProcessError.noVideoTrack
        }
        
        let duration = try await asset.load(.duration)
        
        try compTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: videoTrack,
            at: .zero
        )
        
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        compTrack.preferredTransform = preferredTransform
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let transformedSize = naturalSize.applying(preferredTransform)
        
        let renderSize = CGSize(
            width: abs(transformedSize.width),
            height: abs(transformedSize.height)
        )
        
        // MARK: overlay layer
        
        let overlayLayer = makeTextLayer(text: text, videoSize: renderSize, position: position)
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: renderSize)
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: renderSize)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        // MARK: video composition
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack)
        
        layerInstruction.setTransform(preferredTransform, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
        
        return try await exportVideo(
            composition: composition,
            videoComposition: videoComposition
        )
    }
}

private extension VideoProcessor {
    
    static func exportVideo(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition
    ) async throws -> URL {
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).mov")
        
        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw VideoProcessError.cannotCreateExportSession
        }
        
        exporter.videoComposition = videoComposition
        exporter.shouldOptimizeForNetworkUse = true
        
        try await exporter.export(to: outputURL, as: .mov)
        
        return outputURL
    }
}

private extension VideoProcessor {
    
    static func makeTextLayer(text: String, videoSize: CGSize, position: TextPosition) -> CALayer {
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.fontSize = 42
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = UIColor.red.cgColor
        textLayer.contentsScale = UIScreen.main.scale
        
        var textFrame = CGRect(
            x: 0,
            y: videoSize.height - 120,
            width: videoSize.width,
            height: 80
        )
        switch position {
        case .bottom:
            textFrame = CGRect(
                x: 0,
                y: 20,
                width: videoSize.width,
                height: 80
            )
        case .center:
            textFrame = CGRect(
                x: 0,
                y: videoSize.height / 2.0 - 40,
                width: videoSize.width,
                height: 80
            )
        default:
            break
        }
        textLayer.frame = textFrame
        
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0
        fade.toValue = 1
        fade.duration = 2
        textLayer.add(fade, forKey: "fade")
        
        return textLayer
    }
}
