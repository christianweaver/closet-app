//
//  ItemDetailView.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import SwiftUI

struct ItemDetailView: View {
    let item: Item

    @State private var similar: SimilarState = .loading
    private let api = APIClient(baseURL: AppConfig.apiBaseURL)

    private enum SimilarState {
        case loading
        case loaded([SimilarItem])
        case unavailable
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ItemImage(url: item.imageUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                header

                TagSection(title: "Colors", tags: item.colors)
                TagSection(title: "Style", tags: item.styleTags)

                similarSection
            }
            .padding()
        }
        .navigationTitle(item.category?.rawValue.capitalized ?? "Item")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: item.id) {
            await loadSimilar()
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.category?.rawValue.capitalized ?? "Unknown category")
                .font(.title2.bold())

            Text("Added \(item.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if item.status != .ready {
                Label(item.status.rawValue.capitalized, systemImage: "hourglass")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private var similarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Similar items")
                .font(.headline)

            switch similar {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)

            case .unavailable:
                Text("Not available for this item yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            case .loaded(let results) where results.isEmpty:
                Text("No similar items in your closet yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            case .loaded(let results):
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(results) { result in
                            NavigationLink(value: result.item) {
                                ItemCell(item: result.item)
                                    .frame(width: 110)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Loading

    private func loadSimilar() async {
        guard item.status == .ready else {
            similar = .unavailable
            return
        }
        do {
            similar = .loaded(try await api.similarItems(to: item.id))
        } catch {
            similar = .unavailable
        }
    }
}

struct TagSection: View {
    let title: String
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            if tags.isEmpty {
                Text("None")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag.capitalized)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemBackground), in: Capsule())
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(item: Item.samples[0])
    }
}
