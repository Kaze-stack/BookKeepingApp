import Foundation
import CoreData
import SwiftUI

class AccountViewModel: ObservableObject {
	// MARK: - Member
	// 今日数据
	@Published private(set) var todayData: TodayData
	
	// 记录按钮的位置
	@Published var plusButtonPosition: CGPoint {
		didSet {
			savePlusButtonPosition()
		}
	}
	
	// 所有数据, 用于分类
	private var totalData: [TotalCData] = []
	
	// 分类后的所有数据
	@Published private(set) var classifiedTotalData: [[TotalCData]] = []
	
	// 今日数据 ? 总计数据
	@Published var isTodayData: Bool = true
	
	// 正在加载数据
	@Published private(set) var isLoading: Bool = false
	
	// 用于强制刷新
	@Published private var refresh: Bool = false
	
	// CoreData容器
	private var container: NSPersistentContainer
	// CoreData数据获取请求
	private var fetch: NSFetchRequest<TotalCData>
	// CoreData生成的类, 保存到CoreData的缓冲
	private var oneRecord: TotalCData!
	
	// 今天的日期
	private(set) var today: String
	// 今天的年月
	private var todayYearAndMonth: String
	// 今天的日数
	private var todayDay: String
	
	// 数据的条数
	var recordCount: Int {
		get {
			if isTodayData {
				return todayData.data.count
			} else {
				return classifiedTotalData.count
			}
		}
	}
	
	// 待修改记录下标
	private var toEditRecordIndex: Int = 0
	
	// 今日数据已经加载完毕
	private var todayHasLoaded: Bool = false
	
	// 所有数据已经加载完毕
	private var totalHasLoaded: Bool = false
	
	// 卸载今日数据计时器
	private var unloadTodayDataTimer: DispatchSourceTimer?
	
	// 记录按钮自动保存计时器
	private var autosaveButtonPositionTimer: Timer?
	
	// MARK: - Init
	init() {
		todayData = TodayData()
		plusButtonPosition = CGPoint(x: 200, y: 100)
		
		today = getDate()
		todayYearAndMonth = getYearAndMonth()
		todayDay = getDay()
		
		container = NSPersistentContainer(name: "Data")
		fetch = NSFetchRequest<TotalCData>(entityName: "TotalCData")
		
		plusButtonPosition = getPlusButtonPosition()
		
		initCoreDataContainer()
	}
	
	// MARK: - Private Func
	// 获取记录按钮的位置
	private func getPlusButtonPosition() -> CGPoint {
		if let plusPosition = UserDefaults.standard.data(forKey: "plusButtonPosition") {
			if let decoded = try? JSONDecoder().decode(CGPoint.self, from: plusPosition) {
				return decoded
			} else {
				return CGPoint(x: 200, y: 400)
			}
		} else {
			return CGPoint(x: 200, y: 400)
		}
	}
	
	// 自动保存记录按钮的位置
	private func savePlusButtonPosition() {
		autosaveButtonPositionTimer?.invalidate()
		autosaveButtonPositionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {
			_ in
			UserDefaults.standard.set(try? JSONEncoder().encode(self.plusButtonPosition), forKey: "plusButtonPosition")
//			print("保存完成")
		}
	}
	
	// 初始化CoreData容器
	private func initCoreDataContainer() {
		container.loadPersistentStores { _, error in
			if let err = error {
				print("error in load Core Data: \(err)")
			} else {
//					print("Core Data load successfully")
			}
		}
	}
	
	// 通过dateInfo属性, 删除所有数据中的记录
	private func deleteByDateInfo(dateInfo: Date) {
		if totalData.count == 0 {
			return
		}
		
		var l = 0
		var r = totalData.count - 1
		var index = -1
		while l <= r {
			let m = (l + r) / 2
			if totalData[m].dateInfo! > dateInfo {
				r = m - 1
			} else if totalData[m].dateInfo! < dateInfo {
				l = m + 1
			} else {
				index = m
				break
			}
		}
		if index != -1 {
			totalData.remove(at: index)
		}
	}
	
	// MARK: - Method
	// 加载今日数据
	func loadTodayData() {
		isTodayData = true
		if todayHasLoaded {
			return
		}
		
		let context = container.viewContext
		fetch.predicate = NSPredicate(format: "yearmonth = %@ && day = %@", todayYearAndMonth, todayDay)
		
		do {
			let today = try context.fetch(fetch)
			todayData.parseFromCoreData(rawData: today)
			todayHasLoaded = true
		} catch {
			print("\(Date()): init today's Data error = \(error)")
		}
	}

	// 卸载今日数据
	func unloadTodayData() {
		isTodayData = false
		todayData.data.removeAll()
		todayHasLoaded = false
	}
	
