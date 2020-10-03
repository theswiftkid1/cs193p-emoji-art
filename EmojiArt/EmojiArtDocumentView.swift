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
    @State var selectedEmojis: [EmojiArt.Emoji] = []

    private let defaultEmojiSize: CGFloat = 40

    var body: some View {
        VStack {
            HStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) { emoji in
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
                        .onTapGesture(perform: selectEmoji(emoji))
                        .onDrag {
                            NSItemProvider(object: emoji.text as NSString)
                        }
                        .font(animatableWithSize: emojiScale(for: emoji))
                        .position(position(for: emoji, in: geometry.size))
                    }
                }
                .clipped()
                .gesture(panGesture)
//                .gesture(selectedEmojis.isEmpty ? zoomGesture.exclusively(before: dragSelectedEmojis) : nil)
                .gesture(!selectedEmojis.isEmpty ? emojiZoomGesture : nil)
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
        let emojiScale = selectedEmojis.contains(matching: emoji) ? emojiZoomScale : 1.0
        return emoji.fontSize * zoomScale * emojiScale
    }

    @GestureState private var emojiZoomScale: CGFloat = 1.0

    private var emojiZoomGesture: some Gesture {
        MagnificationGesture()
            .updating($emojiZoomScale) { (currentScale, emojiZoomScale, transaction) in
                emojiZoomScale = currentScale
            }
            .onEnded { finalZoomValue in
                for emoji in selectedEmojis {
                    document.scaleEmoji(emoji, by: finalZoomValue)
                }
            }
    }

    // MARK: Emojis Selection

    private var deselectAllEmojis: () -> Void {
        {
            selectedEmojis = []
        }
    }

    private func selectEmoji(_ emoji: EmojiArt.Emoji) -> () -> Void {
        {
            if let selectedEmojiIndex = selectedEmojis.firstIndex(of: emoji) {
                selectedEmojis.remove(at: selectedEmojiIndex)
            } else {
                selectedEmojis.append(emoji)
            }
        }
    }

    @ViewBuilder
    private func emojiSelection(for emoji: EmojiArt.Emoji) -> some View {
        if (selectedEmojis.contains(emoji)) {
            RoundedRectangle(cornerRadius: 10)
                .stroke(lineWidth: 2)
        } else {
            EmptyView()
        }
    }

    // MARK: Emojis Position

    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
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
