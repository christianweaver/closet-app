//
//  ClosetView.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import SwiftUI

struct ClosetView: View {
    
    private let items = Item.samples
    
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No items yet",
                        systemImage: "tshirt",
                        description: Text("Add your first item from the Add tab.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(items) { item in
                                ItemCell(item: item)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Closet")
        }
    }
}

#Preview {
    ClosetView()
}
