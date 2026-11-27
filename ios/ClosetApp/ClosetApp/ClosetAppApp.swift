//
//  ClosetAppApp.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/25/26.
//

import SwiftUI

@main
struct ClosetAppApp: App {
    @State private var closet = ClosetModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(closet)
        }
    }
}
