//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by theswiftkid on 9/27/20.
//  Copyright © 2020 theswiftkid. All rights reserved.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let url: URL
    let store: EmojiArtDocumentStore

    init() {
        url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        store = EmojiArtDocumentStore(directory: url)
        if store.documents.isEmpty {
            store.addDocument()
        }
    }

    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
        }
    }
}
