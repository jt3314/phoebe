import SwiftUI

struct UpcomingFeaturesView: View {
    let userId: UUID

    @State private var bbtSaved = false
    @State private var sportSaved = false
    @State private var isSaving = false

    private let remindersService = RemindersService()

    var body: some View {
        VStack(spacing: 14) {
            // BBT Temperature Integration
            featureCard(
                icon: "thermometer.medium",
                title: "BBT Temperature Integration",
                description: "Track your basal body temperature to get even more accurate energy predictions. We'll integrate with your temperature data to refine your cycle phases.",
                featureType: "bbt",
                isSaved: bbtSaved
            ) {
                await saveInterest(featureType: "bbt")
                bbtSaved = true
            }

            // Fitness & Sport Integration
            featureCard(
                icon: "figure.run",
                title: "Fitness & Sport Integration",
                description: "Connect your fitness data to adjust effort points based on workout recovery. We'll factor in exercise intensity to optimize your task scheduling.",
                featureType: "sport",
                isSaved: sportSaved
            ) {
                await saveInterest(featureType: "sport")
                sportSaved = true
            }
        }
    }

    private func featureCard(
        icon: String,
        title: String,
        description: String,
        featureType: String,
        isSaved: Bool,
        onTap: @escaping () async -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Theme.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.foreground)

                    Text("Coming soon")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.warning.opacity(0.15))
                        .foregroundStyle(Theme.warning)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            Text(description)
                .font(.caption)
                .foregroundStyle(Theme.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await onTap() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isSaved ? "checkmark.circle.fill" : "heart.fill")
                        .font(.caption)
                    Text(isSaved ? "Interest saved!" : "I want this!")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(isSaved ? Theme.success : Theme.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSaved ? Theme.success.opacity(0.1) : Theme.primary.opacity(0.1))
                .clipShape(Capsule())
            }
            .disabled(isSaved || isSaving)
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
    }

    private func saveInterest(featureType: String) async {
        isSaving = true
        do {
            try await remindersService.saveFeatureInterest(
                userId: userId,
                featureType: featureType,
                responses: "{}",
                notify: true
            )
        } catch {
            // Silently handle - user can try again
        }
        isSaving = false
    }
}
