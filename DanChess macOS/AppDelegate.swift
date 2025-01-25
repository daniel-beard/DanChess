//
//  AppDelegate.swift
//  DanChess macOS
//
//  Created by Daniel Beard on 4/18/21.
//  Copyright © 2021 dbeard. All rights reserved.
//

import AppKit
import Cocoa
import Foundation
import UniformTypeIdentifiers

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    var utType: UTType { UTType(filenameExtension: "danchess")! }

    var gameVC: GameViewController? {
        NSApplication.shared.windows.first?.contentViewController as? GameViewController
    }

    // This is required for the open recent menu item to work
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        let fenString = try! String(contentsOf: url)
        let scene = GameScene.newGameScene(fen: fenString)
        gameVC?.present(scene: scene)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        return true
    }

    @IBAction func newGame(_ sender: Any) {
        let scene = GameScene.newGameScene(fen: START_FEN)
        gameVC?.present(scene: scene)
    }

    @IBAction func inputFEN(_ sender: Any) {

        let alert = NSAlert()
        alert.messageText = "Enter FEN String"
        let textfield = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 380.0, height: 24.0))
        textfield.alignment = .center
        alert.accessoryView = textfield

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let fenString = textfield.stringValue
            let scene = GameScene.newGameScene(fen: fenString)
            gameVC?.present(scene: scene)
        }
    }

    @IBAction func saveDocument(_ sender: Any?) {
        guard let gameVC else { return }
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [utType]
        savePanel.begin { response in
            if response == .OK {
                if let url = savePanel.url {
                    let fenString = gameVC.scene.board.fenForCurrentBoard()
                    try! fenString.write(to: url, atomically: true, encoding: .utf8)
                    NSDocumentController.shared.noteNewRecentDocumentURL(url)
                }
            }
        }
    }

    @IBAction func openDocument(_ sender: Any?) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [utType]
        openPanel.begin { response in
            if response == .OK {
                if let url = openPanel.url {
                    let _ = self.application(NSApplication.shared, openFile: url.path(percentEncoded: false))
                }
            }
        }
    }
}

