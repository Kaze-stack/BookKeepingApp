import Foundation
import SwiftUI

struct TodayView: View {
	@ObservedObject var todayVM: AccountViewModel
	
    var body: some View {
		VStack {
			VStack {
				Text("今天是")
				Text(todayVM.today)
			}
			ZStack {
				VStack {
					Spacer()
					amountList()
					Spacer()
				}
				plusButton()
			}
			.sheet(isPresented: $isRecord) {
				recordForm()
			}
			.sheet(isPresented: $isEdit) {
				editRecordForm()
			}
		}
    }
	
	// 生成今日账本记录
	@ViewBuilder
	private func amountList() -> some View {
		if todayVM.recordCount == 0 {
			Text("今天还没有记录")
		} else {
			let statistic = todayVM.getTodayStatistics()
			List {
				HStack {
					Text("总收入\n总支出")
					Spacer()
					Text("\(statistic.0)\n\(statistic.1)")
				}
				.padding(5)
				.disabled(true)
				ForEach(todayVM.todayData.data) {
					record in
					RecordView(record: record)
						.onTapGesture {
							todayVM.update()
							todayVM.setToEditIndex(id: record.id)
							formIsIncome = record.isIncome
							formAmount = record.amount
							formComment = record.comment
							isEdit = true
						}
				}
				.onDelete { index in
					todayVM.deleteRecord(at: index)
				}
			}
		}
	}
	
	// 记录按钮
	private func plusButton() -> some View {
		Button {
			isRecord = true
		} label: {
			ZStack {
				Circle()
					.foregroundColor(.green)
				Image(systemName: "pencil")
					.imageScale(.large)
					.foregroundColor(.white)
			}
			.frame(maxWidth: 50, maxHeight: 50)
		}
		.position(todayVM.plusButtonPosition)
		.offset(plusButtonOffset)
		.highPriorityGesture(dragPlusButton())
	}
	
	// 按钮位移量
	@GestureState private var plusButtonOffset: CGSize = CGSize.zero
	
	// 拖动按钮手势
	private func dragPlusButton() -> some Gesture {
		let dragGesture = DragGesture()
			.onEnded {
				dragValue in
				todayVM.plusButtonPosition = dragValue.location
			}
			.updating($plusButtonOffset) {
				latestValue, plusButtonOffset, _ in
				withAnimation {
					plusButtonOffset = latestValue.translation
				}
			}
		return dragGesture
	}
	
	// 当前是否在记录
	@State private var isRecord: Bool = false
	// 当前是否在修改记录
	@State private var isEdit: Bool = false
	// 表单 - 是否为收入
	@State private var formIsIncome: Bool = false
	// 表单 - 数额
	@State private var formAmount: Float = 0.0
	// 表单 - 备注
	@State private var formComment: String = ""
	
	// 生成记录表单
	@ViewBuilder
	private func recordForm() -> some View {
		NavigationView {
			VStack {
				Form {
					Section(header: Text("类型")) {
						Toggle(isOn: $formIsIncome) {
							Text(formIsIncome ? "收入" : "支出")
						}
					}
					Section(header: Text("金额")) {
						TextField("", value: $formAmount, format: .number.precision(.fractionLength(2)))
							.keyboardType(.decimalPad)
					}
					Section(header: Text("备注")) {
						TextField("写点备注？", text: $formComment)
					}
					HStack {
						Spacer()
						Button {
							todayVM.addRecord(isIncome: formIsIncome, amount: formAmount, comment: formComment)
							isRecord = false
							formIsIncome = false
							formAmount = 0.0
							formComment = ""
						} label: {
							Text("完成")
						}
						Spacer()
					}
				}
				.navigationTitle("记录一下")
				.navigationBarTitleDisplayMode(.inline)
				.onSubmit {
					todayVM.addRecord(isIncome: formIsIncome, amount: formAmount, comment: formComment)
					isRecord = false
					formIsIncome = false
					formAmount = 0.0
					formComment = ""
				}
				.onDisappear {
					formIsIncome = false
					formAmount = 0.0
					formComment = ""
				}
			}
		}
	}
	
	// 生成修改记录表单
	@ViewBuilder
	private func editRecordForm() -> some View {
		NavigationView {
			VStack {
				Form {
					Section(header: Text("类型")) {
						Toggle(isOn: $formIsIncome) {
							Text(formIsIncome ? "收入" : "支出")
						}
						.disabled(true)
					}
					Section(header: Text("金额")) {
						TextField("", value: $formAmount, format: .number.precision(.fractionLength(2)))
							.keyboardType(.decimalPad)
					}
					Section(header: Text("备注")) {
						TextField("写点备注？", text: $formComment)
					}
					HStack {
						Spacer()
						Button {
							todayVM.editRecord(amount: formAmount, comment: formComment)
							isEdit = false
							formIsIncome = false
							formAmount = 0.0
							formComment = ""
						} label: {
							Text("完成")
						}
						Spacer()
					}
				}
				.navigationTitle("修改记录")
				.navigationBarTitleDisplayMode(.inline)
				.onSubmit {
					todayVM.editRecord(amount: formAmount, comment: formComment)
					isEdit = false
					formIsIncome = false
					formAmount = 0.0
					formComment = ""
				}
				.onDisappear {
					isEdit = false
					formAmount = 0.0
					formComment = ""
				}
			}
		}
	}
}

// 一条记录
fileprivate struct RecordView: View {
	let record: TodayData.Data// 一条记录的数据格式
	
	@State private var isShow: Bool = true
	
	var body: some View {
		HStack {
			if isShow {
				Text(genComment())
					.lineLimit(1)
				Spacer()
				Text(genAmountDiscription())
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
		if record.comment.count == 0 {
			return "记录"
		} else {
			return record.comment
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
