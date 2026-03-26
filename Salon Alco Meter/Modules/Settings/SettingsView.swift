import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) var context
    @State private var user: UserModel?
    @State private var waveSensitivity: Double = 50
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("Settings")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        WaveIntensityCard(sensitivity: $waveSensitivity, user: $user, context: context)
                        
                        MeasurementUnitsCard(user: $user, context: context)
                        
                        PrivacyCard(context: context)
                        
                        AboutCard()
                        
                        ImportantNoticeCard()
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .bg()
        }
        .onAppear {
            fetchOrCreateUser()
        }
    }
    
    private func fetchOrCreateUser() {
        let descriptor = FetchDescriptor<UserModel>()
        if let existingUser = try? context.fetch(descriptor).first {
            self.user = existingUser
            self.waveSensitivity = Double(existingUser.waveSens)
        } else {
            let newUser = UserModel(waveSens: 50, units: .ml)
            context.insert(newUser)
            try? context.save()
            self.user = newUser
            self.waveSensitivity = 50
        }
    }
}

struct WaveIntensityCard: View {
    @Binding var sensitivity: Double
    @Binding var user: UserModel?
    let context: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "water.waves")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wave Intensity")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Adjust animation sensitivity")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text("\(Int(sensitivity))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Slider(value: $sensitivity, in: 0...100, step: 1)
                .tint(.purple)
                .onChange(of: sensitivity) { oldValue, newValue in
                    if let user = user {
                        user.waveSens = Int(newValue)
                        try? context.save()
                    }
                }
            
            HStack {
                Text("Gentle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("Intense")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text("Lower intensity for sensitive vestibular systems")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.15))
        )
    }
}

struct MeasurementUnitsCard: View {
    @Binding var user: UserModel?
    let context: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Measurement Units")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Volume display preference")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            HStack(spacing: 12) {
                ForEach(Units.allCases, id: \.self) { unit in
                    Button(action: {
                        if let user = user {
                            user.units = unit
                            try? context.save()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(unit == .ml ? "Milliliters (ml)" : "Ounces (oz)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(user?.units == unit ? Color.purple : Color.white.opacity(0.1))
                        )
                        .foregroundColor(.white)
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

struct PrivacyCard: View {
    let context: ModelContext
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.red.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Privacy")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Local data storage only")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Button(action: {
                showConfirmation = true
            }) {
                Text("Clear Logbook")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.red.opacity(0.7))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.7), lineWidth: 1.5)
                    )
            }
            .alert("Clear Logbook", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearLogbook()
                }
            } message: {
                Text("Are you sure? This action cannot be undone.")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.15))
        )
    }
    
    private func clearLogbook() {
        let descriptor = FetchDescriptor<SwimModel>()
        if let swims = try? context.fetch(descriptor) {
            for swim in swims {
                context.delete(swim)
            }
            try? context.save()
        }
    }
}

struct AboutCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("About")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("App information")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Salon Alco Meter")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("translates intoxication into physical sensation through vestibular feedback.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text("\"Your body knows. Let it speak.\"")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.15))
        )
    }
}

struct ImportantNoticeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Important Notice")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 10) {
                Text("This app uses visual animations that may cause discomfort. Not recommended for people with vestibular disorders, epilepsy, or pregnancy.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                
                Text("Salon Alco Meter is not a medical device and does not replace professional advice. Alcohol harms your health.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.5), lineWidth: 1.5)
        )
    }
}
