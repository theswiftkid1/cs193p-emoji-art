//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by theswiftkid_ on 8/9/20.
//  Copyright © 2020 theswiftkid_. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @State private var chosenPalette: String
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    private let defaultEmojiSize: CGFloat = 40

    init(document: EmojiArtDocument) {
        self.document = document
        _chosenPalette = State(initialValue: document.defaultPalette)
    }

    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }

    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(chosenPalette.map { String($0) }, id: \.self) { paletteValue in
                            Text(paletteValue)
                                .font(Font.system(size: defaultEmojiSize))
                                .onDrag {
                                    NSItemProvider(object: paletteValue as NSString)
                                }
                        }
                    }
                }
            }

            GeometryReader { geometry in
                VStack {
                    ZStack {
                        Color
                            .white
                            .overlay(
                                OptionalImage(uiImage: document.backgroundImage)
                                    .scaleEffect(zoomScale)
                                    .offset(panOffset)
                            )
                            .gesture(doubleTapToZoom(in: geometry.size))
                            .onTapGesture(perform: deselectAllEmojis)


                        if isLoading {
                            Image(systemName: "hourglass").imageScale(.large).spinning()
                        } else {
                            ForEach(document.emojis) { emoji in
                                ZStack {
                                    emojiSelection(for: emoji)

                                    Text(emoji.text)
                                }
                                .fixedSize()
                                .font(animatableWithSize: emojiScale(for: emoji))
                                .position(position(for: emoji, in: geometry.size))
                                .gesture(moveEmojiGesture(singleEmojiId: emoji.id))
                                .onTapGesture(perform: selectEmoji(emoji))
                            }
                        }
                    }

                    HStack {
                        Spacer()
                        Button {
                            document.deleteSelectedEmojis()
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(Font.largeTitle)
                        }
                    }
                    .padding()
                }
                .clipped()
                .gesture(panGesture)
                .gesture(!document.selectedEmojiIds.isEmpty ? zoomEmojiGesture : nil)
                .gesture(document.selectedEmojiIds.isEmpty ? zoomGesture : nil)
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(self.document.$backgroundImage) { image in
                    zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: [UTType.image, UTType.plainText], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                    return dropToCanvas(providers: providers, at: location)
                }
                .navigationBarItems(
                    trailing:
                        Button {
                            if let url = UIPasteboard.general.url, url != document.backgroundURL {
                                confirmBackgroundPaste = true
                            } else {
                                explainBackgroundPaste = true
                            }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .imageScale(.large)
                                .alert(isPresented: $explainBackgroundPaste) {
                                    return Alert(
                                        title: Text("Paste Background"),
                                        message: Text("Copy the URL of an image to the clipboard and touch this button to make it the background of your document."),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                        }
                )
            }
            .zIndex(-1)
        }
        .alert(isPresented: $confirmBackgroundPaste) {
            return Alert(
                title: Text("Paste Background"),
                message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?"),
                primaryButton: .default(Text("OK")) {
                    document.backgroundURL = UIPasteboard.general.url
                },
                secondaryButton: .cancel()
            )
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

    private func moveEmojiGesture(singleEmojiId: Int) -> some Gesture {
        DragGesture()
            .onChanged { _ in
                document.setSingleEmoji(singleEmojiId)
            }
            .updating($emojiOffset) { currentEmojiOffset, emojiOffset, transaction in
                emojiOffset = currentEmojiOffset.translation
            }
            .onEnded { finalEmojiOffset in
                for emojiId in document.selectedEmojiIds {
                    document.moveEmoji(document.getEmoji(emojiId)!, by: finalEmojiOffset.translation)
                }
                if singleEmojiId == document.singleEmojiId && document.selectedEmojiIds.isEmpty {
                    document.moveEmoji(document.getEmoji(singleEmojiId)!, by: finalEmojiOffset.translation)
                    document.unsetSingleEmoji()
                }
            }
    }

    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        if document.selectedEmojiIds.contains(emoji.id) || document.singleEmojiId == emoji.id {
            location = CGPoint(x: location.x + emojiOffset.width, y: location.y + emojiOffset.height)
        }
        return location
    }

    // MARK: General Scale

    @GestureState private var gestureZoomScale: CGFloat = 1.0

    private var zoomScale: CGFloat {
        document.steadyStateZoomScale * gestureZoomScale
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                document.steadyStateZoomScale *= finalGestureScale
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
        if let image = image, image.size.width > 0 && image.size.height > 0
            && size.width > 0 && size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            document.steadyStatePanOffset = .zero
            document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }


    // MARK: General Position

    @GestureState private var gesturePanOffset: CGSize = .zero

    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                document.steadyStatePanOffset = document.steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }

    // MARK: Drop Actions

    private func dropToCanvas(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            document.backgroundURL = url
        }
        if !found {
            found = providers.loadFirstObject(ofType: String.self) { string in
                document.addEmoji(string, at: location, size: defaultEmojiSize)
            }
        }
        return found
    }
}
