//
//  RekariApp.swift
//  Rekari
//
//  Created by development on 2024/06/15.
//

import SwiftUI

@main
struct RekariApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.commands {
            CommandGroup(replacing: .appInfo) {
                Button("MacNicoPlayer（Re:仮）について") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                                            string: "Copyright © 2024 あんのたん®",
                                                            attributes: [
                                                                NSAttributedString.Key.font: NSFont.systemFont(
                                                                    ofSize: NSFont.smallSystemFontSize)
                                                            ]
                                                        )
                        ]
                    )
                }
            }
        }
    }
}
