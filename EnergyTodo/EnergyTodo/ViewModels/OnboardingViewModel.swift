import Foundation

@Observable
final class OnboardingViewModel {

    enum Step: Int, CaseIterable {
        case cycleLength = 0
        case day1Date = 1
        case schedulingDirection = 2
        case confirm = 3
    }

    var currentStep: Step = .cycleLength
    var cycleLength: Int = AppConstants.defaultCycleLength
    var day1Date: Date = Date()
    var customLengthText = ""
    var schedulingDirection: String = "early"
    var isProcessing = false
    var errorMessage: String?

    private let cycleService = CycleService()

    var day1DateString: String {
        CycleCalculator.formatISO(day1Date)
    }

    var isValidLength: Bool {
        EffortCalculator.isValidCycleLength(cycleLength)
    }

    func selectCommonLength(_ value: Int) {
        cycleLength = value
        customLengthText = ""
    }

    func applyCustomLength() {
        if let value = Int(customLengthText), EffortCalculator.isValidCycleLength(value) {
            cycleLength = value
        }
    }

    func markTodayAsDay1() {
        day1Date = Date()
    }

    func nextStep() {
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func previousStep() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }

    /// Complete onboarding: create cycle + default effort points.
    func completeSetup(userId: UUID) async -> Bool {
        isProcessing = true
        errorMessage = nil
        do {
            let cycle = try await cycleService.createCycle(
                userId: userId,
                length: cycleLength,
                day1Date: day1DateString
            )
            // Save scheduling direction
            try await supabase
                .from("cycles")
                .update(["scheduling_direction": schedulingDirection])
                .eq("id", value: cycle.id.uuidString)
                .execute()
            isProcessing = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isProcessing = false
            return false
        }
    }
}
