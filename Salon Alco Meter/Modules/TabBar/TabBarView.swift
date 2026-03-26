import SwiftUI
import Observation

@Observable
@MainActor
class TabBarViewModel {
    var selection = 0
}

extension TabBarViewModel: TabBarDelegate {
    func showSea() {
        self.selection = 0
    }
}

protocol TabBarDelegate: AnyObject {
    func showSea()
}

struct TabBarView: View {
    @Bindable var viewModel = TabBarViewModel()
    @Environment(\.modelContext) var context

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.purple.opacity(0.32))
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $viewModel.selection) {
            SeaView(context: context)
                .tabItem {
                    Image(systemName: "triangle.fill")
                    Text("Sea")
                        .fontWeight(viewModel.selection == 0 ? .bold : .regular)
                }
                .tag(0)
            LogbookView(tabDelegate: viewModel)
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    Text("Logbook")
                        .fontWeight(viewModel.selection == 1 ? .bold : .regular)
                }
                .tag(1)
            StatsView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Stats")
                        .fontWeight(viewModel.selection == 2 ? .bold : .regular)
                }
                .tag(2)
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                        .fontWeight(viewModel.selection == 3 ? .bold : .regular)
                }
                .tag(3)
        }
        .accentColor(.purple)
    }
}
