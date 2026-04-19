import SwiftUI

struct OpeningView: View {
    @State private var navigateToHome = false

    var body: some View {
        ZStack {
            // Ambient background
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "4a3428"),
                            Color(hex: "2e2218"),
                            Color(hex: "221810")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [
                            Color(hex: "c9a060").opacity(0.38),
                            Color(hex: "8b6238").opacity(0.22),
                            Color(hex: "5c4028").opacity(0.08),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.0),
                        startRadius: 30,
                        endRadius: max(w, geo.size.height) * 0.62
                    )
                    RadialGradient(
                        colors: [
                            Color(hex: "e8b878").opacity(0.18),
                            Color(hex: "a07040").opacity(0.08),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.88, y: 0.92),
                        startRadius: 40,
                        endRadius: w * 0.7
                    )
                    LinearGradient(
                        colors: [
                            Color(hex: "1a1008").opacity(0),
                            Color(hex: "1a0c06").opacity(0.35)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Game title with gradient
                    VStack(spacing: 12) {
                        Text("Ashta Chamma")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "ffe8a0"),
                                        Color(hex: "e8b830"),
                                        Color(hex: "c89420")
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(hex: "5c4010").opacity(0.55), radius: 0, x: 0, y: 2)

                        Text("Traditional South Indian Board Game")
                            .font(.system(size: 14, weight: .medium))
                            .tracking(0.5)
                            .foregroundColor(Color(hex: "d4b090"))

                        Text("4 Players")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "c9a070"))
                    }

                    // Decorative divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "f0c878").opacity(0),
                                    Color(hex: "f5d090").opacity(0.55),
                                    Color(hex: "e8b860").opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                }
                .padding(.horizontal, 30)

                Spacer()

                // Tap to continue button
                VStack(spacing: 16) {
                    NavigationLink(destination: SignUpView().navigationBarBackButtonHidden(true)) {
                        VStack(spacing: 8) {
                            Text("Tap to Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "2a1810"))
                                .tracking(0.3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: "e8b848"),
                                    Color(hex: "f5d078"),
                                    Color(hex: "d49838")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(hex: "3d2010").opacity(0.45), radius: 8, x: 0, y: 4)
                    }

                    Text("Made with ♡ in India")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(hex: "b8956a").opacity(0.7))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        OpeningView()
    }
}
