import SwiftUI

struct SleepCheckBanner: View {
    @Bindable var vm: TodayViewModel
    let userId: UUID

    var body: some View {
        HStack {
            Image(systemName: "moon.zzz")
                .foregroundStyle(.indigo)

            Text("How did you sleep?")
                .font(.subheadline)

            Spacer()

            Button("Well") {
                Task { await vm.recordSleep(userId: userId, sleptPoorly: false) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Poorly (-1)") {
                Task { await vm.recordSleep(userId: userId, sleptPoorly: true) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.orange)
        }
        .padding()
        .background(Color.indigo.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
