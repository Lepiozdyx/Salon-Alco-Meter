import SwiftUI
import Observation
import SwiftData
import Foundation

@Observable
@MainActor
class SeaViewModel {
    var context: ModelContext
    var selectedType: DrinkType = .light
    var selectedDrink: Drink = .beer
    var volumeText: String = ""
    var activeSwim: SwimModel? = nil
    var showCritical: Bool = false
    var user: UserModel? = nil

    init(context: ModelContext) {
        self.context = context
        fetchOrCreateUser()
        fetchActiveSwim()
    }
    
    func fetchOrCreateUser() {
        let descriptor = FetchDescriptor<UserModel>()
        if let existingUser = try? context.fetch(descriptor).first {
            self.user = existingUser
        } else {
            let newUser = UserModel(waveSens: 50, units: .ml)
            context.insert(newUser)
            try? context.save()
            self.user = newUser
        }
    }
    
    func fetchActiveSwim() {
        let descriptor = FetchDescriptor<SwimModel>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let swim = try? context.fetch(descriptor).first {
            self.activeSwim = swim
        }
    }
    
    func addDrink() {
        guard let volume = Int(volumeText), volume > 0 else { return }
        
        if activeSwim == nil {
            let newSwim = SwimModel(date: Date(), intakes: [], isActive: true)
            context.insert(newSwim)
            activeSwim = newSwim
        }
        
        guard let swim = activeSwim else { return }
        
        let drinkModel = DrinkModel(
            id: UUID(),
            date: Date(),
            type: selectedDrink.drinkType,
            volume: volume
        )
        
        swim.intakes.append(drinkModel)
        try? context.save()
        
        volumeText = ""
        
        if totalBO >= 4.0 {
            showCritical = true
        }
    }

    func drinksForSelectedType() -> [Drink] {
        Drink.allCases.filter { $0.drinkType == selectedType }
    }

    var totalBO: Double {
        guard let swim = activeSwim else { return 0 }
        var sum: Double = 0
        
        for intake in swim.intakes {
            let drinkBO = (Double(intake.volume) / 100.0) * getDrinkPromille(for: intake.type)
            sum += drinkBO
        }
        
        return sum
    }
    
    var volumeLabel: String {
        user?.units == .ml ? "Volume (ml):" : "Volume (oz):"
    }
    
    private func getDrinkPromille(for type: DrinkType) -> Double {
        let drinks = Drink.allCases.filter { $0.drinkType == type }
        return drinks.first?.promilePer100Ml ?? 0
    }
}

struct SeaView: View {
    @State private var viewModel: SeaViewModel

    init(context: ModelContext) {
        _viewModel = State(initialValue: SeaViewModel(context: context))
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Color.clear.frame(width: 80.fitW, height: 1)
                    Spacer()
                    Text("Sea")
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        if let swim = viewModel.activeSwim {
                            swim.isActive = false
                            try? viewModel.context.save()
                            viewModel.activeSwim = nil
                            viewModel.fetchActiveSwim()
                        }
                    }) {
                        Text("Finish")
                            .font(.headline).foregroundColor(.white)
                            .padding(.vertical, 4.fitH)
                            .frame(width: 80.fitW)
                            .background(.purple)
                            .cornerRadius(12.fitH)
                    }
                    .disabled(viewModel.activeSwim == nil)
                    .opacity(viewModel.activeSwim == nil ? 0.5 : 1)
                }
                .padding(.horizontal)
                
                ScrollView {
                    ZStack(alignment: .bottom) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 18)
                            Image(.shipAsset)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 140.fitH)
                                .padding(.bottom, 0)
                            WaveView(intensity: viewModel.user?.waveSens ?? 50)
                                .frame(height: 46.fitH)
                                .offset(y: -14.fitH)
                        }
                    }
                    
                    VStack(spacing: 15) {
                        Text("Total Effect Level")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.80))
                        Text("\(String(format: "%.1f", viewModel.totalBO))")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 6)
                        
                        HStack(spacing: 10) {
                            ForEach(DrinkType.allCases, id: \.self) { type in
                                Button(action: { viewModel.selectedType = type }) {
                                    VStack(spacing: 0) {
                                        Image(type.symbolName)
                                            .resizable()
                                            .frame(width: 28.fitH, height: 28.fitH)
                                        Text(type.displayName)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(viewModel.selectedType == type ? .white : .white.opacity(0.4))
                                    .frame(width: 68, height: 58)
                                    .background(viewModel.selectedType == type ? Color.purple : Color.white.opacity(0.07))
                                    .cornerRadius(17)
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Select Drink")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                            Menu {
                                ForEach(viewModel.drinksForSelectedType(), id: \.self) { drink in
                                    Button(drink.displayName) {
                                        viewModel.selectedDrink = drink
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedDrink.displayName)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .font(.system(size: 17, weight: .medium))
                                .padding()
                                .background(Color.purple.opacity(0.31))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.volumeLabel)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                            TextField("0", text: $viewModel.volumeText)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.purple.opacity(0.21))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        Button(action: {
                            viewModel.addDrink()
                        }) {
                            Text("+ Add Drink")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(15)
                                .opacity(viewModel.volumeText.isEmpty ? 0.44 : 1)
                        }
                        .disabled(viewModel.volumeText.isEmpty)
                    }
                    .padding()
                }
            }
            
            if viewModel.showCritical {
                Color.black.opacity(0.58)
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    Button {
                        viewModel.showCritical = false
                    } label: {
                        Image(.criticalEtention)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeIn(duration: 0.15), value: viewModel.showCritical)
            }
        }
        .bg()
        .hideKeyboardOnTap()
    }
}

extension DrinkType {
    var symbolName: String {
        return self.rawValue
    }
}

import SwiftUI

struct WaveView: View {
    let intensity: Int
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let intensityMultiplier = Double(intensity) / 50.0
            let phase1 = CGFloat(now * 0.9 * intensityMultiplier)
            let phase2 = CGFloat(now * 1.35 * intensityMultiplier)
            ZStack {
                WaveShape(amplitude: 14, waveLength: 180, phase: phase1)
                    .stroke(Color.purple.opacity(0.62), lineWidth: 4)
                    .frame(height: 46)
                WaveShape(amplitude: 7, waveLength: 120, phase: -phase2)
                    .stroke(Color.white.opacity(0.63), lineWidth: 2)
                    .frame(height: 27)
            }
        }
        .padding(.vertical, 18)
    }
}

struct WaveShape: Shape {
    var amplitude: CGFloat
    var waveLength: CGFloat
    var phase: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midHeight = rect.height / 2
        let width = rect.width
        path.move(to: .zero)
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / waveLength
            let y = midHeight + sin(relativeX * 2 * .pi + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
