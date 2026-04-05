import SwiftUI

struct HomeView: View {
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

                VStack(spacing: 20) {
                    Text("Game Mode")
                        .font(.system(size: 28, weight: .bold))
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
                        .padding(.bottom, 12)

                    // Classic mode button
                    NavigationLink(destination: GameScreen().navigationBarBackButtonHidden(true)) {
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "2a1810"))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Classic")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(hex: "2a1810"))
                                    Text("4 Player Traditional Game")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color(hex: "5a4428"))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "2a1810"))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .frame(maxWidth: .infinity)
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
                }
                .padding(.horizontal, 30)

                Spacer()

                // Back button
                NavigationLink(destination: OpeningView().navigationBarBackButtonHidden(true)) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "d4b090"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "d4b090").opacity(0.4), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
