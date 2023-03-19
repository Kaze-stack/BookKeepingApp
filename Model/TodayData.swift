import CoreData

struct TodayData {
	// MARK: - Define
	struct Data: Identifiable {
		let id: Int
		let dateInfo: Date
		let isIncome: Bool
		var amount: Float
		var comment: String
		
		private static var cnt: Int = 0
		
		init(isIncome: Bool, amount: Float, comment: String = "") {
			self.id = Data.cnt
			self.dateInfo = Date()
			self.isIncome = isIncome
			self.amount = amount
			self.comment = comment
			
			Data.cnt += 1
		}
		
		init(record: TotalCData) {
			self.id = Data.cnt
			self.dateInfo = record.dateInfo!
			self.isIncome = record.isIncome
			self.amount = record.amount
			self.comment = record.comment!
			
			Data.cnt += 1
		}
	}
	
	// MARK: - Member
	var data: [Data] = []
	
	// MARK: - Method
	mutating func parseFromCoreData(rawData: [TotalCData]) {
		for record in rawData {
			data.append(Data(record: record))
		}
	}
	
	func getIndexById(id: Int) -> Int {
		var l = 0
		var r = data.count - 1
		while l <= r {
			let m = (l + r) / 2
			if data[m].id > id {
				r = m - 1
			} else if data[m].id < id {
				l = m + 1
			} else {
				return m
			}
		}
		return -1
	}
}
