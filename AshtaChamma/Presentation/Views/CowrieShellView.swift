
import SwiftUI

/// Single cowrie: **face up** = ventral side with slit (counts toward the roll); **face down** = speckled dorsal dome.
struct CowrieShellView: View {
    var faceUp: Bool
    /// When true, face changes apply instantly (rapid roll); when false, use a spring flip.
    var rolling: Bool
    var width: CGFloat = 30
    var height: CGFloat = 22

    @State private var flipAngle: Double = 0

    var body: some View {
        ZStack {
            dorsalSide
                .opacity(backOpacity)
                .rotation3DEffect(.degrees(flipAngle + 180), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
            ventralSide
                .opacity(frontOpacity)
                .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
        }
        .frame(width: width, height: height)
        .onAppear {
            flipAngle = faceUp ? 0 : 180
        }
        .onChange(of: faceUp) { _, new in
            if rolling {
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    flipAngle = new ? 0 : 180
                }
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                    flipAngle = new ? 0 : 180
                }
            }
        }
    }

    /// Ventral faces camera when flipAngle ≈ 0; dorsal when ≈ 180.
    private var frontOpacity: Double {
        max(0, cos(flipAngle * .pi / 180))
    }

    private var backOpacity: Double {
        max(0, cos((flipAngle + 180) * .pi / 180))
    }

    // MARK: - Dorsal (smooth speckled dome — “face down” in play)

    private var dorsalSide: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "5c3d28"),
                            Color(hex: "3a2318"),
                            Color(hex: "2a1810")
                        ],
                        center: .init(x: 0.35, y: 0.32),
                        startRadius: 2,
                        endRadius: max(width, height)
                    )
                )
            // Cream speckles (fixed pattern)
            ForEach(0..<22, id: \.self) { i in
                let pts = specklePoint(i)
                Circle()
                    .fill(Color(hex: "f5ead8").opacity(Double(0.22 + CGFloat(i % 5) * 0.04)))
                    .frame(width: CGFloat(1 + (i % 3)), height: CGFloat(1 + (i % 3)))
                    .position(x: pts.x * width, y: pts.y * height)
            }
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            Color.white.opacity(0)
                        ],
                        startPoint: .topLeading,
                        endPoint: UnitPoint(x: 0.5, y: 0.5)
                    )
                )
                .scaleEffect(x: 0.45, y: 0.35)
                .offset(x: -width * 0.12, y: -height * 0.18)
        }
        .clipShape(Ellipse())
        .overlay(
            Ellipse()
                .stroke(Color(hex: "1a0f0a").opacity(0.35), lineWidth: 0.8)
        )
    }

    private func specklePoint(_ i: Int) -> CGPoint {
        let a = Double(i) * 0.618033988749895
        let u = CGFloat(a.truncatingRemainder(dividingBy: 1))
        let v = CGFloat((a * 2.718).truncatingRemainder(dividingBy: 1))
        let dx = (u - 0.5) * 0.78
        let dy = (v - 0.5) * 0.62
        return CGPoint(x: 0.5 + dx, y: 0.48 + dy)
    }

    // MARK: - Ventral (slit + teeth — “face up” in play)

    private var ventralSide: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "f2e6d4"),
                            Color(hex: "dcc8a8"),
                            Color(hex: "c4a882")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            // Longitudinal slit
            Capsule()
                .fill(Color(hex: "1a120c").opacity(0.88))
                .frame(width: width * 0.1, height: height * 0.62)
            // Inner slit highlight
            Capsule()
                .fill(Color(hex: "2a1810").opacity(0.5))
                .frame(width: width * 0.04, height: height * 0.48)
            // Serrated “teeth” along slit edges
            slitTeeth
            Ellipse()
                .stroke(Color(hex: "6b5038").opacity(0.45), lineWidth: 0.9)
        }
        .clipShape(Ellipse())
    }

    private var slitTeeth: some View {
        let count = 7
        let slitH = height * 0.62
        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                let t = CGFloat(i) / CGFloat(count - 1)
                let y = (t - 0.5) * slitH * 0.88
                HStack(spacing: width * 0.07) {
                    toothDot
                    toothDot
                }
                .offset(y: y)
            }
        }
    }

    private var toothDot: some View {
        RoundedRectangle(cornerRadius: 0.5)
            .fill(Color(hex: "faf6f0").opacity(0.95))
            .frame(width: 1.4, height: 2.2)
    }
}

/// Row of four cowries bound to face-up flags from the view model.
struct CowrieShellRow: View {
    let faceUp: [Bool]
    let rolling: Bool
    var shellWidth: CGFloat = 28
    var shellHeight: CGFloat = 20
    var shellSpacing: CGFloat = 6

    var body: some View {
        HStack(spacing: shellSpacing) {
            ForEach(0..<4, id: \.self) { i in
                CowrieShellView(
                    faceUp: i < faceUp.count ? faceUp[i] : false,
                    rolling: rolling,
                    width: shellWidth,
                    height: shellHeight
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CowrieShellRow(faceUp: [true, false, true, false], rolling: false)
        CowrieShellRow(faceUp: [false, false, false, false], rolling: false)
        CowrieShellRow(faceUp: [true, true, true, true], rolling: false)
    }
    .padding()
    .background(Color(hex: "14100a"))
}
