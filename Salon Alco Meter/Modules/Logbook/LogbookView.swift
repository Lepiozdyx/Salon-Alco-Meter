import SwiftUI
import SwiftData

struct LogbookView: View {
    @Environment(\.modelContext) var context
    weak var tabDelegate: TabBarDelegate?
    @Query(sort: \SwimModel.date, order: .reverse) var swims: [SwimModel]
    @State private var selectedSwim: SwimModel? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("Logbook")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer().frame(height: 13)
                Text("Your voyage history")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundColor(.white.opacity(0.63))
                Spacer().frame(height: 25)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        if let record = absoluteRecord(swims: swims) {
                            AbsoluteRecordCard(record: record)
                        }
                        Text("VOYAGE HISTORY")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 3)
                        if swims.isEmpty {
                            NoHistoryCard()
                                .padding(.top, 8)
                        } else {
                            ForEach(swims, id: \.id) { swim in
                                SwimHistoryCard(swim: swim)
                                    .onTapGesture {
                                        selectedSwim = swim
                                    }
                            }
                        }
                        Spacer(minLength: 34)
                    }
                    .padding(.horizontal, 14)
                }
                Spacer()
                Button(action: {
                    tabDelegate?.showSea()
                }) {
                    Text("New swim")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 17)
                                .fill(Color.purple)
                        )
                        .padding(.horizontal, 18)
                }
                .padding(.vertical, 8)
            }
            .bg()
            
            if let swim = selectedSwim {
                VoyageDetailsOverlay(swim: swim, isPresented: $selectedSwim)
            }
        }
    }

    func absoluteRecord(swims: [SwimModel]) -> SwimModel? {
        swims.max { $0.peakBO < $1.peakBO }
    }
}

struct VoyageDetailsOverlay: View {
    let swim: SwimModel
    @Binding var isPresented: SwimModel?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = nil
                }
            
            VStack(spacing: 0) {
                HStack {
                    Text("Voyage Details")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        isPresented = nil
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
                
                Text(swim.dateWithTime)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                HStack(spacing: 12) {
                    StatCard(title: "Peak BO", value: String(format: "%.1f", swim.peakBO))
                    StatCard(title: "Drinks", value: "\(swim.drinkCount)")
                    StatCard(title: "Duration", value: swim.durationText)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Voyage Details")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    BOChart(swim: swim)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.15))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#1a0d2e"))
                    .stroke(Color.purple.opacity(0.5), lineWidth: 1.5)
            )
            .padding(20)
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
        )
    }
}

struct BOChart: View {
    let swim: SwimModel
    
    var chartPoints: [(index: Int, time: String, bo: Double)] {
        let sortedIntakes = swim.intakes.sorted { $0.date < $1.date }
        
        var points: [(Int, String, Double)] = []
        var cumulativeBO: Double = 0
        
        for (index, intake) in sortedIntakes.enumerated() {
            let drinkBO = (Double(intake.volume) / 100.0) * intake.type.promilePer100Ml
            cumulativeBO += drinkBO
            
            let timeMinutes = Int(intake.date.timeIntervalSince(swim.date) / 60)
            let timeLabel = timeMinutes > 0 ? "+\(timeMinutes)m" : "0m"
            
            points.append((index, timeLabel, cumulativeBO))
        }
        
        return points
    }
    
