import SwiftUI

extension View {
    func bg() -> some View {
        self.background(
            Image(.bg)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        )
    }
}

