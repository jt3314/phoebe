import SwiftUI

struct EffortBadge: View {
    let points: Int

    var body: some View {
        Text("\(points) pts")
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.secondary)
            .foregroundStyle(Theme.secondaryForeground)
            .clipShape(Capsule())
    }
}

struct PriorityBadge: View {
    let priority: Int

    var body: some View {
        Text("\(priority)")
            .font(.system(size: 10, weight: .bold))
            .frame(width: 22, height: 22)
            .background(priorityColor.opacity(0.15))
            .foregroundStyle(priorityColor)
            .clipShape(Circle())
    }

    private var priorityColor: Color {
        switch priority {
        case 1...3: return Theme.success
        case 4...6: return Theme.warning
        case 7...10: return Theme.destructive
        default: return Theme.mutedForeground
        }
    }
}