    var maxBO: Double {
        chartPoints.map { $0.bo }.max() ?? 12
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if chartPoints.isEmpty {
                Text("No intakes recorded")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(height: 180)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Canvas { context, size in
                    let padding: CGFloat = 45
                    let chartWidth = size.width - padding - 20
                    let chartHeight = size.height - padding - 20
                    
                    let yMax = (maxBO * 1.2).rounded(.up)
                    let pointCount = max(chartPoints.count, 1)
                    
                    var gridPath = Path()
                    for i in 0..<5 {
                        let y = padding + (chartHeight / 4) * CGFloat(i)
                        gridPath.move(to: CGPoint(x: padding, y: y))
                        gridPath.addLine(to: CGPoint(x: size.width - 10, y: y))
                    }
                    
                    if pointCount > 1 {
                        for i in 0..<pointCount {
                            let x = padding + (chartWidth / CGFloat(pointCount - 1)) * CGFloat(i)
                            gridPath.move(to: CGPoint(x: x, y: padding))
                            gridPath.addLine(to: CGPoint(x: x, y: size.height - 20))
                        }
                    }
                    
                    context.stroke(
                        gridPath,
                        with: .color(Color.purple.opacity(0.15)),
                        lineWidth: 0.8
                    )
                    
                    var axisPath = Path()
                    axisPath.move(to: CGPoint(x: padding, y: size.height - 20))
                    axisPath.addLine(to: CGPoint(x: size.width - 10, y: size.height - 20))
                    axisPath.move(to: CGPoint(x: padding, y: padding))
                    axisPath.addLine(to: CGPoint(x: padding, y: size.height - 20))
                    
                    context.stroke(
                        axisPath,
                        with: .color(Color.white.opacity(0.3)),
                        lineWidth: 1.2
                    )
                    
                    if pointCount > 1 {
                        var linePath = Path()
                        for (index, point) in chartPoints.enumerated() {
                            let x = padding + (chartWidth / CGFloat(pointCount - 1)) * CGFloat(index)
                            let normalizedBO = point.bo / yMax
                            let y = size.height - 20 - (normalizedBO * chartHeight)
                            
                            if index == 0 {
                                linePath.move(to: CGPoint(x: x, y: y))
                            } else {
                                linePath.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        
                        context.stroke(
                            linePath,
                            with: .color(Color.purple),
                            lineWidth: 2.5
                        )
                    }
                    
                    for (index, point) in chartPoints.enumerated() {
                        let x: CGFloat
                        if pointCount == 1 {
                            x = padding + chartWidth / 2
                        } else {
                            x = padding + (chartWidth / CGFloat(pointCount - 1)) * CGFloat(index)
                        }
                        
                        let normalizedBO = point.bo / yMax
                        let y = size.height - 20 - (normalizedBO * chartHeight)
                        
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)),
                            with: .color(Color.purple)
                        )
                    }
                    
                    for i in 0..<5 {
                        let yValue = Int((yMax / 4) * CGFloat(4 - i))
                        let text = Text("\(yValue)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        let y = padding + (chartHeight / 4) * CGFloat(i)
                        context.draw(text, at: CGPoint(x: padding - 35, y: y - 5))
                    }
                    
                    for (index, point) in chartPoints.enumerated() {
                        let text = Text(point.time)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        let x: CGFloat
                        if pointCount == 1 {
                            x = padding + chartWidth / 2
                        } else {
                            x = padding + (chartWidth / CGFloat(pointCount - 1)) * CGFloat(index)
                        }
                        
                        context.draw(text, at: CGPoint(x: x - 12, y: size.height - 5))
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

extension SwimModel {
    var peakBO: Double {
        var maxBO: Double = 0
        var cumulativeBO: Double = 0
        
        for intake in intakes.sorted(by: { $0.date < $1.date }) {
            let drinkBO = (Double(intake.volume) / 100.0) * intake.type.promilePer100Ml
            cumulativeBO += drinkBO
            maxBO = max(maxBO, cumulativeBO)
        }
        
        return maxBO
    }

    var drinkCount: Int {
        intakes.count
    }

    var dateFormatted: String {
        date.formatted(style: .medium)
    }
    
    var dateWithTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    var durationText: String {
        guard let firstIntake = intakes.min(by: { $0.date < $1.date }),
              let lastIntake = intakes.max(by: { $0.date < $1.date }) else {
            return "0 min"
        }
        let mins = Int(lastIntake.date.timeIntervalSince(firstIntake.date) / 60)
        return "\(mins) min"
    }
}

extension Date {
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct AbsoluteRecordCard: View {
    let record: SwimModel
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 17, weight: .bold))
                Text("Absolute Record")
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            HStack {
                Text(String(format: "%.1f BO", record.peakBO))
                    .foregroundColor(.white)
                    .font(.system(size: 27, weight: .bold))
                    .padding(.vertical, 1)
                Spacer()
            }
            HStack {
                Text(record.date.formatted(style: .medium))
                    .foregroundColor(.white.opacity(0.72))
                    .font(.system(size: 15, weight: .medium))
                Spacer()
            }
        }
        .frame(alignment: .leading)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.3))
        )
        .padding(.bottom, 7)
    }
}

struct NoHistoryCard: View {
    var body: some View {
        VStack(spacing: 9) {
            Text("NO VOYAGES RECORDED YET")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white.opacity(0.54))
            Text("Start tracking your drinks on the Sea screen")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.purple.opacity(0.28), lineWidth: 2.2)
                .background(Color.clear)
        )
    }
}

struct SwimHistoryCard: View {
    let swim: SwimModel

    var borderColor: Color {
        if swim.peakBO >= 8 {
            return .red
        } else if swim.peakBO >= 4 {
            return .yellow
        } else {
            return .green
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            Image(systemName: "calendar")
                .foregroundColor(borderColor)
                .font(.system(size: 27, weight: .semibold))
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(swim.date.formatted(style: .medium))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(swim.drinkCount) drinks")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.77))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", swim.peakBO))
                    .foregroundColor(borderColor)
                    .font(.system(size: 20, weight: .bold))
                Text("Peak BO")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.66))
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 9)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .stroke(borderColor.opacity(0.77), lineWidth: 2.1)
                .background(Color.clear)
        )
        .padding(.bottom, 12)
    }
}
