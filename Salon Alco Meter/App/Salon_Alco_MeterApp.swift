import SwiftUI
import SwiftData

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
