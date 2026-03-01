import Foundation
import TaxiwayCore

@Observable
final class FixQueue {
    struct Item: Identifiable {
        let id: String
        let descriptor: FixDescriptor
        let addressedResults: [CheckResult]
    }

    private(set) var items: [Item] = []

    var count: Int { items.count }
    var isEmpty: Bool { items.isEmpty }

    var requiresGhostscript: Bool {
        items.contains { $0.descriptor.category == .ghostscript }
    }

    func toggleFix(_ descriptor: FixDescriptor, for results: [CheckResult]) {
        if let index = items.firstIndex(where: { $0.id == descriptor.id }) {
            items.remove(at: index)
        } else {
            items.append(Item(id: descriptor.id, descriptor: descriptor, addressedResults: results))
        }
    }

    func isQueued(_ descriptorID: String) -> Bool {
        items.contains { $0.id == descriptorID }
    }

    func removeFix(id: String) {
        items.removeAll { $0.id == id }
    }

    func clear() {
        items.removeAll()
    }
}
