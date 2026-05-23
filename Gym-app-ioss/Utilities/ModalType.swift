//
//  ModalType.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/16/23.
//

import Foundation

enum ModalType: Identifiable{
    var id: String {
        switch self{
        case .add: return "add"
        case .update: return "update"
        }
    }
    case add
    case update(User)
}
