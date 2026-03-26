import SwiftUI
import SwiftData

@main
struct Salon_Alco_MeterApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    var body: some View {
        LoadingScreen()
            .preferredColorScheme(.light)
            .modelContainer(for: [
                SwimModel.self,
                UserModel.self
            ])
    }
}
