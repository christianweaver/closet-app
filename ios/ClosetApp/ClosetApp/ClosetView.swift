//
//  ClosetView.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import SwiftUI

struct ClosetView: View {
    @State private var model = ClosetModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Closet")
                .navigationDestination(for: Item.self){
                    item in ItemDetailView(item: item)
                }
        }
        .task {
            await model.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView("Loading your closet…")

        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load your closet", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") {
                    Task { await model.load() }
                }
                .buttonStyle(.borderedProminent)
            }

        case .loaded(let items) where items.isEmpty:
            ContentUnavailableView(
                "No items yet",
                systemImage: "tshirt",
                description: Text("Add your first item from the Add tab.")
            )

        case .loaded(let items):
            ClosetGrid(items: items)
                .refreshable { await model.load() }
        }
    }
}

struct ClosetGrid: View {
    let items: [Item]

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        ItemCell(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ClosetView()
}
