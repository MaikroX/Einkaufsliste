//
//  EinkaufslisteApp.swift
//  Einkaufsliste
//
//  Created by Maik Langer on 19.11.24.
//

import SwiftUI

@main
struct EinkaufslisteApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
