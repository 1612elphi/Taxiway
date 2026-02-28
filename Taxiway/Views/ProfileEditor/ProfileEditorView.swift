import SwiftUI
import TaxiwayCore

struct ProfileEditorView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(\.dismiss) var dismiss

    @State private var editedProfile: PreflightProfile?
    @State private var selectedCategory: CheckCategory? = .file
    @State private var selectedCheckIndex: Int?
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
            }
            Text(editedProfile?.name ?? "Profile")
                .font(TaxiwayTheme.monoTitle)
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
                Text("\(counts.enabled)/\(counts.total)")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
            }
            .tag(category)
        }
        .listStyle(.sidebar)
        .onChange(of: selectedCategory) { _, _ in
            selectedCheckIndex = nil
        }
    }

    // MARK: - Check List (Middle Column)

    @ViewBuilder
    private func checkList() -> some View {
        if let category = selectedCategory, let profile = editedProfile {
            let indices = checksIndices(for: category, in: profile)
            List(indices, id: \.self, selection: $selectedCheckIndex) { index in
                let entry = profile.checks[index]
                HStack(spacing: 8) {
                    Circle()
                        .fill(severityColor(for: entry))
                        .frame(width: 8, height: 8)
                    Text(CheckMetadata.displayName(for: entry.typeID))
                        .font(TaxiwayTheme.monoSmall)
                        .lineLimit(1)
                    Spacer()
                    if !entry.enabled {
                        Text("OFF")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.secondary))
                    }
                }
                .tag(index)
            }
            .listStyle(.plain)
        } else {
            ContentUnavailableView("Select a Category", systemImage: "sidebar.left")
        }
    }

    // MARK: - Detail Pane (Right Column)

    @ViewBuilder
    private func detailPane() -> some View {
        if let index = selectedCheckIndex,
           let profile = editedProfile,
           index < profile.checks.count {
            CheckDetailView(
                entry: Binding(
                    get: {
                        guard let p = editedProfile, index < p.checks.count else {
                            return CheckEntry(typeID: "", enabled: false, parametersJSON: Data())
                        }
                        return p.checks[index]
                    },
                    set: { newValue in
                        editedProfile?.checks[index] = newValue
                    }
                ),
                readOnly: isBuiltIn
            )
        } else {
            ContentUnavailableView("Select a Check", systemImage: "checkmark.circle")
        }
    }

    // MARK: - Helpers

    private func checksIndices(for category: CheckCategory, in profile: PreflightProfile) -> [Int] {
        profile.checks.enumerated().compactMap { index, entry in
            CheckMetadata.category(for: entry.typeID) == category ? index : nil
        }
    }

    private func checkCounts(for category: CheckCategory) -> (enabled: Int, total: Int) {
        guard let profile = editedProfile else { return (0, 0) }
        let indices = checksIndices(for: category, in: profile)
        let enabled = indices.filter { profile.checks[$0].enabled }.count
        return (enabled, indices.count)
    }

    private func severityColor(for entry: CheckEntry) -> Color {
        let severity = entry.severityOverride ?? defaultSeverity(for: entry.typeID)
        switch severity {
        case .error: return TaxiwayTheme.statusError
        case .warning: return TaxiwayTheme.statusWarning
        case .info: return .blue
        }
    }

    private func defaultSeverity(for typeID: String) -> CheckSeverity {
        // Fallback — used only for the coloured dot
        .warning
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
