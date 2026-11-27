//
//  UploadImage.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import UIKit

enum UploadImage {
    static let maxDimension: CGFloat = 1024

    struct Prepared {
        let image: UIImage    // what we show in the preview
        let pngData: Data     // what we upload
    }

    enum Failure: LocalizedError {
        case encodingFailed

        var errorDescription: String? {
            "Couldn't prepare the image for upload."
        }
    }

    /// Shrinks the cutout and encodes it as PNG, on a background thread.
    static func prepare(_ cutout: UIImage) async throws -> Prepared {
        let maxDimension = Self.maxDimension
        let (image, data) = try await Task.detached(priority: .userInitiated) {
            let resized = BackgroundRemover.uprightAndScaled(cutout, maxDimension: maxDimension)
            guard let data = resized.pngData() else { throw Failure.encodingFailed }
            return (resized, data)
        }.value
        return Prepared(image: image, pngData: data)
    }
}
