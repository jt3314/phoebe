import SwiftUI

struct SchedulingDirectionView: View {
    @Binding var selectedDirection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            directionOption(
                value: "early",
                title: "Early Bird",
                description: "Schedule tasks as soon as possible. We'll flag if anything lands past its deadline.",
                icon: "sunrise"
            )

            directionOption(
                value: "late",
                title: "Productive Procrastination",
                description: "Schedule tasks right before their deadline. Maximum flexibility.",
                icon: "moon.stars"
            )
        }
    }

    private func directionOption(value: String, title: String, description: String, icon: String) -> some View {
        Button {
            selectedDirection = value
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(selectedDirection == value ? Theme.primary : Theme.cardBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if selectedDirection == value {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.subheadline)
                            .foregroundStyle(selectedDirection == value ? Theme.primary : Theme.mutedForeground)

                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.foreground)
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(12)
            .background(selectedDirection == value ? Theme.primary.opacity(0.06) : Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedDirection == value ? Theme.primary.opacity(0.4) : Theme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
