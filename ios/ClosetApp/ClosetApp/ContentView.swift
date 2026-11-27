//
//  ContentView.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/25/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Closet", systemImage: "tshirt") {
                ClosetView()
            }
            Tab("Add", systemImage: "plus.circle") {
                AddItemView()
            }
            Tab("Outfits", systemImage: "sparkles") {
                OutfitsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(ClosetModel())
}
