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

extension View {
    func punchCard(
        fill: Color = .punchPaper,
        radius: CGFloat = 14
    ) -> some View {
        modifier(PunchCardModifier(fill: fill, radius: radius))
    }
}
