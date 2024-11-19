//
//  ContentView.swift
//  Einkaufsliste
//
//  Created by Maik Langer on 19.11.24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var newProductName: String = "" // Eingabefeld für den Produktnamen
    @State private var isAddingItem: Bool = false  // Steuerung, ob das Eingabefeld angezeigt wird
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Einkaufsliste.ShoppingItem.name, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Einkaufsliste.ShoppingItem>
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground) // Standard-Grauton von iOS
                    .ignoresSafeArea()
                // Liste der Produkte
                VStack {
                    List {
                        ForEach(items) { item in
                            HStack {
                                Text(item.name ?? "Unbenannt")
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(item.isChecked ? Color.green : Color.gray)
                                        .opacity(item.isChecked ? 1.0 : 0.5) // Verringert die Deckkraft des grauen Kreises
                                        .frame(width: 24, height: 24)
                                    if item.isChecked {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white) // Weißer Haken
                                    }
                                }
                            }
                            .onTapGesture {
                                withAnimation {
                                    item.isChecked.toggle() // Zustand ändern (abgehakt/nicht abgehakt)
                                    saveContext()
                                }
                            }
                        }
                        
                        .onDelete(perform: deleteItems)
                    }
                    .padding(.bottom, isAddingItem ? 190 :190)
                    
                    if items.isEmpty {
                        Text("Keine Einträge vorhanden")
                            .foregroundColor(.gray)
                    }
                }
                
                // Eingabefeld und schwebender Button
                VStack {
                    Spacer()
                    
                    // Eingabefeld erscheint, wenn `isAddingItem` aktiv ist
                    if isAddingItem {
                        HStack {
                            TextField("Produktname eingeben", text: $newProductName)
                                .padding() // Innenabstand
                                .background(Color(.white)) // Weißer Hintergrund
                                .cornerRadius(8) // Abgerundete Ecken
                                .foregroundColor(.black) // Textfarbe explizit auf Schwarz setzen
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1) // Grauer Rahmen
                                )
                                .padding(6.0)
                            
                            
                            Button("Hinzufügen") {
                                addItem() // Neuen Eintrag erstellen
                                isAddingItem = false // Eingabemodus beenden
                            }
                            .padding(.trailing)
                            .disabled(newProductName.isEmpty) // Button deaktiviert, wenn das Feld leer ist
                        }
                        .padding()
                    }
                    
                    
                    // Schwebe-Button unten mittig
                    Button(action: {
                        isAddingItem.toggle()
                    }) {
                        Image(systemName: "plus")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color(hex: "017eff")))
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 20) // Abstand vom unteren Bildschirmrand
                }
            }
            .navigationTitle("Einkaufsliste")
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = ShoppingItem(context: viewContext)
            newItem.name = newProductName // Nutzt den eingegebenen Produktnamen
            newItem.isChecked = false // Standardmäßig nicht abgehakt
            saveContext()
            newProductName = "" // Eingabefeld zurücksetzen
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
