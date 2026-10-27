//
//  AddEditRepairView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import CoreData
import SwiftUI

struct AddEditRepairView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @StateObject var draftRepair = DraftRepair()
    @FocusState var isInputActive: Bool
    @State private var showingDeleteAlert = false
    @State private var odometerWarning: OdometerWarning?
    
    // MARK: - Input
    private let vehicle: Vehicle?
    private let repair: Repair?
    private let onDelete: (() -> Void)?
    
    // MARK: - Init
    init(vehicle: Vehicle? = nil, repair: Repair? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.repair = repair
        self.onDelete = onDelete
        
        _draftRepair = StateObject(wrappedValue: DraftRepair(repair: repair))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                FormHeaderView(symbolName: AppSection.repairs.symbol(filled: true), primaryText: repair != nil ? "Edit Repair" : "New Repair", accentColor: AppSection.repairs.color)
                
                Section {
                    DatePicker("Date", selection: $draftRepair.date, displayedComponents: .date)
                        .foregroundStyle(Color.secondary)
                    
                    LabeledInput(label: "Name") {
                        TextField("Required", text: $draftRepair.name)
                            .textInputAutocapitalization(.words)
                            .focused($isInputActive)
                    }
                    
                    LabeledInput(label: "Odometer") {
                        TextField("Required", value: $draftRepair.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.numberPad)
                    }
                    
                    LabeledInput(label: "Cost") {
                        TextField("Optional", value: $draftRepair.cost, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.decimalPad)
                    }
                    
                    NavigationLink {
                        RepairCategorySelectionView(selection: $draftRepair.category)
                    } label: {
                        LabeledInput(label: "Category") {
                            Text(draftRepair.category?.name ?? "Optional")
                                .foregroundStyle(draftRepair.category == nil ? .tertiary : .primary)
                        }
                    }
                }
                
                FormFooterView (
                    note: $draftRepair.note,
                    photos: $draftRepair.photos,
                    documents: $draftRepair.documents,
                    deleteButtonTitle: "Delete Repair",
                    onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if repair == nil {
                    // Show keyboard automatically, when adding a new repair
                    DispatchQueue.main.async {
                        isInputActive = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(repair != nil ? "Done" : "Add", systemImage: "checkmark") {
                        saveRepair()
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftRepair.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }
            }
        }
        .tint(AppSection.repairs.color)
        .alert("Delete Repair", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let repair {
                    DataController.shared.delete(repair)
                }

                dismiss()
                onDelete?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Permanently delete this repair record? This cannot be undone.")
        }
        .odometerWarningAlert(
            warning: $odometerWarning,
            entered: draftRepair.odometer,
            current: comparisonVehicle?.odometer,
            distanceUnit: comparisonVehicle?.distanceUnit.abbreviated ?? AppSettingsStore.shared.distanceUnit.abbreviated,
            onConfirm: performRepairSave
        )
        .tint(nil)
    }

    private var comparisonVehicle: Vehicle? {
        vehicle ?? repair?.vehicle
    }

    private func saveRepair() {
        if let entered = draftRepair.odometer, let comparisonVehicle,
           let warning = OdometerValidator.warning(
               entered: entered,
               current: comparisonVehicle.odometer,
               context: .historicalRecord
           ) {
            odometerWarning = warning
            return
        }

        performRepairSave()
    }

    private func performRepairSave() {
        if let repair {
            repair.updateAndSave(draftRepair: draftRepair)
        } else if let vehicle {
            vehicle.addNewRepair(draftRepair: draftRepair)
        }

        dismiss()
    }
}

