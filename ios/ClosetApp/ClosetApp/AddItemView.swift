//
//  AddItemView.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import SwiftUI

struct AddItemView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Add an item",
                systemImage: "camera",
                description: Text("Photo capture comes soon (Day 5).")
            )
            .navigationTitle("Add")
        }
    }
}

#Preview {
    AddItemView()
}
