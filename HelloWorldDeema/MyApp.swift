import SwiftUI
import SwiftData

@main
struct MyApp: App {
    private let container: ModelContainer
    @State private var viewModel: ActivityViewModel

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: DayEntryRecord.self, GoalRecord.self)
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
        self.container = container
        _viewModel = State(initialValue: ActivityViewModel(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
        }
        .modelContainer(container)
    }
}
