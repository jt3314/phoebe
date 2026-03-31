import SwiftUI

struct NudgeBannerView: View {
    let nudge: Nudge
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(nudge.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.foreground)

                Text(nudge.body)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(Theme.mutedForeground)
            }
        }
        .padding(12)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var iconName: String {
        switch nudge.severity {
        case .info: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch nudge.severity {
        case .info: return Theme.primary
        case .warning: return Theme.warning
        case .critical: return Theme.destructive
        }
    }

    private var backgroundColor: Color {
        switch nudge.severity {
        case .info: return Theme.primary.opacity(0.08)
        case .warning: return Theme.warning.opacity(0.08)
        case .critical: return Theme.destructive.opacity(0.08)
        }
    }

    private var borderColor: Color {
        switch nudge.severity {
        case .info: return Theme.primary.opacity(0.2)
        case .warning: return Theme.warning.opacity(0.2)
        case .critical: return Theme.destructive.opacity(0.2)
        }
    }
}
