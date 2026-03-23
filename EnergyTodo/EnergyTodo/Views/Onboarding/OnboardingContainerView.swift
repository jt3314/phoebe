import SwiftUI

struct OnboardingContainerView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                        Capsule()
                            .fill(step.rawValue <= vm.currentStep.rawValue ? Theme.primary : Theme.secondary)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                TabView(selection: $vm.currentStep) {
                    CycleLengthStepView(vm: vm)
                        .tag(OnboardingViewModel.Step.cycleLength)
                    Day1DateStepView(vm: vm)
                        .tag(OnboardingViewModel.Step.day1Date)
                    SchedulingDirectionStepView(vm: vm)
                        .tag(OnboardingViewModel.Step.schedulingDirection)
                    ConfirmStepView(vm: vm, authVM: authVM)
                        .tag(OnboardingViewModel.Step.confirm)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: vm.currentStep)
            }
        }
    }
}

// MARK: - Step 1: Cycle Length

struct CycleLengthStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Choose Your Cycle Length")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.foreground)

                Text("Your cycle represents the recurring pattern of your energy levels")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedForeground)
                    .multilineTextAlignment(.center)
            }

            // Quick select buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AppConstants.commonCycleLengths, id: \.value) { option in
                    Button {
                        vm.selectCommonLength(option.value)
                    } label: {
                        Text(option.label)
                            .font(.subheadline)
                            .foregroundStyle(vm.cycleLength == option.value ? .white : Theme.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(vm.cycleLength == option.value ? Theme.primary : Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(vm.cycleLength == option.value ? Theme.primary : Theme.cardBorder, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 24)

            // Custom input
            HStack {
                TextField("Custom (1-99)", text: $vm.customLengthText)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardBorder, lineWidth: 1))
                    .frame(maxWidth: 160)

                Button("Set") { vm.applyCustomLength() }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.secondary)
                    .foregroundStyle(Theme.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text("Selected: \(vm.cycleLength) days")
                .font(.headline)
                .foregroundStyle(Theme.primary)

            Spacer()

            Button("Next") { vm.nextStep() }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(vm.isValidLength ? Theme.primary : Theme.muted)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(!vm.isValidLength)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .padding()
    }
}

// MARK: - Step 2: Day 1 Date

struct Day1DateStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("When Does Day 1 Start?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.foreground)

                Text("Choose when your current cycle began")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedForeground)
            }

            Button("Mark Today as Day 1") { vm.markTodayAsDay1() }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("or choose a date:")
                .font(.caption)
                .foregroundStyle(Theme.mutedForeground)

            DatePicker("Day 1", selection: $vm.day1Date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Theme.primary)
                .padding(.horizontal)

            Spacer()

            HStack(spacing: 16) {
                Button("Back") { vm.previousStep() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.foreground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cardBorder, lineWidth: 1))

                Button("Next") { vm.nextStep() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding()
    }
}

// MARK: - Step 3: Scheduling Direction

struct SchedulingDirectionStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("How Should We Schedule?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.foreground)

                Text("Choose your preferred scheduling style")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedForeground)
                    .multilineTextAlignment(.center)
            }

            SchedulingDirectionView(selectedDirection: $vm.schedulingDirection)
                .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 16) {
                Button("Back") { vm.previousStep() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.foreground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cardBorder, lineWidth: 1))

                Button("Next") { vm.nextStep() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding()
    }
}

// MARK: - Step 4: Confirm

struct ConfirmStepView: View {
    @Bindable var vm: OnboardingViewModel
    @Bindable var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Confirm Your Setup")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.foreground)

                Text("You can always change these later in Settings")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedForeground)
            }

            // Summary card
            VStack(spacing: 16) {
                HStack {
                    Text("Cycle Length")
                        .foregroundStyle(Theme.mutedForeground)
                    Spacer()
                    Text("\(vm.cycleLength) days")
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.foreground)
                }
                Divider()
                HStack {
                    Text("Day 1 Date")
                        .foregroundStyle(Theme.mutedForeground)
                    Spacer()
                    Text(vm.day1Date, style: .date)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.foreground)
                }
                Divider()
                HStack {
                    Text("Scheduling")
                        .foregroundStyle(Theme.mutedForeground)
                    Spacer()
                    Text(vm.schedulingDirection == "early" ? "Early Bird" : "Productive Procrastination")
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.foreground)
                }
                Divider()
                Text("Effort points will be set to default values. You can customize them later in the Setup page.")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedForeground)
            }
            .themedCard()
            .padding(.horizontal, 24)

            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.destructive)
            }

            Spacer()

            HStack(spacing: 16) {
                Button("Back") { vm.previousStep() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.foreground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cardBorder, lineWidth: 1))

                Button {
                    Task {
                        if let userId = authVM.currentUserId {
                            let success = await vm.completeSetup(userId: userId)
                            if success { authVM.state = .authenticated }
                        }
                    }
                } label: {
                    if vm.isProcessing {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Get Started")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(vm.isProcessing)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding()
    }
}
