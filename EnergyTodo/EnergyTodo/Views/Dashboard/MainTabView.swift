import SwiftUI

struct MainTabView: View {
    @Bindable var authVM: AuthViewModel

    var body: some View {
        TabView {
            TodayView(authVM: authVM)
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            CalendarView(authVM: authVM)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            NavigationStack {
                ProjectsListView(authVM: authVM)
            }
            .tabItem {
                Label("Projects", systemImage: "folder")
            }

            NavigationStack {
                SetupView(authVM: authVM)
            }
            .tabItem {
                Label("Setup", systemImage: "gearshape")
            }
        }
    }
}
