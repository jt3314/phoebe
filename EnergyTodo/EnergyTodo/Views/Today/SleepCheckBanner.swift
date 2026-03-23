import SwiftUI

struct SleepCheckBanner: View {
    @Bindable var vm: TodayViewModel
    let userId: UUID

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(Theme.sleepAccent)

            Text("How did you sleep?")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Theme.foreground)

            Spacer()

            Button("Well") {
                Task { await vm.recordSleep(userId: userId, sleptPoorly: false) }
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.card)
            .foregroundStyle(Theme.foreground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardBorder, lineWidth: 1))

            Button("Poorly (-1)") {
                Task { await vm.recordSleep(userId: userId, sleptPoorly: true) }
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.card)
            .foregroundStyle(Theme.warning)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.warning.opacity(0.3), lineWidth: 1))
        }
        .padding(14)
        .background(Theme.sleepBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.sleepAccent.opacity(0.2), lineWidth: 1)
        )
    }
}
