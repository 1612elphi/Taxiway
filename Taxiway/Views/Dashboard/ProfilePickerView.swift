import SwiftUI
import TaxiwayCore

struct ProfilePickerView: View {
    @Environment(AppCoordinator.self) var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        Picker("Profile", selection: $coordinator.selectedProfile) {
            ForEach(PreflightProfile.allBuiltIn) { profile in
                Text(profile.name).tag(profile)
            }
        }
    }
}
