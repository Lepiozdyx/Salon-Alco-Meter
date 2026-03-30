import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) var context
    @Query(sort: \SwimModel.date, order: .reverse) var swims: [SwimModel]
    @State private var selectedTab: Int = 0
    
    var filteredSwims: [SwimModel] {
        let now = Date()
        let calendar = Calendar.current
        
        if selectedTab == 0 {
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return swims.filter { $0.date >= monthAgo }
        } else {
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return swims.filter { $0.date >= yearAgo }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("Statistic")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                HStack(spacing: 12) {
                    Button(action: { selectedTab = 0 }) {
                        Text("Month")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == 0 ? Color.purple : Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { selectedTab = 1 }) {
                        Text("Year")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == 1 ? Color.purple : Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        BOOverTimeCard(swims: filteredSwims, selectedTab: selectedTab)
                        
                        ByCategoryCard(swims: filteredSwims)
                        
                        TopDrinksCard(swims: filteredSwims)
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .bg()
        }
    }
}

struct BOOverTimeCard: View {
    let swims: [SwimModel]
    let selectedTab: Int
    
    var dailyData: [(date: String, bo: Double)] {
        var data: [Date: Double] = [:]
        
        for swim in swims {
            let day = Calendar.current.startOfDay(for: swim.date)
            data[day, default: 0] = max(data[day, default: 0], swim.peakBO)
        }
        
        let sorted = data.sorted { $0.key < $1.key }
        return sorted.map { day, bo in
            let formatter = DateFormatter()
            if selectedTab == 0 {
                formatter.dateFormat = "MMM d"
            } else {
                formatter.dateFormat = "MMM"
            }
            return (formatter.string(from: day), bo)
        }
    }
    
    var maxBO: Double {
        dailyData.map { $0.bo }.max() ?? 12
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Effect Level Over Time")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            if dailyData.isEmpty {
                Text("No data available")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(height: 180)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Canvas { context, size in
                    let padding: CGFloat = 40
                    let chartWidth = size.width - padding - 20
                    let chartHeight = size.height - padding - 20
                    
                    let yMax = (maxBO * 1.2).rounded(.up)
                    let pointCount = max(dailyData.count, 1)
                    
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
                        for (index, data) in dailyData.enumerated() {
                            let x = padding + (chartWidth / CGFloat(pointCount - 1)) * CGFloat(index)
                            let normalizedBO = data.bo / yMax
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
                    
                    for (index, data) in dailyData.enumerated() {
                        let x: CGFloat
                        if pointCount == 1 {
                            x = padding + chartWidth / 2
                        } else {
                            x = padding + (chartWidth / CGFloat(pointCount - 1)) * CGFloat(index)
                        }
                        
                        let normalizedBO = data.bo / yMax
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
                    
                    for (index, data) in dailyData.enumerated() {
                        let text = Text(data.date)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.15))
        )
    }
}

struct ByCategoryCard: View {
    let swims: [SwimModel]
    
    var categoryStats: [DrinkType: Double] {
        var stats: [DrinkType: Double] = [:]
        
        for swim in swims {
            for intake in swim.intakes {
                let drinkBO = (Double(intake.volume) / 100.0) * intake.type.promilePer100Ml
                stats[intake.type, default: 0] += drinkBO
            }
        }
        
        return stats
    }
    
    var totalBO: Double {
        categoryStats.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                PieChart(data: categoryStats, totalBO: totalBO)
                    .frame(width: 120, height: 120)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(DrinkType.allCases, id: \.self) { type in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(categoryColor(for: type))
                                .frame(width: 12, height: 12)
                            
                            Text(type.displayName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(categoryColor(for: type))
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.15))
        )
    }
    
    private func categoryColor(for type: DrinkType) -> Color {
        switch type {
        case .light:
            return Color(red: 0.7, green: 0.5, blue: 1.0)
        case .medium:
            return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .coctail:
            return Color(red: 1.0, green: 0.6, blue: 0.5)
        case .strong:
            return Color(red: 0.9, green: 0.3, blue: 0.4)
        }
    }
}

struct PieChart: View {
    let data: [DrinkType: Double]
    let totalBO: Double
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            
            var startAngle: CGFloat = -CGFloat.pi / 2
            
            for type in DrinkType.allCases {
                let value = data[type] ?? 0
                let percentage = totalBO > 0 ? value / totalBO : 0
                let sliceAngle = percentage * 2 * .pi
                
                let endAngle = startAngle + sliceAngle
                
                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: false)
                path.closeSubpath()
                
                let color: Color
                switch type {
                case .light:
                    color = Color(red: 0.7, green: 0.5, blue: 1.0)
                case .medium:
                    color = Color(red: 1.0, green: 0.8, blue: 0.2)
                case .coctail:
                    color = Color(red: 1.0, green: 0.6, blue: 0.5)
                case .strong:
                    color = Color(red: 0.9, green: 0.3, blue: 0.4)
                }
                
                context.fill(path, with: .color(color))
                
                startAngle = endAngle
            }
        }
    }
}

struct TopDrinksCard: View {
    let swims: [SwimModel]
    
    var topDrinks: [(drink: Drink, count: Int, totalBO: Double)] {
        var drinkStats: [Drink: (count: Int, bo: Double)] = [:]
        
        for swim in swims {
            for intake in swim.intakes {
                let drinkBO = (Double(intake.volume) / 100.0) * intake.type.promilePer100Ml
                
                let drink = Drink.allCases.first(where: { $0.drinkType == intake.type }) ?? .beer
                
                if drinkStats[drink] != nil {
                    drinkStats[drink]?.count += 1
                    drinkStats[drink]?.bo += drinkBO
                } else {
                    drinkStats[drink] = (count: 1, bo: drinkBO)
                }
            }
        }
        
        var sorted = drinkStats.map { (drink: $0.key, count: $0.value.count, totalBO: $0.value.bo) }
        sorted.sort { $0.totalBO > $1.totalBO }
        return Array(sorted.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top 5 Drinks")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            if topDrinks.isEmpty {
                Text("No drinks recorded yet")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(topDrinks.enumerated()), id: \.element.drink) { index, item in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.purple)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.drink.displayName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(String(format: "%.1f total Effect Level", item.totalBO))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Text("×\(item.count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.15))
        )
    }
}

extension DrinkType {
    var displayName: String {
        switch self {
        case .light: "Light"
        case .medium: "Medium"
        case .coctail: "Cocktail"
        case .strong: "Strong"
        }
    }
    
    var promilePer100Ml: Double {
        switch self {
        case .light:
            0.2
        case .medium:
            1
        case .coctail:
            2
        case .strong:
            5
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: SwimModel.self, inMemory: true)
}
