import Foundation
import SwiftData

@Model
class UserModel {
    var id = UUID()
    
    var waveSens: Int
    var units: Units
    
    init(id: UUID = UUID(), waveSens: Int, units: Units) {
        self.id = id
        self.waveSens = waveSens
        self.units = units
    }
}

enum Units: String, CaseIterable, Codable {
    case ml, oz
}
