//
//  BackgroundRemover.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import CoreImage
import UIKit
import Vision

enum BackgroundRemover {
    enum Failure: LocalizedError {
        case unreadableImage
        case noSubjectFound
        case renderFailed

        var errorDescription: String? {
            switch self {
            case .unreadableImage:
                return "This photo couldn't be read."
            case .noSubjectFound:
                return "Couldn't find a clothing item in this photo. Try laying it flat on a plain surface."
            case .renderFailed:
                return "Something went wrong while cutting out the item."
            }
        }
    }

    /// Runs Vision on a background thread and returns a transparent cutout.
    static func removeBackground(from image: UIImage) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            try BackgroundRemover.cutOut(image)
        }.value
    }

    nonisolated private static func cutOut(_ image: UIImage) throws -> UIImage {
        let upright = uprightAndScaled(image, maxDimension: 2048)
        guard let cgImage = upright.cgImage else { throw Failure.unreadableImage }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        guard let observation = request.results?.first,
              !observation.allInstances.isEmpty else {
            throw Failure.noSubjectFound
        }

        let maskedBuffer = try observation.generateMaskedImage(
            ofInstances: observation.allInstances,
            from: handler,
            croppedToInstancesExtent: true
        )

        let ciImage = CIImage(cvPixelBuffer: maskedBuffer)
        guard let output = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            throw Failure.renderFailed
        }
        return UIImage(cgImage: output)
    }

    /// Redraws an image upright (applying its orientation) and no larger than maxDimension.
    nonisolated static func uprightAndScaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / longest)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
