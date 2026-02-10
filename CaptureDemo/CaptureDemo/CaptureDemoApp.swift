//
//  CaptureDemoApp.swift
//  CaptureDemo
//
//  Created by Thanh Nguyen on 10/2/26.
//

import SwiftUI

@main
struct CaptureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CameraLiveView()
            }
        }
    }
}
