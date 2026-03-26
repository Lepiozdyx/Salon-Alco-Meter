//import SwiftUI
//
//struct WaveView: View {
//    var body: some View {
//        TimelineView(.animation) { timeline in
//            let now = timeline.date.timeIntervalSinceReferenceDate
//            let phase1 = CGFloat(now * 0.9)
//            let phase2 = CGFloat(now * 1.35)
//            ZStack {
//                WaveShape(amplitude: 14, waveLength: 180, phase: phase1)
//                    .stroke(Color.purple.opacity(0.62), lineWidth: 4)
//                    .frame(height: 46)
//                WaveShape(amplitude: 7, waveLength: 120, phase: -phase2)
//                    .stroke(Color.white.opacity(0.63), lineWidth: 2)
//                    .frame(height: 27)
//            }
//        }
//        .padding(.vertical, 18)
//    }
//}
//
//struct WaveShape: Shape {
//    var amplitude: CGFloat
//    var waveLength: CGFloat
//    var phase: CGFloat
//
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        let midHeight = rect.height / 2
//        let width = rect.width
//        path.move(to: .zero)
//        for x in stride(from: 0, to: width, by: 1) {
//            let relativeX = x / waveLength
//            let y = midHeight + sin(relativeX * 2 * .pi + phase) * amplitude
//            path.addLine(to: CGPoint(x: x, y: y))
//        }
//        path.addLine(to: CGPoint(x: width, y: rect.height))
//        path.addLine(to: CGPoint(x: 0, y: rect.height))
//        path.closeSubpath()
//        return path
//    }
//}
