//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by theswiftkid_ on 8/9/20.
//  Copyright © 2020 theswiftkid_. All rights reserved.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject {
    // MARK: Generic vars
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    var singleEmojiId: Int? = nil
    let palette: String = "😄😆😅😂😍"
    private static let untitled = "EmojiArtDocument.untitled"
    private var autosaveCancellable: AnyCancellable?
    private var fetchImageCancellable: AnyCancellable?

    // MARK: Published vars
    @Published var selectedEmojiIds: Set<Int> = .init()
    @Published private var emojiArt: EmojiArt
    @Published private(set) var backgroundImage: UIImage?

    // MARK: Init

    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        autosaveCancellable = $emojiArt.sink { emojiArt in
            print("\(emojiArt.json?.utf8 ?? "nil")")
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
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

    var backgroundURL: URL? {
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
        get {
            emojiArt.backgroundURL
        }
    }

    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL {
            fetchImageCancellable?.cancel()
            fetchImageCancellable = URLSession.shared
                .dataTaskPublisher(for: url)
                .map { data, urlResponse in
                    UIImage(data: data)
                }
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .assign(to: \EmojiArtDocument.backgroundImage, on: self)
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(size) }

    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}
