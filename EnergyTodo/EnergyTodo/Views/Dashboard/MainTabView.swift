import SwiftUI

struct MainTabView: View {
    @Bindable var authVM: AuthViewModel

    var body: some View {
        TabView {
            TodayView(authVM: authVM)
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            NavigationStack {
                ProjectsListView(authVM: authVM)
            }
            .tabItem {
                Label("Tasks", systemImage: "checkmark.circle")
            }

            PlannerView(authVM: authVM)
                .tabItem {
                    Label("Planner", systemImage: "calendar.day.timeline.left")
                }

            CalendarView(authVM: authVM)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            NavigationStack {
                SetupView(authVM: authVM)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(Theme.primary)
    }
}
