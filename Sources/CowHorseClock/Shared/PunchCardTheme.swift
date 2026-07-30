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
    @State private var isHovered = false

    let style: HoverLiftStyle

    func body(content: Content) -> some View {
        let activeShadow =
            isHovered
            ? (reduceMotion ? style.shadowOffset * 0.6 : style.shadowOffset)
            : 0
        let hoverAnimation: Animation =
            reduceMotion
            ? .easeOut(duration: 0.1)
            : .spring(response: 0.18, dampingFraction: 0.76)

        content
            .offset(y: isHovered && !reduceMotion ? -style.lift : 0)
            .scaleEffect(isHovered && !reduceMotion ? style.scale : 1)
            .shadow(
                color: .punchInk.opacity(isHovered ? 0.92 : 0),
                radius: 0,
                x: activeShadow,
                y: activeShadow
            )
            .zIndex(isHovered ? 10 : 0)
            .animation(hoverAnimation, value: isHovered)
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

    func hoverLift(_ style: HoverLiftStyle = .standard) -> some View {
        modifier(HoverLiftModifier(style: style))
    }
}
