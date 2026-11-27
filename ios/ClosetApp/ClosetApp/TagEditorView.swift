//
//  TagEditorView.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import SwiftUI

struct TagEditorView: View {
    let item: Item
    let isSaving: Bool
    let onSave: (ItemUpdate) -> Void
    let onDiscard: () -> Void

    // Draft edits: start from the model's suggestions, then the user adjusts them.
    @State private var category: Category?
    @State private var colors: [String]
    @State private var styleTags: [String]

    init(
        item: Item,
        isSaving: Bool,
        onSave: @escaping (ItemUpdate) -> Void,
        onDiscard: @escaping () -> Void
    ) {
        self.item = item
        self.isSaving = isSaving
        self.onSave = onSave
        self.onDiscard = onDiscard
        _category = State(initialValue: item.category)
        _colors = State(initialValue: item.colors)
        _styleTags = State(initialValue: item.styleTags)
    }

    var body: some View {
        Form {
            Section {
                ItemImage(url: item.imageUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } footer: {
                Text("Check the tags below and fix anything that's off.")
            }

            Section("Category") {
                Picker("Category", selection: $category) {
                    Text("Unknown").tag(Category?.none)
                    ForEach(Category.allCases, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(Category?.some(option))
                    }
                }
            }

            Section("Colors") {
                ChipPicker(options: TagOptions.colors, selection: $colors)
            }

            Section("Style") {
                ChipPicker(options: TagOptions.styles, selection: $styleTags)
            }

            Section {
                Button {
                    onSave(ItemUpdate(category: category, colors: colors, styleTags: styleTags))
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save to closet").bold()
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving)

                Button("Discard item", role: .destructive, action: onDiscard)
                    .disabled(isSaving)
            }
        }
    }
}

struct ChipPicker: View {
    let options: [String]
    @Binding var selection: [String]

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(allOptions, id: \.self) { option in
                let isOn = selection.contains(option)
                Button {
                    toggle(option)
                } label: {
                    Text(option.capitalized)
                        .font(.subheadline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isOn ? Color.accentColor : Color(.secondarySystemBackground),
                                    in: Capsule())
                        .foregroundStyle(isOn ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    /// The standard options plus anything already selected that isn't in the list,
    /// so a tag from the backend is never silently dropped.
    private var allOptions: [String] {
        options + selection.filter { !options.contains($0) }
    }

    private func toggle(_ option: String) {
        if let index = selection.firstIndex(of: option) {
            selection.remove(at: index)
        } else {
            selection.append(option)
        }
    }
}

#Preview {
    TagEditorView(item: Item.samples[0], isSaving: false, onSave: { _ in }, onDiscard: {})
}
