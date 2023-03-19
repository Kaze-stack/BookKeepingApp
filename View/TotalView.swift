import Foundation
import SwiftUI

struct TotalView: View {
	@ObservedObject var totalVM: AccountViewModel
	
    var body: some View {
		VStack {
			Text("数据总览")
			if totalVM.isLoading {
				ProgressView()
			} else {
				dataList()
				Spacer()
			}
		}
		.sheet(isPresented: $isShowRecord) {
			recordForm()
		}
    }
	
	// 显示详细记录
	@State private var isShowRecord: Bool = false
	// 表单 - 日期
	@State private var formDate: String = ""
	// 表单 - 是否收入
	@State private var formIsIncome: Bool = false
	// 表单 - 数额
	@State private var formAmount: Float = 0
	// 表单 - 备注
	@State private var formComment: String = ""
	
	// 生成记录列表
	@ViewBuilder
	private func dataList() -> some View {
		if totalVM.recordCount == 0 {
			Text("还没有记录")
		} else {
			List {
				ForEach(totalVM.classifiedTotalData, id: \.self) {
					recordSet in
					FoldList(
						vm: totalVM,
						recordSet: recordSet,
						isShowRecord: $isShowRecord,
						formDate: $formDate,
						formIsIncome: $formIsIncome,
						formAmount: $formAmount,
						formComment: $formComment
					)
				}
			}
		}
	}
	
	// 生成详细记录表单
	@ViewBuilder
	private func recordForm() -> some View {
		NavigationView {
			VStack {
				Form {
					Section(header: Text("时间")) {
						Text(formDate)
					}
					Section(header: Text("类型")) {
						Toggle(isOn: $formIsIncome) {
							Text(formIsIncome ? "收入" : "支出")
						}
						.disabled(true)
					}
					Section(header: Text("金额")) {
						Text(NSString.init(format: "%.2f", formAmount) as String)
					}
					Section(header: Text("备注")) {
						Text(formComment)
					}
					HStack {
						Spacer()
						Button {
							isShowRecord = false
							formDate = ""
							formIsIncome = false
							formAmount = 0.0
							formComment = ""
						} label: {
							Text("结束")
						}
						Spacer()
					}
				}
				.navigationTitle("查看记录")
				.navigationBarTitleDisplayMode(.inline)
				.onDisappear {
					isShowRecord = false
					formDate = ""
					formIsIncome = false
					formAmount = 0.0
					formComment = ""
				}
			}
		}
	}
}

// 一条记录
fileprivate struct RecordView: View {
	let record: TotalCData!// 一条记录的数据格式
	
	@State private var isShow: Bool = true
	
	var body: some View {
		VStack {
			if isShow {
				HStack {
					Text("\(record.yearmonth!)月\(record.day!)")
						.font(.footnote)
					Spacer()
				}
				HStack {
					Text(genComment())
						.lineLimit(1)
					Spacer()
					Text(genAmountDiscription())
				}
			}
		}
		.padding(5)
		.onAppear {
			isShow = true
		}
		.onDisappear {
			isShow = false
		}
	}
	
	// 生成备注
	private func genComment() -> String {
		if record.comment!.count == 0 {
			return "记录"
		} else {
			return record.comment!
		}
	}
	
	// 生成收入支出数额
	private func genAmountDiscription() -> String {
		var signal: String
		let number = NSString.init(format: "%.2f", record.amount) as String
		
		if record.isIncome {
			signal = "+"
		} else {
			signal = "-"
		}
		return (signal + number)
	}
}

// 折叠列表
fileprivate struct FoldList: View {
	let vm: AccountViewModel
	
	let recordSet: [TotalCData]
	
	@State private var isFold: Bool = false
	
	// 显示详细记录
	@Binding var isShowRecord: Bool
	// 表单 - 日期
	@Binding var formDate: String
	// 表单 - 是否收入
	@Binding var formIsIncome: Bool
	// 表单 - 数额
	@Binding var formAmount: Float
	// 表单 - 备注
	@Binding var formComment: String
	
	var body: some View {
		Section(header: sectionHeader) {
			MonthStatistic(recordSet: recordSet)
				.padding(5)
				.disabled(true)
			if !isFold {
				ForEach(recordSet) {
					record in
					RecordView(record: record)
						.onTapGesture {
							vm.update()
							formDate = DateFormat(date: record.dateInfo!)
							formIsIncome = record.isIncome
							formAmount = record.amount
							formComment = record.comment!
							isShowRecord = true
						}
				}
				.onDelete {
					indexSet in
					vm.deleteRecordInTotal(record: recordSet[indexSet.first!])
				}
			}
		}
	}
	
	// Section头部标签
	private var sectionHeader: some View {
		HStack {
			Text("\(recordSet[0].yearmonth!)月").font(.headline)
			Spacer()
			Image(systemName: "chevron.right")
				.rotationEffect(.degrees(isFold ? 0 : 90))
				.scaleEffect(1.2)
				.onTapGesture {
					withAnimation {
						isFold = !isFold
					}
				}
		}
	}
	
	// 生成对应月份的总支出, 总收入
	private func MonthStatistic(recordSet: [TotalCData]) -> some View{
		var sumIn: Float = 0
		var sumOut: Float = 0
		
		for record in recordSet {
			if record.isIncome {
				sumIn += record.amount
			} else {
				sumOut += record.amount
			}
		}
		let strIn = NSString.init(format: "%.2f", sumIn) as String
		let strOut = NSString.init(format: "%.2f", sumOut) as String
		return VStack {
			HStack {
				Text("总收入")
				Spacer()
				Text(strIn)
			}
			HStack {
				Text("总支出")
				Spacer()
				Text(strOut)
			}
		}
		.font(.subheadline)
	}
}
