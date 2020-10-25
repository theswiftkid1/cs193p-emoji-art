//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by theswiftkid on 10/22/20.
//  Copyright © 2020 theswiftkid. All rights reserved.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    @Binding var chosenPalette: String
    @State private var showPaletteEditor: Bool = false

    var body: some View {
        HStack {
            Stepper(
                onIncrement: {
                    chosenPalette = document.palette(after: chosenPalette)
                },
                onDecrement: {
                    chosenPalette = document.palette(before: chosenPalette)
                },
                label: {
                    EmptyView()
                })
            Text(document.paletteNames[chosenPalette] ?? "")
            Image(systemName: "gear")
                .imageScale(.large)
                .onTapGesture {
                    showPaletteEditor = true
                }
                .popover(isPresented: $showPaletteEditor) {
                    PaletteEditor(chosenPalette: $chosenPalette, isShowing: $showPaletteEditor)
                        .environmentObject(document)
                        .frame(minWidth: 300, minHeight: 500)
                }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct PaletteEditor: View {
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var chosenPalette: String
    @Binding var isShowing: Bool
    @State private var emojisToAdd: String = ""
    @State private var paletteName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Palette Editor")
                    .font(.headline)
                    .padding()
                HStack {
                    Spacer()
                    Button {
                        isShowing = false
                    } label: {
                        Text("Done")
                    }
                    .padding()
                }
            }

            Divider()

            Form {
                Section {
                    TextField("Palette Name", text: $paletteName, onEditingChanged: { began in
                        if !began {
                            document.renamePalette(chosenPalette, to: paletteName)
                        }
                    })

                    TextField("Add Emoji", text: $emojisToAdd, onEditingChanged: { began in
                        if !began {
                            document.addEmoji(emojisToAdd, toPalette: chosenPalette)
                            emojisToAdd = ""
                        }
                    })
                }

                Section(header: Text("Remove Emoji")) {
                    Grid(chosenPalette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: fontSize))
                            .onTapGesture {
                                chosenPalette = document.removeEmoji(emoji, fromPalette: chosenPalette)
                            }
                    }
                    .frame(height: height)
                }
            }
        }.onAppear {
            paletteName = document.paletteNames[chosenPalette] ?? "" 
        }
    }

    // MARK: - Drawing Constants

    let fontSize: CGFloat = 40

    var height: CGFloat {
        CGFloat((chosenPalette.count - 1) / 6 * 70 + 70)
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}
