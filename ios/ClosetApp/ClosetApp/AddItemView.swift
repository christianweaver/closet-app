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
    @Environment(ClosetModel.self) private var closet

    var body: some View {
        NavigationStack {
            Group {
                if case .confirm(let item) = model.phase {
                    // The editor is a full-screen Form with its own buttons.
                    TagEditorView(
                        item: item,
                        isSaving: model.isSaving,
                        onSave: { update in
                            Task {
                                await model.save(update, for: item)
                                if case .saved(let saved) = model.phase {
                                    closet.add(saved)
                                }
                            }
                        },
                        onDiscard: {
                            Task {
                                await model.discard(item)
                                selection = nil
                            }
                        }
                    )
                } else {
                    VStack(spacing: 16) {
                        content
                            .frame(maxHeight: .infinity)
                        buttons
                    }
                    .padding()
                }
            }
            .navigationTitle(title)
            .task(id: selection) {
                await model.loadPhoto(selection)
            }
            .alert("Something went wrong", isPresented: saveErrorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.saveError ?? "")
            }
        }
    }

    private var title: String {
        if case .confirm = model.phase { return "Review tags" }
        return "Add"
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { model.saveError != nil },
            set: { isPresented in
                if !isPresented { model.saveError = nil }
            }
        )
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

        case .saved(let item):
            ContentUnavailableView {
                Label("Added to your closet", systemImage: "checkmark.circle.fill")
            } description: {
                let category = item.category?.rawValue.capitalized ?? "Item"
                let colors = item.colors.joined(separator: ", ")
                Text(colors.isEmpty ? category : "\(category) · \(colors)")
            }

        case .failed(let message, _):
            ContentUnavailableView(
                "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )

        case .confirm:
            EmptyView()   // handled by TagEditorView in body
        }
    }

    // MARK: - Buttons

    @ViewBuilder
    private var buttons: some View {
        switch model.phase {
        case .working, .confirm:
            EmptyView()

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

        case .saved:
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
        .environment(ClosetModel())
}
