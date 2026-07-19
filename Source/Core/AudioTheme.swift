import Foundation

enum AudioTheme: String, CaseIterable {
    case realNKCream
    case realHolyPanda
    case realTurquoise
    case realMXBlue
    case realMXBrown
    case realMXBlack
    case realCreamTravel
    
    var displayName: String {
        switch self {
        case .realNKCream: return "NK Cream"
        case .realHolyPanda: return "Holy Panda"
        case .realTurquoise: return "Turquoise"
        case .realMXBlue: return "Cherry MX Blue"
        case .realMXBrown: return "Cherry MX Brown"
        case .realMXBlack: return "Cherry MX Black"
        case .realCreamTravel: return "Cream Travel"
        }
    }
    
    var folderName: String {
        switch self {
        case .realNKCream: return "NKCream"
        case .realHolyPanda: return "HolyPanda"
        case .realTurquoise: return "Turquoise"
        case .realMXBlue: return "MXBlue"
        case .realMXBrown: return "MXBrown"
        case .realMXBlack: return "MXBlack"
        case .realCreamTravel: return "CreamTravel"
        }
    }
}
