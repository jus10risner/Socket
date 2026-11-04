import Foundation

// Allows ActivityView to work with the .sheet(item:) modifier (requires a URL with Identifiable conformance)
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
