//
//  ClosetView.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import SwiftUI

struct ClosetView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No items yet",
                systemImage: "tshirt",
                description: Text("Your closet will appear here.")
            )
            .navigationTitle("Closet")
        }
    }
}

#Preview {
    ClosetView()
}
