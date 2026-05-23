//
//  ExcercisesViewModel.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/16/23.
//
import Combine


class ListViewModel: ObservableObject {
    @Published var items: [ExcListItem]
    
    init(items: [ExcListItem]) {
        self.items = items
    }
    
    func toggleExpand(for item: ExcListItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isExpanded.toggle()
        }
    }
}
