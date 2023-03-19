import Foundation

func getDate() -> String {
	let fmt = DateFormatter()
	fmt.dateFormat = "yyyy年MM月dd日"
	return fmt.string(from: Date())
}

func getYearAndMonth() -> String {
	let fmt = DateFormatter()
	fmt.dateFormat = "yyyy年MM"
	return fmt.string(from: Date())
}

func getDay() -> String {
	let fmt = DateFormatter()
	fmt.dateFormat = "dd日"
	return fmt.string(from: Date())
}

func DateFormat(date: Date) -> String {
	let fmt = DateFormatter()
	fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
	return fmt.string(from: date)
}
