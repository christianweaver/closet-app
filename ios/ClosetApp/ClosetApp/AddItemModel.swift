//
//  AddItemModel.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class AddItemModel {
    enum Phase {
        case empty
        case working(String)
        case preview(UploadImage.Prepared)
        case confirm(Item)
        case saved(Item)
        case failed(message: String, retry: UploadImage.Prepared?)
    }

    enum Failure: LocalizedError {
        case photoUnreadable
        case taggingFailed
        case timedOut

        var errorDescription: String? {
            switch self {
            case .photoUnreadable:
                return "This photo couldn't be loaded."
            case .taggingFailed:
                return "The server couldn't tag this item. Try again, or use a different photo."
            case .timedOut:
                return "Tagging is taking longer than expected. Check your closet in a minute."
            }
        }
    }

    private(set) var phase: Phase = .empty
    private(set) var isSaving = false
    var saveError: String?

    private let api: APIClient

    init(api: APIClient = APIClient(baseURL: AppConfig.apiBaseURL)) {
        self.api = api
    }

    var hasPhoto: Bool {
        if case .empty = phase { return false }
        return true
    }

    func reset() {
        phase = .empty
    }

    // MARK: - Photo → cutout → prepared PNG (on the phone)

    func loadPhoto(_ selection: PhotosPickerItem?) async {
        guard let selection else { return }
        phase = .working("Loading photo…")

        do {
            guard let data = try await selection.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw Failure.photoUnreadable
            }

            phase = .working("Removing background…")
            let cutout = try await BackgroundRemover.removeBackground(from: image)
            try Task.checkCancellation()

            phase = .working("Preparing image…")
            let prepared = try await UploadImage.prepare(cutout)
            try Task.checkCancellation()

            phase = .preview(prepared)
        } catch is CancellationError {
            // A newer selection took over.
        } catch {
            phase = .failed(message: error.localizedDescription, retry: nil)
        }
    }

    // MARK: - Upload → process → poll (phone ↔ API ↔ storage)

    func upload(_ prepared: UploadImage.Prepared) async {
        do {
            phase = .working("Uploading…")
            let ticket = try await api.requestUploadURL(contentType: "image/png")
            try await api.uploadImage(prepared.pngData, to: ticket.uploadUrl, contentType: "image/png")

            phase = .working("Tagging your item…")
            _ = try await api.startProcessing(id: ticket.item.id)
            let item = try await waitUntilProcessed(ticket.item.id)

            guard item.status == .ready else { throw Failure.taggingFailed }
            phase = .confirm(item)
        } catch is CancellationError {
            // The screen went away.
        } catch {
            phase = .failed(message: error.localizedDescription, retry: prepared)
        }
    }

    private func waitUntilProcessed(_ id: UUID) async throws -> Item {
        for _ in 0..<60 {
            let item = try await api.getItem(id: id)
            if item.status == .ready || item.status == .failed {
                return item
            }
            try await Task.sleep(for: .seconds(1))
        }
        throw Failure.timedOut
    }

    // MARK: - Confirm: save corrections, or discard

    func save(_ update: ItemUpdate, for item: Item) async {
        isSaving = true
        defer { isSaving = false }
        do {
            let updated = try await api.updateItem(id: item.id, update)
            phase = .saved(updated)
        } catch {
            saveError = error.localizedDescription   // stay on the editor; edits aren't lost
        }
    }

    func discard(_ item: Item) async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await api.deleteItem(id: item.id)
            phase = .empty
        } catch {
            saveError = error.localizedDescription
        }
    }
}
