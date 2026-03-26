import SwiftData
import Foundation

struct DrinkModel: Codable {
    var id: UUID
    var date: Date
    var type: DrinkType
    var volume: Int
}

@Model
class SwimModel {
    var id = UUID()
    
    var date: Date
    var intakes: [DrinkModel]
    var isActive: Bool
    
    init(id: UUID = UUID(), date: Date, intakes: [DrinkModel], isActive: Bool) {
        self.id = id
        self.date = date
        self.intakes = intakes
        self.isActive = isActive
    }
}

enum Drink: String, CaseIterable, Codable {
    case beer, cider, seltzer, lightCoctail, otherLight
    case wine, champagne, port, strongCider, otherWine
    case longIsland, ginTonic, mojito, margarita, otherCoctail
    case vodka, cognac, whiskey, tekuila, otherStrong
    
    var drinkType: DrinkType {
        switch self {
        case .beer, .cider, .seltzer, .lightCoctail, .otherLight:
            .light
        case .wine, .champagne, .port, .strongCider, .otherWine:
            .medium
        case .longIsland, .ginTonic, .mojito, .margarita, .otherCoctail:
            .coctail
        case .vodka, .cognac, .whiskey, .tekuila, .otherStrong:
            .strong
        }
    }
    
    var displayName: String {
        switch self {
        case .beer: "Beer"
        case .cider: "Cider"
        case .seltzer: "Seltzer"
        case .lightCoctail: "Light Cocktail"
        case .otherLight: "Other Light Drink"
        case .wine: "Wine"
        case .champagne: "Champagne"
        case .port: "Port"
        case .strongCider: "Strong Cider"
        case .otherWine: "Other Wine"
        case .longIsland: "Long Island"
        case .ginTonic: "Gin & Tonic"
        case .mojito: "Mojito"
        case .margarita: "Margarita"
        case .otherCoctail: "Other Cocktail"
        case .vodka: "Vodka"
        case .cognac: "Cognac"
        case .whiskey: "Whiskey"
        case .tekuila: "Tequila"
        case .otherStrong: "Other Strong Drink"
        }
    }

    /// Оценка промилей на 100 мл
    /// Beer, cider, seltzer (4-6%) — 0.2
    /// Wine, champagne, port, strong cider (10-15%) — 1
    /// Cocktails (18-22%) — 2
    /// Vodka, cognac, whiskey, tequila (40%) — 5
    var promilePer100Ml: Double {
        switch self {
        case .beer, .cider, .seltzer, .lightCoctail, .otherLight:
            0.2
        case .wine, .champagne, .port, .strongCider, .otherWine:
            1
        case .longIsland, .ginTonic, .mojito, .margarita, .otherCoctail:
            2
        case .vodka, .cognac, .whiskey, .tekuila, .otherStrong:
            5
        }
    }
}

enum DrinkType: String, CaseIterable, Codable {
    case light, medium, coctail, strong
}
