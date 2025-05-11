//
//  DesignTokens.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import SwiftUI

enum DesignTokens {
    // Colors
    enum Colors {
        static let primary = Color("PrimaryColor")
        static let secondary = Color("SecondaryColor")
        static let background = Color("BackgroundColor")
        static let text = Color("TextColor")
        static let destructive = Color("DestructiveColor")
        static let success = Color("SuccessColor")
        static let warning = Color("WarningColor")
        static let info = Color("InfoColor")
        
        enum Provider {
            static let openAI = Color("OpenAIColor")
            static let anthropic = Color("AnthropicColor")
            static let groq = Color("GroqColor")
            static let perplexity = Color("PerplexityColor")
            static let deepSeek = Color("DeepSeekColor")
            static let openRouter = Color("OpenRouterColor")
        }
        
        enum Message {
            static let userBackground = Color.accentColor.opacity(0.8)
            static let userText = Color.white
            static let assistantBackground = Color(.systemGray6)
            static let assistantText = Color.primary
            static let systemBackground = Color(.systemGray4)
            static let systemText = Color.primary
        }
        
        enum Folder {
            static let blue = Color.blue
            static let green = Color.green
            static let orange = Color.orange
            static let purple = Color.purple
            static let red = Color.red
            static let teal = Color.teal
            static let yellow = Color.yellow
            static let pink = Color.pink
            
            static func color(from string: String) -> Color {
                switch string.lowercased() {
                case "blue": return .blue
                case "green": return .green
                case "orange": return .orange
                case "purple": return .purple
                case "red": return .red
                case "teal": return .teal
                case "yellow": return .yellow
                case "pink": return .pink
                default: return .blue
                }
            }
        }
    }
    
    // Typography
    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title, design: .rounded).weight(.bold)
        static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body)
        static let callout = Font.system(.callout)
        static let subheadline = Font.system(.subheadline)
        static let footnote = Font.system(.footnote)
        static let caption = Font.system(.caption)
        static let caption2 = Font.system(.caption2)
    }
    
    // Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // Border Radius
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xl: CGFloat = 16
        static let round: CGFloat = 999
    }
    
    // Animation
    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
    }
    
    // Shadow
    enum Shadow {
        static let small = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.15)
        static let large = Color.black.opacity(0.2)
        
        static let smallRadius: CGFloat = 4
        static let mediumRadius: CGFloat = 8
        static let largeRadius: CGFloat = 16
        
        static let smallY: CGFloat = 2
        static let mediumY: CGFloat = 4
        static let largeY: CGFloat = 8
    }
}