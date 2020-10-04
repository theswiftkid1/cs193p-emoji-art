//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by theswiftkid_ on 8/9/20.
//  Copyright © 2020 theswiftkid_. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument

    private let defaultEmojiSize: CGFloat = 40

    var body: some View {
        VStack {
            HStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(document.palette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: defaultEmojiSize))
                                .onDrag {
                                    NSItemProvider(object: emoji as NSString)
                                }
                        }
                    }
                }

                Spacer()

                Image(systemName: "trash")
                    .font(.largeTitle)
                    .onDrop(of: ["public.text"], isTargeted: nil) { providers, location in
                        true
                    }
            }
            .padding(.horizontal)

            GeometryReader { geometry in
                ZStack {
                    Color
                        .white
                        .overlay(
                            OptionalImage(uiImage: document.backgroundImage)
                                .scaleEffect(zoomScale)
                                .offset(panOffset)
                        )
                        .onTapGesture(perform: deselectAllEmojis)
                        .gesture(doubleTapToZoom(in: geometry.size))

                    ForEach(document.emojis) { emoji in
                        ZStack {
                            emojiSelection(for: emoji)

                            Text(emoji.text)
                        }
                        .fixedSize()
                        .font(animatableWithSize: emojiScale(for: emoji))
                        .position(position(for: emoji, in: geometry.size))
                        .gesture(document.selectedEmojiIds.contains(emoji.id) ? moveEmojiGesture : nil)
                        .onTapGesture(perform: selectEmoji(emoji))
                    }
                }
                .clipped()
                .gesture(panGesture)
                .gesture(!document.selectedEmojiIds.isEmpty ? zoomEmojiGesture : nil)
                .gesture(document.selectedEmojiIds.isEmpty ? zoomGesture : nil)
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                    return drop(providers: providers, at: location)
                }
            }
        }
    }

    // MARK: Emojis Scale

    private func emojiScale(for emoji: EmojiArt.Emoji) -> CGFloat {
        let emojiScale = document.selectedEmojiIds.contains(matching: emoji.id) ? emojiZoomScale : 1.0
        return emoji.fontSize * zoomScale * emojiScale
    }

    @GestureState private var emojiZoomScale: CGFloat = 1.0

    private var zoomEmojiGesture: some Gesture {
        MagnificationGesture()
            .updating($emojiZoomScale) { (currentScale, emojiZoomScale, transaction) in
                emojiZoomScale = currentScale
            }
            .onEnded { finalZoomValue in
                for emojiId in document.selectedEmojiIds {
                    document.scaleEmoji(document.getEmoji(emojiId)!, by: finalZoomValue)
                }
            }
    }

    // MARK: Emojis Selection

    private var deselectAllEmojis: () -> Void {
        {
            document.clearSelectedEmojis()
        }
    }

    private func selectEmoji(_ emoji: EmojiArt.Emoji) -> () -> Void {
        {
            document.toggleSelectedEmoji(emoji.id)
        }
    }

    @ViewBuilder
    private func emojiSelection(for emoji: EmojiArt.Emoji) -> some View {
        if (document.selectedEmojiIds.contains(emoji.id)) {
            RoundedRectangle(cornerRadius: 10)
                .stroke(lineWidth: 2)
        } else {
            EmptyView()
        }
    }

    // MARK: Emojis Position

    @GestureState private var emojiOffset: CGSize = .zero

    private var moveEmojiGesture: some Gesture {
        DragGesture()
            .updating($emojiOffset) { currentEmojiOffset, emojiOffset, transaction in
                emojiOffset = currentEmojiOffset.translation
            }
            .onEnded { finalEmojiOffset in
                for emojiId in document.selectedEmojiIds {
                    document.moveEmoji(document.getEmoji(emojiId)!, by: finalEmojiOffset.translation)
                }
            }
    }

    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        if document.selectedEmojiIds.contains(emoji.id) {
            location = CGPoint(x: location.x + emojiOffset.width, y: location.y + emojiOffset.height)
        }
        return location
    }

    // MARK: General Scale

    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0

    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                steadyStateZoomScale *= finalGestureScale
            }
    }

    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(document.backgroundImage, in: size)
                }
            }
    }

    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0 && image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }


    // MARK: General Position

    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero

    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }

    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped \(url)")
            document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadFirstObject(ofType: String.self) { string in
                document.addEmoji(string, at: location, size: defaultEmojiSize)
            }
        }
        return found
    }
}
