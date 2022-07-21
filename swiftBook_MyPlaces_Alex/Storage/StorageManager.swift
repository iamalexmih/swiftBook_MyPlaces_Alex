//
//  StorageManager.swift
//  swiftBook_MyPlaces_Alex
//
//  Created by Алексей Попроцкий on 12.07.2022.
//

import RealmSwift

let realm = try! Realm()


class StorageManager {
    
    static func saveObject(_ place: Place) {
            try! realm.write {
            realm.add(place)
        }
    }
    
    static func deleteObject(_ place: Place) {
        try! realm.write({
            realm.delete(place)
        })
    }
}
