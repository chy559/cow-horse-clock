import SwiftUI

struct PunchCardGauge: View {
    let progress: Double

    private var boundedProgress: Double {
        min(1, max(0, progress))
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height - 12)
            let radius = min(size.width * 0.39, size.height - 24)
            let start = Angle.degrees(180)
            let end = Angle.degrees(0)

            var track = Path()
            track.addArc(
                center: center,
                radius: radius,
                startAngle: start,
                endAngle: end,
                clockwise: false
            )
            context.stroke(
                track,
                with: .color(.white.opacity(0.8)),
                style: StrokeStyle(lineWidth: 16, lineCap: .round)
            )

            var progressPath = Path()
            progressPath.addArc(
                center: center,
                radius: radius,
                startAngle: start,
                endAngle: .degrees(180 + 180 * boundedProgress),
                clockwise: false
            )
            context.stroke(
                progressPath,
                with: .color(.punchInk),
                style: StrokeStyle(lineWidth: 11, lineCap: .round)
            )

            for index in 0...10 {
                let angle = Double.pi + Double(index) / 10 * Double.pi
                let outer = CGPoint(
                    x: center.x + cos(angle) * (radius + 13),
                    y: center.y + sin(angle) * (radius + 13)
                )
                let inner = CGPoint(
                    x: center.x + cos(angle) * (radius + (index.isMultiple(of: 5) ? 2 : 6)),
                    y: center.y + sin(angle) * (radius + (index.isMultiple(of: 5) ? 2 : 6))
                )
                var tick = Path()
                tick.move(to: inner)
                tick.addLine(to: outer)
                context.stroke(tick, with: .color(.punchInk), lineWidth: 2)
            }

            let needleAngle = Double.pi + boundedProgress * Double.pi
            let needleEnd = CGPoint(
                x: center.x + cos(needleAngle) * (radius - 18),
                y: center.y + sin(needleAngle) * (radius - 18)
            )
            var needle = Path()
            needle.move(to: center)
            needle.addLine(to: needleEnd)
            context.stroke(
                needle,
                with: .color(.punchCoral),
                style: StrokeStyle(lineWidth: 7, lineCap: .round)
            )
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - 8,
                    y: center.y - 8,
                    width: 16,
                    height: 16
                )),
                with: .color(.punchInk)
            )
        }
        .animation(
            .spring(response: 0.45, dampingFraction: 0.78),
            value: boundedProgress
        )
        .accessibilityLabel("今日搬砖进度")
        .accessibilityValue("\(Int(boundedProgress * 100))%")
    }
}
