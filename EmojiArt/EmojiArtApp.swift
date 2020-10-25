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
    let store = EmojiArtDocumentStore(named: "EmojiArt")

    init() {
        store.addDocument()
        store.addDocument(named: "Hello World!")
    }

    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
        }
    }
}
