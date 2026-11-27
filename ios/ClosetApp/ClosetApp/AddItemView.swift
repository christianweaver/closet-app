//
//  AddItemView.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import PhotosUI
import SwiftUI

struct AddItemView: View {
    @State private var model = AddItemModel()
    @State private var selection: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                content
                    .frame(maxHeight: .infinity)
                buttons
            }
            .padding()
            .navigationTitle("Add")
            .task(id: selection) {
                await model.loadPhoto(selection)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .empty:
            ContentUnavailableView(
                "Add an item",
                systemImage: "tshirt",
                description: Text("Choose a photo of one clothing item. Plain backgrounds work best.")
            )

        case .working(let message):
            ProgressView(message)

        case .preview(let prepared):
            VStack(spacing: 8) {
                Image(uiImage: prepared.image)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

                Text("Upload size: \(Int64(prepared.pngData.count).formatted(.byteCount(style: .file)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .confirm(let item):
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ItemImage(url: item.imageUrl)
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text(item.category?.rawValue.capitalized ?? "Unknown category")
                        .font(.title2.bold())

                    TagSection(title: "Colors", tags: item.colors)
                    TagSection(title: "Style", tags: item.styleTags)
                }
            }

        case .failed(let message, _):
            ContentUnavailableView(
                "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    // MARK: - Buttons

    @ViewBuilder
    private var buttons: some View {
        switch model.phase {
        case .working:
            EmptyView()   // no buttons while busy: nothing can interrupt an upload halfway

        case .preview(let prepared):
            primaryButton("Use this photo", systemImage: "arrow.up.circle") {
                Task { await model.upload(prepared) }
            }
            picker

        case .failed(_, let prepared?):
            primaryButton("Try again", systemImage: "arrow.clockwise") {
                Task { await model.upload(prepared) }
            }
            picker

        case .confirm:
            primaryButton("Add another item", systemImage: "plus") {
                selection = nil
                model.reset()
            }

        default:
            picker
        }
    }

    private var picker: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            Label(model.hasPhoto ? "Choose a different photo" : "Choose a photo",
                  systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private func primaryButton(
        _ title: String, systemImage: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

#Preview {
    AddItemView()
}
