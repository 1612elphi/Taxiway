import SwiftUI
import TaxiwayCore

struct ProfileEditorView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(\.dismiss) var dismiss

    @State private var editedProfile: PreflightProfile?
    @State private var editedChecks: [String: CheckEntry] = [:]
    @State private var selectedCategory: CheckCategory? = .file
    @State private var selectedTypeID: String?
    @State private var saveError: String?

    private var isBuiltIn: Bool {
        editedProfile?.origin == .builtIn
    }

    var body: some View {
        Group {
            if editedProfile != nil {
                editorContent()
            } else {
                ContentUnavailableView("No Profile Selected", systemImage: "doc.questionmark")
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onAppear {
            editedProfile = coordinator.editingProfile
            populateChecks()
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

    // MARK: - Editor Content

    @ViewBuilder
    private func editorContent() -> some View {
        VStack(spacing: 0) {
            titleBar()
            Divider()
            NavigationSplitView {
                categoryList()
                    .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
            } content: {
                checkList()
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            } detail: {
                detailPane()
            }
            .navigationSplitViewStyle(.balanced)
        }
    }

    // MARK: - Title Bar

    @ViewBuilder
    private func titleBar() -> some View {
        HStack {
            if isBuiltIn {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .font(TaxiwayTheme.monoSmall)
                Text(editedProfile?.name ?? "Profile")
                    .font(TaxiwayTheme.monoTitle)
            } else {
                TextField("Profile Name", text: Binding(
                    get: { editedProfile?.name ?? "" },
                    set: { editedProfile?.name = $0 }
                ))
                .font(TaxiwayTheme.monoTitle)
                .textFieldStyle(.plain)
            }
            Spacer()
            if isBuiltIn {
                Button("Duplicate") {
                    duplicateProfile()
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            Button("Save") {
                saveProfile()
            }
            .disabled(isBuiltIn)
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, TaxiwayTheme.panelPadding)
        .padding(.vertical, 10)
    }

    // MARK: - Category List (Left Column)

    @ViewBuilder
    private func categoryList() -> some View {
        List(CheckCategory.allCases, id: \.self, selection: $selectedCategory) { category in
            let counts = checkCounts(for: category)
            HStack {
                Text(categoryLabel(category))
                    .font(TaxiwayTheme.monoFont)
                Spacer()
                Text("\(counts.active)/\(counts.total)")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
            }
            .tag(category)
        }
        .listStyle(.sidebar)
        .onChange(of: selectedCategory) { _, _ in
            selectedTypeID = nil
        }
    }

    // MARK: - Check List (Middle Column)

    @ViewBuilder
    private func checkList() -> some View {
        if let category = selectedCategory {
            let typeIDs = CheckMetadata.typeIDs(for: category)
            List(typeIDs, id: \.self, selection: $selectedTypeID) { typeID in
                HStack(spacing: 8) {
                    Circle()
                        .fill(stateColor(for: typeID))
                        .frame(width: 8, height: 8)
                    Text(CheckMetadata.displayName(for: typeID))
                        .font(TaxiwayTheme.monoSmall)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        cycleState(for: typeID)
                    } label: {
                        Text(stateLabel(for: typeID))
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(stateColor(for: typeID)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isBuiltIn)
                }
                .tag(typeID)
            }
            .listStyle(.plain)
        } else {
            ContentUnavailableView("Select a Category", systemImage: "sidebar.left")
        }
    }

    private func cycleState(for typeID: String) {
        guard var entry = editedChecks[typeID] else { return }
        let state = CheckDetailView.checkState(of: entry)
        switch state {
        case .ignore:
            entry.enabled = true
            entry.severityOverride = .warning
        case .warn:
            entry.enabled = true
            entry.severityOverride = .error
        case .fault:
            entry.enabled = false
        }
        editedChecks[typeID] = entry
    }

    // MARK: - Detail Pane (Right Column)

    @ViewBuilder
    private func detailPane() -> some View {
        if let typeID = selectedTypeID, editedChecks[typeID] != nil {
            CheckDetailView(
                entry: Binding(
                    get: {
                        editedChecks[typeID] ?? CheckMetadata.defaultEntry(for: typeID)
                    },
                    set: { newValue in
                        editedChecks[typeID] = newValue
                    }
                ),
                readOnly: isBuiltIn
            )
        } else {
            ContentUnavailableView("Select a Check", systemImage: "checkmark.circle")
        }
    }

    // MARK: - Data Population

    private func populateChecks() {
        var checks: [String: CheckEntry] = [:]
        // Start with defaults for all known typeIDs
        for category in CheckCategory.allCases {
            for typeID in CheckMetadata.typeIDs(for: category) {
                checks[typeID] = CheckMetadata.defaultEntry(for: typeID)
            }
        }
        // Overlay with profile's existing checks
        if let profile = editedProfile {
            for entry in profile.checks {
                checks[entry.typeID] = entry
            }
        }
        editedChecks = checks
    }

    // MARK: - Helpers

    private func checkCounts(for category: CheckCategory) -> (active: Int, total: Int) {
        let typeIDs = CheckMetadata.typeIDs(for: category)
        let active = typeIDs.filter { editedChecks[$0]?.enabled == true }.count
        return (active, typeIDs.count)
    }

    private func stateColor(for typeID: String) -> Color {
        guard let entry = editedChecks[typeID] else { return .green }
        if !entry.enabled { return .green }
        switch entry.severityOverride {
        case .error: return TaxiwayTheme.statusError
        case .warning, .info, nil: return TaxiwayTheme.statusWarning
        }
    }

    private func stateLabel(for typeID: String) -> String {
        guard let entry = editedChecks[typeID] else { return "IGNORE" }
        if !entry.enabled { return "IGNORE" }
        switch entry.severityOverride {
        case .error: return "FAULT"
        case .warning, .info, nil: return "WARN"
        }
    }

    private func categoryLabel(_ category: CheckCategory) -> String {
        switch category {
        case .file: "File"
        case .pdf: "PDF"
        case .pages: "Pages"
        case .marks: "Marks"
        case .colour: "Colour"
        case .fonts: "Fonts"
        case .images: "Images"
        case .lines: "Lines"
        }
    }

    // MARK: - Actions

    private func duplicateProfile() {
        guard let original = editedProfile else { return }
        var copy = original.duplicate(name: "Copy of \(original.name)")
        copy = PreflightProfile(
            name: copy.name,
            description: copy.description,
            origin: .user,
            checks: Array(editedChecks.values)
        )
        do {
            try ProfileStorage().save(copy)
            editedProfile = copy
            coordinator.editingProfile = copy
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func saveProfile() {
        guard var profile = editedProfile else { return }
        profile = PreflightProfile(
            id: profile.id,
            name: profile.name,
            description: profile.description,
            origin: .user,
            checks: Array(editedChecks.values)
        )
        do {
            try ProfileStorage().save(profile)
            coordinator.selectedProfile = profile
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
