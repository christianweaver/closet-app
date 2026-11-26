//
//  OutfitsView.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import SwiftUI

struct OutfitsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No outfits yet",
                systemImage: "sparkles",
                description: Text("Outfit generation comes on Day 6.")
            )
            .navigationTitle("Outfits")
        }
    }
}

#Preview {
    OutfitsView()
}
