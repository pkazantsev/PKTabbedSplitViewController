//
//  LoggerWrapper.swift
//  TabbedSplitViewControllerDemo
//
//  Created by Pavel Kazantsev on 11/12/17.
//  Copyright © 2017 Pavel Kazantsev. All rights reserved.
//

import Foundation
import XCGLogger
import TabbedSplitViewController

class Logger: DebugLogger {

    private let log = XCGLogger()

    init() {
        log.setup(level: .debug,
                  showLogIdentifier: false,
                  showFunctionName: true,
                  showThreadName: false,
                  showLevel: true,
                  showFileNames: false,
                  showLineNumbers: true,
                  showDate: false,
                  writeToFile: nil,
                  fileLevel: nil)
    }

    func log(_ message: @escaping @autoclosure () -> Any?, level: LogLevel, _ file: StaticString, _ line: Int) {
        log.logln(message, level: level.xcgLevel, fileName: file, lineNumber: line)
    }

}

extension LogLevel {
    var xcgLevel: XCGLogger.Level {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
}

