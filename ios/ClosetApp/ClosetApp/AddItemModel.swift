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

    // MARK: - Step 1: photo → cutout → prepared PNG (all on the phone)

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

    // MARK: - Step 2: upload → process → poll (phone ↔ API ↔ storage)

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
}
