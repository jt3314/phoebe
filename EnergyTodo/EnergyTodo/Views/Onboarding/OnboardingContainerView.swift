import SwiftUI

struct OnboardingContainerView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                    Capsule()
                        .fill(step.rawValue <= vm.currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
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
                ConfirmStepView(vm: vm, authVM: authVM)
                    .tag(OnboardingViewModel.Step.confirm)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: vm.currentStep)
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

                Text("Your cycle represents the recurring pattern of your energy levels")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(vm.cycleLength == option.value ? .accentColor : .secondary)
                }
            }
            .padding(.horizontal, 24)

            // Custom input
            HStack {
                TextField("Custom (1-99)", text: $vm.customLengthText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 160)

                Button("Set") {
                    vm.applyCustomLength()
                }
                .buttonStyle(.bordered)
            }

            Text("Selected: \(vm.cycleLength) days")
                .font(.headline)
                .foregroundStyle(Color.accentColor)

            Spacer()

            Button("Next") {
                vm.nextStep()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!vm.isValidLength)
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

                Text("Choose when your current cycle began")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("Mark Today as Day 1") {
                vm.markTodayAsDay1()
            }
            .buttonStyle(.borderedProminent)

            Text("or choose a date:")
                .font(.caption)
                .foregroundStyle(.secondary)

            DatePicker("Day 1", selection: $vm.day1Date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)

            Spacer()

            HStack(spacing: 16) {
                Button("Back") { vm.previousStep() }
                    .buttonStyle(.bordered)
                Button("Next") { vm.nextStep() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
}

// MARK: - Step 3: Confirm

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

                Text("You can always change these later in Settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Summary card
            VStack(spacing: 16) {
                HStack {
                    Text("Cycle Length")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(vm.cycleLength) days")
                        .fontWeight(.semibold)
                }
                Divider()
                HStack {
                    Text("Day 1 Date")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(vm.day1Date, style: .date)
                        .fontWeight(.semibold)
                }
                Divider()
                Text("Effort points will be set to default values. You can customize them later in the Setup page.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)

            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack(spacing: 16) {
                Button("Back") { vm.previousStep() }
                    .buttonStyle(.bordered)

                Button {
                    Task {
                        if let userId = authVM.currentUserId {
                            let success = await vm.completeSetup(userId: userId)
                            if success {
                                authVM.state = .authenticated
                            }
                        }
                    }
                } label: {
                    if vm.isProcessing {
                        ProgressView()
                    } else {
                        Text("Get Started")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isProcessing)
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
}
