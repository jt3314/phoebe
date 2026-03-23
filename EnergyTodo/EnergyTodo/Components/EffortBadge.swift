import SwiftUI

struct EffortBadge: View {
    let points: Int

    var body: some View {
        Text("\(points) pts")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct PriorityBadge: View {
    let priority: Int

    var body: some View {
        Text("\(priority)")
            .font(.caption2)
            .fontWeight(.bold)
            .frame(width: 22, height: 22)
            .background(priorityColor.opacity(0.15))
            .foregroundStyle(priorityColor)
            .clipShape(Circle())
    }

    private var priorityColor: Color {
        switch priority {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...10: return .red
        default: return .secondary
        }
    }
}
