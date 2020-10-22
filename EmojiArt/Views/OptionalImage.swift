//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by theswiftkid_ on 9/30/20.
//  Copyright © 2020 theswiftkid_. All rights reserved.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?

    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}
