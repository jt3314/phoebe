import SwiftUI

struct AddPhoebeEventSheet: View {
    @Binding var isPresented: Bool
    let userId: UUID
    let selectedDate: String
    let onCreated: () -> Void

    @State private var name = ""
    @State private var eventType: PhoebeEvent.EventType = .selfCare
    @State private var effortCost = 0
    @State private var startTime = ""
    @State private var endTime = ""
    @State private var isSaving = false

    private let phoebeEventService = PhoebeEventService()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Event type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedForeground)

                            Picker("Event Type", selection: $eventType) {
                                ForEach(PhoebeEvent.EventType.allCases, id: \.self) { type in
                                    Label(type.label, systemImage: type.icon)
                                        .tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedForeground)

                            TextField(eventType.label, text: $name)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Theme.cardBorder, lineWidth: 1)
                                )
                        }

                        // Effort cost
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Effort Cost: \(effortCost) pts")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedForeground)

                            Stepper("", value: $effortCost, in: 0...15)
                                .labelsHidden()
                        }

                        // Save button
                        Button {
                            Task { await save() }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            } else {
                                Text("Add \(eventType.label)")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(isSaving)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add Phoebe Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(Theme.primary)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        let eventName = name.isEmpty ? eventType.label : name

        do {
            _ = try await phoebeEventService.create(
                userId: userId,
                name: eventName,
                description: nil,
                eventType: eventType,
                date: selectedDate,
                startTime: startTime.isEmpty ? nil : startTime,
                endTime: endTime.isEmpty ? nil : endTime,
                effortCost: effortCost
            )
            onCreated()
            isPresented = false
        } catch {
            // Handle silently for now
        }
        isSaving = false
    }
}
