//
//  DataManager.swift
//  test
//
//  Created by mad on 07.12.2019.
//  Copyright © 2019 Vladyslav Yatsun. All rights reserved.
//

import UIKit

enum Type: String, Decodable {
    
    case `default` = "tap to breathe"
    case initial = ""
    case inhale
    case exhale
    case hold

    var title: String {
        return self.rawValue.uppercased()
    }

    var scaleValue: CGFloat? {
        switch self {
        case .default:
            return 1.0
        case .initial:
            return 0.75
        case .inhale:
            return 1.0
        case .exhale:
            return 0.5
        case .hold:
            return nil
        }
    }

}

struct State: Decodable {

    let type: Type
    let color: UIColor
    let duration: TimeInterval

    private enum CodingKeys: String, CodingKey {
        case type
        case color
        case duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(Type.self, forKey: .type)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
        let hexString = try container.decode(String.self, forKey: .color)
        self.color = UIColor.colorWith(hexString: hexString)
    }

    private init(type: Type, color: UIColor, duration: TimeInterval) {
        self.type = type
        self.color = color
        self.duration = duration
    }

    fileprivate static var `default`: State {
        return State(type: .default, color: .red, duration: 1)
    }

    fileprivate static var initial: State {
        return State(type: .initial, color: .yellow, duration: 1)
    }
}

class DataManager {

    private let fileName = "data"
    private let fileType = "json"

    private(set) var states: [State] = []
    private(set) var breatheStatesDuration: TimeInterval = 0.0
    
    init() {
        self.loadData()
        self.breatheStatesDuration = self.states.reduce(0.0) { (result, state) -> TimeInterval in
            if self.isBreatheState(state) {
                return result + state.duration
            } else {
                return result
            }
        }
    }

    func isBreatheState(_ state : State) -> Bool {
        switch state.type {
        case .inhale, .exhale, .hold:
            return true
        default:
            return false
        }
    }

    private func loadData() {
        if let path = Bundle.main.path(forResource: self.fileName, ofType: self.fileType) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let newStates = try JSONDecoder().decode([State].self, from: data)
                self.states.append(State.initial)
                self.states.append(contentsOf: newStates)
                self.states.append(State.default)
            } catch {
                print("Read data error")
            }
        }
    }

}

