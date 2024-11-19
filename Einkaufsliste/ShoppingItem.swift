//
//  ShoppingItem.swift
//  Einkaufsliste
//
//  Created by Maik Langer on 19.11.24.
//

import CoreData

@objc(ShoppingItem)
public class ShoppingItem: NSManagedObject, Identifiable {
    @NSManaged public var name: String?
    @NSManaged public var isChecked: Bool
    @NSManaged public var timestamp: Date?

    public var id: NSManagedObjectID { self.objectID }
}


