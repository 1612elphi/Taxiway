import SwiftUI
import TaxiwayCore

struct ProfileEditorView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(\.dismiss) var dismiss

    @State private var editedProfile: PreflightProfile?
    @State private var saveError: String?

    private var isBuiltIn: Bool {
        editedProfile?.origin == .builtIn
    }

    var body: some View {
        Group {
            if let profile = Binding($editedProfile) {
                profileForm(profile: profile)
            } else {
                ContentUnavailableView("No Profile Selected", systemImage: "doc.questionmark")
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            editedProfile = coordinator.editingProfile
        }
    }

    // MARK: - Profile Form

    @ViewBuilder
    private func profileForm(profile: Binding<PreflightProfile>) -> some View {
        Form {
            Section("Profile") {
                TextField("Name", text: profile.name)
                    .disabled(isBuiltIn)
                TextField("Description", text: profile.description)
                    .disabled(isBuiltIn)
                if isBuiltIn {
                    Label("Built-in profiles are read-only.", systemImage: "lock.fill")
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Checks") {
                let grouped = groupedChecks(profile.wrappedValue.checks)
                ForEach(grouped.keys.sorted(), id: \.self) { category in
                    DisclosureGroup(category.capitalized) {
                        let indices = grouped[category] ?? []
                        ForEach(indices, id: \.self) { index in
                            checkRow(profile: profile, index: index)
                        }
                    }
                }
            }

            if isBuiltIn {
                Section {
                    Button("Duplicate Profile") {
                        duplicateProfile()
                    }
                    .help("Create an editable copy of this built-in profile.")
                }
            }
        }
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(isBuiltIn)
            }
        }
        .alert("Save Failed", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "Unknown error")
        }
    }

    // MARK: - Check Row

    @ViewBuilder
    private func checkRow(profile: Binding<PreflightProfile>, index: Int) -> some View {
        let entry = profile.wrappedValue.checks[index]
        HStack {
            Toggle(isOn: profile.checks[index].enabled) {
                Text(entry.typeID)
                    .font(TaxiwayTheme.monoSmall)
            }
            .disabled(isBuiltIn)

            Spacer()

            Picker("Severity", selection: profile.checks[index].severityOverride) {
                Text("Default").tag(CheckSeverity?.none)
                ForEach(CheckSeverity.allCases, id: \.self) { severity in
                    Text(severityLabel(severity)).tag(CheckSeverity?.some(severity))
                }
            }
            .labelsHidden()
            .frame(width: 100)
            .disabled(isBuiltIn)
        }
    }

    // MARK: - Helpers

    private func groupedChecks(_ checks: [CheckEntry]) -> [String: [Int]] {
        var result: [String: [Int]] = [:]
        for (index, check) in checks.enumerated() {
            let category = String(check.typeID.prefix(while: { $0 != "." }))
            result[category, default: []].append(index)
        }
        return result
    }

    private func severityLabel(_ severity: CheckSeverity) -> String {
        switch severity {
        case .error: "Error"
        case .warning: "Warning"
        case .info: "Info"
        }
    }

    private func duplicateProfile() {
        guard let original = editedProfile else { return }
        let copy = original.duplicate(name: "Copy of \(original.name)")
        do {
            try ProfileStorage().save(copy)
            editedProfile = copy
            coordinator.editingProfile = copy
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func saveProfile() {
        guard let profile = editedProfile else { return }
        do {
            try ProfileStorage().save(profile)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
