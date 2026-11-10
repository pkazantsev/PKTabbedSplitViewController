//
//  LoggerWrapper.swift
//  TabbedSplitViewControllerDemo
//
//  Created by Pavel Kazantsev on 11/12/17.
//  Copyright © 2017 Pavel Kazantsev. All rights reserved.
//

import Foundation
import PKTabbedSplitViewController

class Logger: DebugLogger {

    func log(_ message: @escaping @autoclosure () -> Any?, level: LogLevel = .debug, _ function: StaticString = #function, _ line: Int = #line) {
        print("\(level) > \(function): \(message()!)")
    }

}