private struct RepairCategorySelectionView: View {
    @Environment(\.managedObjectContext) private var context
    @Binding private var selection: RepairCategory?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RepairCategory.name_, ascending: true)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var categories: FetchedResults<RepairCategory>

    @State private var showingNewCategoryAlert = false
    @State private var newCategoryName = ""
    @State private var showingRenameAlert = false
    @State private var categoryToRename: RepairCategory?
    @State private var renamedCategory = ""
    @State private var showingDeleteConfirmation = false
    @State private var categoryToDelete: RepairCategory?

    init(selection: Binding<RepairCategory?>) {
        self._selection = selection
    }

    private var visibleCategories: [RepairCategory] {
        RepairCategoryMaintenance.visibleCategories(from: Array(categories))
    }

    var body: some View {
        List {
            Section {
                ForEach(visibleCategories, id: \.objectID) { category in
                Button {
                    selection = isSelected(category) ? nil : category
                } label: {
                    LabeledContent(category.name) {
                        if isSelected(category) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppSection.repairs.color)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .imageScale(.large)
                    .foregroundStyle(Color.primary)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash") {
                        categoryToDelete = category
                        showingDeleteConfirmation = true
                    }
                    .tint(.red)
                }
                .swipeActions(edge: .leading) {
                    Button("Rename", systemImage: "pencil") {
                        categoryToRename = category
                        renamedCategory = category.name
                        showingRenameAlert = true
                    }
                    .tint(AppSection.repairs.color)
                }
                }
            } footer: {
                Text("Use categories to organize repairs and group them in the repairs list.")
            }
        }
        .navigationTitle("Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Category", systemImage: "plus") {
                    newCategoryName = ""
                    showingNewCategoryAlert = true
                }
            }
        }
        .alert("New Category", isPresented: $showingNewCategoryAlert) {
            TextField("Category Name", text: $newCategoryName)
                .textInputAutocapitalization(.words)

            Button("Add") {
                addCategory()
            }
            .disabled(newCategoryName.isBlank)

            Button("Cancel", role: .cancel) {
                newCategoryName = ""
            }
        }
        .alert("Rename Category", isPresented: $showingRenameAlert) {
            TextField("Category Name", text: $renamedCategory)
                .textInputAutocapitalization(.words)

            Button("Rename") {
                renameCategory()
            }
            .disabled(renamedCategory.isBlank)

            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog(
            "Delete Category?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteCategory()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Repairs in this category will become uncategorized.")
        }
        .tint(nil)
    }

    private func addCategory() {
        let name = normalized(newCategoryName)

        withAnimation {
            if let existingCategory = category(named: name) {
                existingCategory.isArchived = false
                selection = existingCategory
            } else {
                let category = RepairCategory(context: context)
                category.id = UUID()
                category.name = name
                selection = category
            }

            save()
        }
        newCategoryName = ""
    }

    private func renameCategory() {
        guard let categoryToRename else { return }
        let replacement = normalized(renamedCategory)

        let wasSelected = isSelected(categoryToRename)
        do {
            let category = try RepairCategoryMaintenance.rename(
                categoryToRename, to: replacement, in: context
            )
            if wasSelected { selection = category }
            save()
        } catch {
            print("Failed to rename category: \(error.localizedDescription)")
        }
        self.categoryToRename = nil
    }

    private func deleteCategory() {
        guard let categoryToDelete else { return }

        let wasSelected = isSelected(categoryToDelete)
        do {
            try withAnimation {
                try RepairCategoryMaintenance.archive(categoryToDelete, in: context)
                if wasSelected { selection = nil }
                save()
            }
        } catch {
            print("Failed to delete category: \(error.localizedDescription)")
        }
        self.categoryToDelete = nil
    }

    private func isSelected(_ category: RepairCategory) -> Bool {
        guard let selection else { return false }
        return comparisonKey(for: selection.name) == comparisonKey(for: category.name)
    }

    private func category(named name: String, excluding excludedCategory: RepairCategory? = nil) -> RepairCategory? {
        let request = RepairCategory.fetchRequest()
        guard let allCategories = try? context.fetch(request) else { return nil }

        return allCategories
            .filter { category in
                category.objectID != excludedCategory?.objectID
                    && comparisonKey(for: category.name) == comparisonKey(for: name)
            }
            .sorted {
                if $0.isArchived != $1.isArchived { return !$0.isArchived }
                return ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "")
            }
            .first
    }

    private func comparisonKey(for category: String) -> String {
        RepairCategoryMaintenance.comparisonKey(for: category)
    }

    private func normalized(_ category: String) -> String {
        category.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        try? context.save()
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    let repair = Repair(context: context)
    
    return AddEditRepairView(vehicle: vehicle, repair: repair)
}
