import SwiftUI

@main
struct __App: App {
	let accountVM = AccountViewModel()
	@State private var selected: Int = 0
	
    var body: some Scene {
        WindowGroup {
			TabView(selection: $selected) {
				TodayView(todayVM: accountVM)
					.tabItem {
						Image(systemName: selected == 0 ? "person.circle" : "person")
						Text("今日数据")
					}
					.tag(0)
					.onAppear {
						accountVM.loadTodayData()
					}
					.onDisappear {
						accountVM.unloadTodayData()
					}

				TotalView(totalVM: accountVM)
					.tabItem {
						Image(systemName: selected == 1 ? "list.bullet.indent" : "list.dash")
						Text("总计")
					}
					.tag(1)
					.onAppear {
						accountVM.loadTotalData()
					}
					.onDisappear {
						accountVM.unloadTotalData()
					}
			}
        }
    }
	
	init() {}
}
