//
//  APIClient.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import Foundation

enum APIError: LocalizedError {
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code):
            return "The server returned an error (status \(code))."
        }
    }
}

struct APIClient {
    let baseURL: URL

    func listItems() async throws -> [Item] {
        let url = baseURL
            .appending(path: "items")
            .appending(queryItems: [URLQueryItem(name: "limit", value: "200")])
        return try await get(url)
    }

    // MARK: - Helpers

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.badStatus(http.statusCode)
        }
        return try Self.makeDecoder().decode(T.self, from: data)
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase   // style_tags → styleTags
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) { return date }

            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unrecognized date: \(string)"
            )
        }
        return decoder
    }
}
