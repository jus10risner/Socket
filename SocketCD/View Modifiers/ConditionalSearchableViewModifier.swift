//
//  ConditionalSearchableViewModifier.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct ConditionalSearchableViewModifier: ViewModifier {
    let isSearchable: Bool
    @Binding var searchString: String
    
    func body(content: Content) -> some View {
        switch isSearchable {
            case true:
                content
                    .searchable(text: $searchString)
            case false:
                content
        }
    }
}