	// 加载所有数据
	func loadTotalData() {
		if totalHasLoaded {
			return
		}
		
		let context = container.viewContext
		fetch = NSFetchRequest<TotalCData>(entityName: "TotalCData")
		
		do {
			totalData = try context.fetch(fetch)
			totalHasLoaded = true
		} catch {
			print("\(Date()): init total Data error = \(error)")
		}
		
		isLoading = true
		DispatchQueue.global().async {
			[unowned self] in
			var yearAndMonth: String = ""
			var recordSet: [TotalCData] = []
			var classfyData: [[TotalCData]] = []
			for record in self.totalData {
				if record.yearmonth != yearAndMonth {
					if recordSet.count > 0 {
						classfyData.append(recordSet)
						recordSet.removeAll()
					}
					yearAndMonth = record.yearmonth!
				}
				recordSet.append(record)
			}
			
			if recordSet.count > 0 {
				classfyData.append(recordSet)
				recordSet.removeAll()
			}
			self.totalData.removeAll()
			
			DispatchQueue.main.async {
				self.isLoading = false
				self.classifiedTotalData = classfyData
				classfyData.removeAll()
			}
		}
	}
	// 卸载所有数据
	func unloadTotalData() {
		totalHasLoaded = false
		classifiedTotalData.removeAll()
	}
	
	// 获取今日总支出, 总收入
	func getTodayStatistics() -> (String, String) {
		var sumIn: Float = 0
		var sumOut: Float = 0
		
		for record in todayData.data {
			if record.isIncome {
				sumIn += record.amount
			} else {
				sumOut += record.amount
			}
		}
		let strIn = NSString.init(format: "%.2f", sumIn) as String
		let strOut = NSString.init(format: "%.2f", sumOut) as String
		
		return (strIn, strOut)
	}
	
	// 增加记录
	func addRecord(isIncome: Bool, amount: Float, comment: String = "") {
		let record = TodayData.Data(isIncome: isIncome, amount: amount, comment: comment)
		todayData.data.append(record)
		
		let context = container.viewContext
		oneRecord = NSEntityDescription.insertNewObject(forEntityName: "TotalCData", into: context) as? TotalCData
		
		oneRecord.yearmonth = self.todayYearAndMonth
		oneRecord.day = self.todayDay
		oneRecord.dateInfo = record.dateInfo
		oneRecord.isIncome = record.isIncome
		oneRecord.amount = record.amount
		oneRecord.comment = record.comment
		
		if context.hasChanges {
			do {
				try context.save()
//				print("Save record: \(record) successfully.")
			} catch {
				print("Can't save record: \(record) to Core Data")
				print("\(error)")
			}
		}
	}
	
	// 删除记录
	func deleteRecord(at index: IndexSet) {
		let record = todayData.data[index.first!]
		todayData.data.remove(atOffsets: index)
		let dateInfo = record.dateInfo
		deleteByDateInfo(dateInfo: dateInfo)

		let context = container.viewContext
		fetch.predicate = NSPredicate(format: "dateInfo = %@", dateInfo as CVarArg)
		do {
			let data = try context.fetch(fetch)
			context.delete(data[0])
			
			if context.hasChanges {
				try context.save()
			}
		} catch {
			print("Can't delete record: \(dateInfo) from Core Data")
			print("\(error)")
		}
	}
	
	// 在所有数据中删除记录
	func deleteRecordInTotal(record: TotalCData) {
		var index: (Int, Int) = (-1, -1)
		for i in 0..<classifiedTotalData.count {
			if classifiedTotalData[i][0].yearmonth == record.yearmonth {
				index.0 = i
				for j in 0..<classifiedTotalData[i].count {
					if classifiedTotalData[i][j] == record {
						index.1 = j
						break
					}
				}
				break
			}
		}
		if index.0 == -1 || index.1 == -1 {
			return
		}
		
		classifiedTotalData[index.0].remove(at: index.1)
		if classifiedTotalData[index.0].count == 0 {
			classifiedTotalData.remove(at: index.0)
		}
		
		let context = container.viewContext
		fetch.predicate = NSPredicate(format: "dateInfo = %@", record.dateInfo! as CVarArg)
		do {
			let data = try context.fetch(fetch)
			context.delete(data[0])
			
			if context.hasChanges {
				try context.save()
			}
		} catch {
			print("Can't delete record: \(record) from Core Data")
			print("\(error)")
		}
	}
	
	// 保存待修改记录的下标
	func setToEditIndex(id: Int) {
		toEditRecordIndex = todayData.getIndexById(id: id)
	}
	
	// 修改记录
	func editRecord(amount: Float, comment: String) {
		let index = toEditRecordIndex
		let record = todayData.data[index]
		todayData.data[index].amount = amount
		todayData.data[index].comment = comment
		
		let context = container.viewContext
		fetch.predicate = NSPredicate(format: "dateInfo = %@", record.dateInfo as CVarArg)
		do {
			let data = try context.fetch(fetch)
			data[0].amount = amount
			data[0].comment = comment
			
			if context.hasChanges {
				try context.save()
			}
		} catch {
			print("Can't change record: \(record) from Core Data")
			print("\(error)")
		}
	}
	
	func update() {
		refresh.toggle()
	}
}
