//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by theswiftkid_ on 9/27/20.
//  Copyright © 2020 theswiftkid_. All rights reserved.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        WindowGroup {
            let viewModel = EmojiArtDocument()
            EmojiArtDocumentView(document: viewModel)
        }
    }
}
