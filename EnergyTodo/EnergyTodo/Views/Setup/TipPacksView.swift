import SwiftUI

struct TipPacksView: View {
    let sources: [ReminderSource]
    let userSources: [UserReminderSource]
    let userId: UUID
    var onToggle: (UUID, Bool) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(sources) { source in
                let isEnabled = userSources.first(where: { $0.sourceId == source.id })?.enabled ?? false

                HStack(spacing: 12) {
                    // Icon
                    if let icon = source.icon, !icon.isEmpty {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(Theme.primary)
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "lightbulb")
                            .font(.title3)
                            .foregroundStyle(Theme.primary)
                            .frame(width: 32, height: 32)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(source.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.foreground)

                        if let desc = source.description, !desc.isEmpty {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(Theme.mutedForeground)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: Binding<Bool>(
                        get: { isEnabled },
                        set: { newValue in
                            onToggle(source.id, newValue)
                        }
                    ))
                    .labelsHidden()
                    .tint(Theme.primary)
                }
                .padding(12)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                )
            }
        }
    }
}
