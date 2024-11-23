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
    @State private var showAlert: Bool = false     // Zustand für das Alert
    @FocusState private var focusedItemID: NSManagedObjectID? // Steuerung des Fokus auf eine Zeile
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Einkaufsliste.ShoppingItem.name, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Einkaufsliste.ShoppingItem>
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Hintergrundfarbe
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if items.isEmpty {
                    VStack {
                        Spacer()
                        Text("Deine Einkaufsliste ist leer")
                            .foregroundColor(.gray)
                            .font(.headline)
                            .padding(.bottom, 80)
                        Spacer()
                    }
                }
                
                VStack(spacing: 0) {
                    List {
                        ForEach(items, id: \.objectID) { item in
                            HStack {
                                if editingItem == item {
                                    TextField("Produktname ändern", text: Binding(
                                        get: { item.name ?? "" },
                                        set: { item.name = $0 }
                                    ))
                                    .padding(6)
                                    .padding(.leading, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(.systemGray6))
                                    )
                                    .focused($focusedItemID, equals: item.objectID) // Fokus auf diese Zeile setzen
                                    .onAppear {
                                        focusedItemID = item.objectID // Fokus aktivieren
                                    }
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
                                    focusedItemID = item.objectID // Fokus setzen, wenn auf Bearbeiten geklickt wird
                                } label: {
                                    Label("Bearbeiten", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                .padding(.bottom, 0) // Platz für Tastatur
                
                // Eingabefeld für neues Item
                if isAddingItem {
                    VStack {
                        HStack {
                            TextField("Produktname eingeben", text: $newProductName)
                                .padding(6)
                                .padding(.leading, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemGray6)))
                            
                            Button(action: {
                                addItem()
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
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
                            .ignoresSafeArea(edges: .bottom)
                    )
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
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Meine Einkaufsliste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !items.isEmpty {
                        Button(action: {
                            showAlert = true // Alert anzeigen
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .alert("Einkaufsliste leeren?", isPresented: $showAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    deleteAllItems()
                }
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
    
    private func deleteAllItems() {
        withAnimation {
            for item in items {
                viewContext.delete(item)
            }
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
