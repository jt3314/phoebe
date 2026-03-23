import SwiftUI

struct Day1BannerView: View {
    var onDismiss: () -> Void

    var body: some View {
        let heading = getCyclingCopy(options: Day1PostcardCopy.bannerHeading)
        let cta = getCyclingCopy(options: Day1PostcardCopy.bannerCta, salt: 1)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.primaryForeground.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .background(Theme.primaryForeground.opacity(0.15))
                        .clipShape(Circle())
                }
            }

            Text(heading)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.primaryForeground)

            Text(getCyclingCopy(options: Day1PostcardCopy.postcardBody, salt: 2))
                .font(.subheadline)
                .foregroundStyle(Theme.primaryForeground.opacity(0.85))

            Button {
                // CTA action - could navigate to planner or cycle view
            } label: {
                Text(cta)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.primaryForeground)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Theme.primary, Theme.primary.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
