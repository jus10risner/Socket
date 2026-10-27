import CoreData
import Foundation

enum RepairCategoryMaintenance {
    static func comparisonKey(for name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    static func visibleCategories(from categories: [RepairCategory]) -> [RepairCategory] {
        let active = categories.filter { !$0.isArchived && !$0.isDeleted }
        let groups = Dictionary(grouping: active) { comparisonKey(for: $0.name) }
        return groups.values.compactMap { group in
            group.min { ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "") }
        }.sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            if order != .orderedSame { return order == .orderedAscending }
            return ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "")
        }
    }

    static func rename(_ category: RepairCategory, to name: String, in context: NSManagedObjectContext) throws -> RepairCategory {
        let key = comparisonKey(for: category.name)
        let categories = try context.fetch(RepairCategory.fetchRequest())
        // Rename archived copies too, so cleanup cannot bring the old name back.
        for copy in categories where comparisonKey(for: copy.name) == key {
            copy.name = name
        }
        try reconcile(in: context, seedIfEmpty: false)
        return visibleCategories(from: categories).first {
            comparisonKey(for: $0.name) == comparisonKey(for: name)
        } ?? category
    }

    static func archive(_ category: RepairCategory, in context: NSManagedObjectContext) throws {
        let key = comparisonKey(for: category.name)
        for copy in try context.fetch(RepairCategory.fetchRequest())
        where comparisonKey(for: copy.name) == key {
            for repair in copy.repairs as? Set<Repair> ?? [] {
                repair.category = nil
            }
            copy.isArchived = true
        }
    }

    // Run on the supplied context's queue. Archived records count as existing
    // categories so deleting all categories does not seed them again.
    static func reconcile(in context: NSManagedObjectContext, seedIfEmpty: Bool) throws {
        var categories = try context.fetch(RepairCategory.fetchRequest())
        if categories.isEmpty && seedIfEmpty {
            for name in [
                String(localized: "Engine"), String(localized: "Suspension"),
                String(localized: "Brakes"), String(localized: "Electrical"),
                String(localized: "Tires & Wheels"), String(localized: "Body")
            ] {
                let category = RepairCategory(context: context)
                category.id = UUID()
                category.name = name
                categories.append(category)
            }
        }

        for category in categories where category.id == nil {
            category.id = UUID()
        }
        try context.obtainPermanentIDs(for: categories.filter { $0.objectID.isTemporaryID })

        let groups = Dictionary(grouping: categories) { comparisonKey(for: $0.name) }
        for (key, duplicates) in groups where !key.isEmpty && duplicates.count > 1 {
            // UUIDs are synced; local object-ID ordering alone can differ by device.
            let sorted = duplicates.sorted {
                let left = $0.id?.uuidString ?? ""
                let right = $1.id?.uuidString ?? ""
                if left != right { return left < right }
                return $0.objectID.uriRepresentation().absoluteString
                    < $1.objectID.uriRepresentation().absoluteString
            }
            guard let canonical = sorted.first else { continue }
            let allArchived = duplicates.allSatisfy(\.isArchived)
            if canonical.isArchived != allArchived {
                canonical.isArchived = allArchived
            }

            for duplicate in sorted.dropFirst() {
                for repair in duplicate.repairs as? Set<Repair> ?? [] {
                    repair.category = canonical
                }
                if !duplicate.isArchived {
                    duplicate.isArchived = true
                }
            }
        }
        // Keep redundant records as archives: relationships arriving in later
        // CloudKit batches can still be redirected on the next pass.
    }
}
