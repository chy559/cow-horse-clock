import SwiftUI

extension Color {
    static let punchCream = Color(red: 1.0, green: 0.965, blue: 0.74)
    static let punchInk = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let punchCoral = Color(red: 1.0, green: 0.45, blue: 0.34)
    static let punchPaper = Color(red: 1.0, green: 0.995, blue: 0.95)
    static let punchMint = Color(red: 0.52, green: 0.91, blue: 0.70)
}

struct PunchCardModifier: ViewModifier {
    var fill: Color = .punchPaper
    var radius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.punchInk, lineWidth: 2)
            }
    }
}

private struct SoftPunchCardModifier: ViewModifier {
    var fill: Color = .punchPaper
    var radius: CGFloat = 18

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        content
            .background {
                shape.fill(
                    LinearGradient(
                        colors: [fill, fill.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .clipShape(shape)
            .overlay {
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.punchInk.opacity(0.9),
                            Color.punchInk.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            }
            .shadow(color: .punchInk.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

enum HoverLiftStyle: Equatable {
    case standard
    case compact

    var lift: CGFloat {
        self == .standard ? 5 : 3
    }

    var scale: CGFloat {
        self == .standard ? 1.015 : 1.01
    }

    var shadowOffset: CGFloat {
        self == .standard ? 5 : 3
    }
}

private struct HoverLiftModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    let style: HoverLiftStyle

    func body(content: Content) -> some View {
        let isActive = isHovered && isEnabled
        let activeShadow =
            isActive
            ? (reduceMotion ? style.shadowOffset * 0.6 : style.shadowOffset)
            : 0
        let hoverAnimation: Animation =
            reduceMotion
            ? .easeOut(duration: 0.1)
            : .spring(response: 0.18, dampingFraction: 0.76)

        content
            .offset(y: isActive && !reduceMotion ? -style.lift : 0)
            .scaleEffect(isActive && !reduceMotion ? style.scale : 1)
            .shadow(
                color: .punchInk.opacity(isActive ? 0.92 : 0),
                radius: 0,
                x: activeShadow,
                y: activeShadow
            )
            .zIndex(isActive ? 10 : 0)
            .animation(hoverAnimation, value: isActive)
            .onHover { isHovered = $0 }
    }
}

extension View {
    func punchCard(
        fill: Color = .punchPaper,
        radius: CGFloat = 14
    ) -> some View {
        modifier(PunchCardModifier(fill: fill, radius: radius))
    }

    func softPunchCard(
        fill: Color = .punchPaper,
        radius: CGFloat = 18
    ) -> some View {
        modifier(SoftPunchCardModifier(fill: fill, radius: radius))
    }

    func hoverLift(_ style: HoverLiftStyle = .standard) -> some View {
        modifier(HoverLiftModifier(style: style))
    }
}
