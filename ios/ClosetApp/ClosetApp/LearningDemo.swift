import SwiftUI

struct CounterDemo: View {
    @State private var count = 0            // CounterDemo OWNS this data

    var body: some View {
        VStack(spacing: 20) {
            Text("Tapped \(count) times")
                .font(.title2)

            Button("Tap me") {
                count += 1                   // change the data, not the screen
            }
            .buttonStyle(.borderedProminent)

            CountBadge(count: count)         // data flows DOWN (read-only)
            ResetButton(count: $count)       // a binding lets the child change it

            Divider()

            Text("A").padding().background(.yellow)
            Text("B").background(.yellow).padding()
        }
        .padding()
    }
}

struct CountBadge: View {
    let count: Int                           // a plain value: like a React prop

    var body: some View {
        Text("\(count)")
            .padding(10)
            .background(.blue.opacity(0.2), in: Capsule())
    }
}

struct ResetButton: View {
    @Binding var count: Int                  // a two-way connection to the parent's @State

    var body: some View {
        Button("Reset") {
            count = 0                        // writes back to CounterDemo's count
        }
    }
}

#Preview {
    CounterDemo()
}
