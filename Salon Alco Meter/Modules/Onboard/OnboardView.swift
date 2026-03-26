import SwiftUI

struct OnboardView: View {
    var onEnd: () -> Void
    var isSE: Bool { UIScreen.isIphoneSEClassic }

    var body: some View {
        VStack {
            Button(action: { onEnd() }) {
                Image(.onboard)
                    .resizable().scaledToFit().padding()
            }
        }
        .bg()
    }
}
