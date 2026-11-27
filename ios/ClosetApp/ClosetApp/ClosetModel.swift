//
//  ClosetModel.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ClosetModel {
    enum State {
        case loading
        case loaded([Item])
        case failed(String)
    }

    private(set) var state: State = .loading
    private let api: APIClient

    init(api: APIClient = APIClient(baseURL: AppConfig.apiBaseURL)) {
        self.api = api
    }

    func load() async {
        do {
            let items = try await api.listItems()
            state = .loaded(items)
        } catch is CancellationError {
            // The screen went away before loading finished; nothing to show.
        } catch let error as URLError where error.code == .cancelled {
            // Same, for a cancelled network request.
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
    
    /// Insert an item the server just confirmed, without refetching the whole list.
    func add(_ item: Item) {
        guard case .loaded(let items) = state else { return }
        state = .loaded([item] + items.filter { $0.id != item.id })
    }
}
