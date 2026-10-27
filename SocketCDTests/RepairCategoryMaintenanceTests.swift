import CoreData
import Testing
@testable import SocketCD

@MainActor
struct RepairCategoryMaintenanceTests {
    @Test func seedingIsGlobalAndRepeatable() throws {
        let controller = TestDataController()
        let context = controller.container.viewContext
        _ = Vehicle(context: context)
        _ = Vehicle(context: context)
        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: true)
        try context.save()
        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: true)
        #expect(try context.count(for: RepairCategory.fetchRequest()) == 6)
        #expect(!context.hasChanges)
    }

    @Test func mergesDuplicateAssignmentsAcrossVehicles() throws {
        let controller = TestDataController()
        let context = controller.container.viewContext
        let first = category("Engine", in: context)
        let second = category(" ENGINE ", in: context)
        let a = Repair(context: context)
        a.vehicle = Vehicle(context: context)
        a.category = first
        let b = Repair(context: context)
        b.vehicle = Vehicle(context: context)
        b.category = second
        try context.save()

        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: true)
        try context.save()
        let categories = try context.fetch(RepairCategory.fetchRequest())
        #expect(categories.count == 2)
        #expect(categories.filter { !$0.isArchived }.count == 1)
        #expect(a.category == b.category)
        #expect(a.category?.isArchived == false)
        #expect(try context.count(for: Repair.fetchRequest()) == 2)
        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: true)
        #expect(!context.hasChanges)
    }

    @Test func laterImportsAreReconciledAndLateRelationshipsPreserved() throws {
        let controller = TestDataController()
        let context = controller.container.viewContext
        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: true)
        try context.save()
        let original = try #require(context.fetch(RepairCategory.fetchRequest()).first)
        let duplicate = category(original.name, in: context)
        try context.save()
        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: false)
        try context.save()
        let archived = try #require(context.fetch(RepairCategory.fetchRequest()).first { $0.isArchived })
        let lateRepair = Repair(context: context)
        lateRepair.category = archived
        try context.save()
        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: false)
        try context.save()
        #expect(lateRepair.category?.isArchived == false)
        #expect(try context.fetch(RepairCategory.fetchRequest()).filter { !$0.isArchived }.count == 6)
        #expect(!duplicate.isDeleted)
    }

    @Test func archivedCategoriesStayArchivedAndAreNotReseeded() throws {
        let controller = TestDataController()
        let context = controller.container.viewContext
        let first = category("Brakes", in: context)
        first.isArchived = true
        let second = category("brakes", in: context)
        second.isArchived = true
        try context.save()
        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: true)
        try context.save()
        let categories = try context.fetch(RepairCategory.fetchRequest())
        #expect(categories.count == 2)
        #expect(categories.allSatisfy { $0.isArchived })
    }

    @Test func remoteChangeDoesNotSeedAnEmptyStore() throws {
        let controller = TestDataController()
        let context = controller.container.viewContext
        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: false)
        #expect(try context.count(for: RepairCategory.fetchRequest()) == 0)
    }

    @Test func pickerShowsOneRowBeforeReconciliation() throws {
        let controller = TestDataController()
        let context = controller.container.viewContext
        let engine = category("Engine", in: context)
        let duplicate = category(" ENGINE ", in: context)
        let brakes = category("Brakes", in: context)
        let archived = category("Body", in: context)
        archived.isArchived = true
        try context.save()
        let rows = RepairCategoryMaintenance.visibleCategories(from: [duplicate, archived, engine, brakes])
        let reversedRows = RepairCategoryMaintenance.visibleCategories(from: [brakes, engine, archived, duplicate])
        #expect(rows.count == 2)
        #expect(rows.map(\.objectID) == reversedRows.map(\.objectID))
        #expect(!context.hasChanges)
    }

    @Test func renamingDuplicatesIntoExistingCategoryPreservesRepairs() throws {
        let controller = TestDataController()
        let context = controller.container.viewContext
        let engine = category("Engine", in: context)
        let duplicate = category("engine", in: context)
        let oldArchive = category("ENGINE", in: context)
        oldArchive.isArchived = true
        let target = category("Powertrain", in: context)
        let repairs = [engine, duplicate, oldArchive, target].map { category in
            let repair = Repair(context: context)
            repair.category = category
            return repair
        }
        try context.save()
        let renamed = try RepairCategoryMaintenance.rename(engine, to: "Powertrain", in: context)
        try context.save()
        let rows = RepairCategoryMaintenance.visibleCategories(
            from: try context.fetch(RepairCategory.fetchRequest())
        )
        #expect(rows.count == 1)
        #expect(renamed.name == "Powertrain")
        #expect(repairs.allSatisfy { $0.category == renamed })
        #expect(oldArchive.name == "Powertrain")
    }

    @Test func deletionArchivesEveryDuplicateAndClearsAssignments() throws {
        let controller = TestDataController()
        let context = controller.container.viewContext
        let first = category("Engine", in: context)
        let second = category("engine", in: context)
        let repair = Repair(context: context)
        repair.category = second
        try context.save()
        try RepairCategoryMaintenance.archive(first, in: context)
        try context.save()
        try RepairCategoryMaintenance.reconcile(in: context, seedIfEmpty: true)
        let rows = RepairCategoryMaintenance.visibleCategories(
            from: try context.fetch(RepairCategory.fetchRequest())
        )
        #expect(rows.isEmpty)
        #expect(repair.category == nil)
        #expect(!repair.isDeleted)
    }

    private func category(_ name: String, in context: NSManagedObjectContext) -> RepairCategory {
        let category = RepairCategory(context: context)
        category.id = UUID()
        category.name = name
        return category
    }
}
