//
//  SubscriptionTier.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

enum SubscriptionTier: String, Codable, CaseIterable, Identifiable {
    case free
    case premium
    case lifetime
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        case .lifetime:
            return "Lifetime Premium"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "Access to basic models",
                "Limited messages per day",
                "Basic memory features",
                "Standard response times"
            ]
        case .premium:
            return [
                "Access to all models",
                "Unlimited messages",
                "Advanced memory system",
                "Priority response times",
                "Image generation",
                "Custom bot creation",
                "No ads"
            ]
        case .lifetime:
            return [
                "All Premium features",
                "One-time purchase",
                "Early access to new features",
                "Exclusive themes"
            ]
        }
    }
    
    var monthlyPrice: Decimal? {
        switch self {
        case .free:
            return nil
        case .premium:
            return 4.99
        case .lifetime:
            return nil
        }
    }
    
    var yearlyPrice: Decimal? {
        switch self {
        case .free:
            return nil
        case .premium:
            return 49.99
        case .lifetime:
            return 99.99
        }
    }
}