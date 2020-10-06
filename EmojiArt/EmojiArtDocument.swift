//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by theswiftkid_ on 8/9/20.
//  Copyright © 2020 theswiftkid_. All rights reserved.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    // MARK: Generic vars
    private static let untitled = "EmojiArtDocument.untitled"
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    var singleEmojiId: Int? = nil
    let palette: String = "😄😆😅😂😍"

    // MARK: Published vars
    @Published var selectedEmojiIds: Set<Int> = .init()
    @Published private var emojiArt: EmojiArt {
        didSet {
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    @Published private(set) var backgroundImage: UIImage?


    // MARK: Init

    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        fetchBackgroundImageData()
    }

    // MARK: Intents

    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }

    func getEmoji(_ id: Int) -> EmojiArt.Emoji? {
        for emoji in emojis {
            if emoji.id == id {
                return emoji
            }
        }
        return nil
    }

    func toggleSelectedEmoji(_ id: Int) {
        selectedEmojiIds.toggleElement(element: id)
    }

    func setSingleEmoji(_ id: Int) {
        if singleEmojiId == nil {
            singleEmojiId = id
        }
    }

    func unsetSingleEmoji() {
        singleEmojiId = nil
    }

    func clearSelectedEmojis() {
        selectedEmojiIds = []
    }

    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }

    func deleteSelectedEmojis() {
        for id in selectedEmojiIds {
            emojiArt.deleteEmoji(id: id)
        }
        selectedEmojiIds.removeAll()
    }

    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }

    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }

    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(size) }

    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}
