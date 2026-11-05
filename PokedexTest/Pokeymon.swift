//
//  Pokeymon.swift
//  Pokedex
//
//  Created by Claude Code
//

import UIKit

enum PokeymonType: String, CaseIterable {
    case fire
    case water
    case earth
    case grass
    case electric
    case ice
    case flying
    case psychic

    var emoji: String {
        switch self {
        case .fire: return "🔥"
        case .water: return "💧"
        case .earth: return "🪨"
        case .grass: return "🌿"
        case .electric: return "⚡️"
        case .ice: return "❄️"
        case .flying: return "🪽"
        case .psychic: return "🔮"
        }
    }
}

// MARK: Had to put nonisolated keyword here
nonisolated class Pokeymon {
    var name: String
    var type: PokeymonType
    var attack: Int
    var defense: Int
    var dateCaptured: Date

    init(name: String, type: PokeymonType, attack: Int, defense: Int, dateCaptured: Date = Date()) {
        self.name = name
        self.type = type
        self.attack = attack
        self.defense = defense
        self.dateCaptured = dateCaptured
    }
}
