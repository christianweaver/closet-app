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

struct UploadURLRequest: Encodable {
    let contentType: String
}

struct UploadURLResponse: Decodable {
    let item: Item
    let uploadUrl: URL
    let expiresIn: Int
}

struct APIClient {
    let baseURL: URL

    // MARK: - Items

    func listItems() async throws -> [Item] {
        let url = baseURL
            .appending(path: "items")
            .appending(queryItems: [URLQueryItem(name: "limit", value: "200")])
        return try await send("GET", url)
    }

    func getItem(id: UUID) async throws -> Item {
        try await send("GET", itemURL(id))
    }

    func similarItems(to id: UUID, limit: Int = 10) async throws -> [SimilarItem] {
        let url = itemURL(id)
            .appending(path: "similar")
            .appending(queryItems: [URLQueryItem(name: "limit", value: String(limit))])
        return try await send("GET", url)
    }

    // MARK: - Add-item flow

    func requestUploadURL(contentType: String) async throws -> UploadURLResponse {
        try await send("POST", baseURL.appending(path: "items/upload-url"),
                       body: UploadURLRequest(contentType: contentType))
    }

    /// PUTs the image directly to storage using a presigned URL (not through our API).
    func uploadImage(_ data: Data, to url: URL, contentType: String) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        try Self.check(response)
    }

    func startProcessing(id: UUID) async throws -> Item {
        try await send("POST", itemURL(id).appending(path: "process"))
    }

    // MARK: - Helpers

    private func itemURL(_ id: UUID) -> URL {
        baseURL.appending(path: "items/\(id.uuidString.lowercased())")
    }

    private func send<Response: Decodable>(_ method: String, _ url: URL) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = method
        return try await perform(request)
    }

    private func send<Response: Decodable, Body: Encodable>(
        _ method: String, _ url: URL, body: Body
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.makeEncoder().encode(body)
        return try await perform(request)
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.check(response)
        return try Self.makeDecoder().decode(Response.self, from: data)
    }

    private static func check(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.badStatus(http.statusCode)
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase   // contentType → content_type
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
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
