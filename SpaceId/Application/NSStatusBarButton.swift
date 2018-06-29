//
//  NSStatusBarButton.swift
//  SpaceId
//
//  Created by Pieter on 6/28/18.
//  Copyright © 2018 Dennis Kao. All rights reserved.
//

import Foundation
import Cocoa

extension NSStatusBarButton {
    
    @discardableResult
    func shell(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    open override func scrollWheel(with: NSEvent) {
        if (with.deltaY == -3.0) {
            shell("/usr/local/bin/chunkc", "tiling::desktop", "-f", "next")
        } else if (with.deltaY == 3.0) {
            shell("/usr/local/bin/chunkc", "tiling::desktop", "-f", "prev")
        }
    }
}
