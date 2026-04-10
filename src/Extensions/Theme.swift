import SwiftUI

extension Color {
    enum theme {
        static let primary = Color(red: 0.275, green: 0.69, blue: 0.396)     // #46B065
        static let inProgress = Color(red: 0.0, green: 0.478, blue: 1.0)     // #007AFF
        static let warning = Color(red: 1.0, green: 0.584, blue: 0.0)        // #FF9500
    }
}

// Backward compatibility
typealias Theme = Color.theme
