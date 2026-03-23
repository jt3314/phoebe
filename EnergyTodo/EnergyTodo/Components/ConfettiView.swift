import SwiftUI

/// Confetti celebration animation triggered on task completion.
/// Uses Canvas + TimelineView for lightweight particle rendering.
struct ConfettiView: View {
    @State private var particles: [Particle] = []
    @State private var startTime: Date?

    private let colors: [Color] = [
        Color(hex: "#E8B89D"), Color(hex: "#D4845A"),
        .green, .blue, .purple, .pink, .yellow, .orange,
    ]

    struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        var y: CGFloat
        let size: CGFloat
        let color: Color
        let speed: CGFloat
        let wobble: CGFloat
        let rotation: Double
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = (startTime.map { timeline.date.timeIntervalSince($0) }) ?? 0

                for particle in particles {
                    let y = particle.y + particle.speed * CGFloat(elapsed) * 200
                    let x = particle.x + sin(CGFloat(elapsed) * particle.wobble * 3) * 20

                    guard y < size.height + 20 else { continue }

                    var transform = CGAffineTransform.identity
                    transform = transform.translatedBy(x: x, y: y)
                    transform = transform.rotated(by: elapsed * particle.rotation)

                    context.transform = transform
                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * 0.6
                    )
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(particle.color)
                    )
                    context.transform = .identity
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startTime = Date()
            particles = (0..<50).map { _ in
                Particle(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: -100...(-20)),
                    size: CGFloat.random(in: 6...12),
                    color: colors.randomElement()!,
                    speed: CGFloat.random(in: 0.8...2.0),
                    wobble: CGFloat.random(in: 1...4),
                    rotation: Double.random(in: -3...3)
                )
            }
        }
    }
}
