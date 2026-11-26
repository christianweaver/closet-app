//
//  ItemCell.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import SwiftUI

struct ItemCell: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ItemImage(url: item.imageUrl)
                .aspectRatio(1, contentMode: .fit)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(item.category?.rawValue.capitalized ?? "Unknown")
                .font(.caption.weight(.semibold))

            Text(item.colors.isEmpty ? " " : item.colors.joined(separator: ", "))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

struct ItemImage: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            case .failure:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            case .empty:
                if url == nil {
                    Image(systemName: "tshirt")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                } else {
                    ProgressView()
                }
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ItemCell(item: Item.samples[0])
        .frame(width: 140)
        .padding()
}
