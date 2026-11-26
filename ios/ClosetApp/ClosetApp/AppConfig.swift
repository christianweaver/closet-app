//
//  AppConfig.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import Foundation

enum AppConfig {
    // In the Simulator, localhost is your Mac.
    // A real iPhone needs your Mac's Wi-Fi IP address instead (Step 8).
    static let apiBaseURL = URL(string: "http://localhost:8000")!
}
