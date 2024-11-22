//
//  ContentView.swift
//  Einkaufsliste
//
//  Created by Maik Langer on 19.11.24.
//

import SwiftUI
import CoreData

extension Color {
    static let background = Color(UIColor.systemBackground) // Passt sich an den Hell-/Dunkelmodus an
}
extension Color {
    static let separator = Color(UIColor.separator)
}



struct ContentView: View {
    @State private var newProductName: String = "" // Eingabefeld für den Produktnamen
    @State private var isAddingItem: Bool = false  // Steuerung, ob das Eingabefeld angezeigt wird
    @State private var editingItem: ShoppingItem? = nil
    @State private var keyboardHeight: CGFloat = 0 // Höhe der Tastatur
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Einkaufsliste.ShoppingItem.name, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Einkaufsliste.ShoppingItem>
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) { // Alignment sorgt für bessere Platzierung
                
                // Hintergrundfarbe
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Liste der Produkte
                VStack(spacing: 0) {
                    List {
                        ForEach(items) { item in
                            HStack {
                                if editingItem == item {
                                    // Textfeld für Live-Bearbeitung
                                    TextField("Produktname eingeben", text: Binding(
                                        get: { item.name ?? "" },
                                        set: { item.name = $0 }
                                    ))
                                    .padding(6)
                                    .padding(.leading, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20) // Abgerundeter Rahmen
                                            .fill(Color(.systemGray6)))
                                    .onSubmit {
                                        saveContext()
                                        editingItem = nil
                                    }
                                } else {
                                    Text(item.name ?? "Unbenannt")
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(item.isChecked ? Color.green : Color.gray)
                                        .opacity(item.isChecked ? 1.0 : 0.5)
                                        .frame(width: 24, height: 24)
                                    if item.isChecked {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .onTapGesture {
                                withAnimation {
                                    item.isChecked.toggle()
                                    saveContext()
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                                
                                Button {
                                    editingItem = item
                                } label: {
                                    Label("Bearbeiten", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    
                    if items.isEmpty {
                        Text("Keine Einträge vorhanden")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom,0) // Platz für Tastatur
                
                // Eingabefeld für neues Item
                if isAddingItem {
                    VStack {
                        HStack {
                            TextField("Produktname eingeben", text: $newProductName)
                            
                                .padding(6)
                                .padding(.leading, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20) // Abgerundeter Rahmen
                                        .fill(Color(.systemGray6)))
                            
                            
                            Button("Hinzufügen") {
                                addItem()
                                isAddingItem = false
                            }
                            
                            .disabled(newProductName.isEmpty)
                        }
                        .padding(12)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.background)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1) // Höhe des oberen Rahmens
                                    .foregroundColor(Color.separator) // Farbe des Rahmens
                                    .padding(.top, -1), // Position direkt oben
                                alignment: .top // Am oberen Rand ausrichten
                            )// Erweiterung verwenden
                    )
                    .animation(.easeOut, value: keyboardHeight)
                }
                
                // Schwebe-Button
                if !isAddingItem {
                    Button(action: {
                        isAddingItem = true
                    }) {
                        Image(systemName: "plus")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color(hex: "017eff")))
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, keyboardHeight + 20) // Dynamisch oberhalb der Tastatur
                    .animation(.easeOut, value: keyboardHeight)
                }
            }
            .navigationTitle("Einkaufsliste")
            .onAppear {
                startObservingKeyboard() // Beobachten der Tastatur
            }
            .onDisappear {
                stopObservingKeyboard() // Beenden der Beobachtung
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = ShoppingItem(context: viewContext)
            newItem.name = newProductName
            newItem.isChecked = false
            saveContext()
            newProductName = ""
        }
    }
    
    private func deleteItem(_ item: ShoppingItem) {
        viewContext.delete(item)
        saveContext()
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
    
    private func startObservingKeyboard() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                let screenHeight = UIScreen.main.bounds.height
                self.keyboardHeight = max(0, screenHeight - frame.origin.y)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.keyboardHeight = 0
        }
    }
    
    private func stopObservingKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
