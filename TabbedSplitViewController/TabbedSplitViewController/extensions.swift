//
//  extensions.swift
//  TabbedSplitViewController
//
//  Created by Pavel Kazantsev on 1/27/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import Foundation

extension UIViewController {

    /// Add a view as a child to this view controller's view
    ///  attaching all sides.
    ///
    /// - Parameter childView: a child view that will take all parent's space
    func addChildView(_ childView: UIView) {
        view.addSubview(childView)

        childView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            childView.leftAnchor.constraint(equalTo: view.leftAnchor),
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.rightAnchor.constraint(equalTo: view.rightAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        view.addConstraints(constraints)
    }

}

extension Array where Element: NSLayoutConstraint {

    static func constraints(withVisualFormat format: String, options opts: NSLayoutFormatOptions = [], metrics: [String : Any]?, views: [String : Any]) -> [NSLayoutConstraint] {
        return NSLayoutConstraint.constraints(withVisualFormat: format, options: opts, metrics: metrics, views: views)
    }
}

protocol Then {}

extension Then where Self: Any {

    func then(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }

}

extension NSObject: Then {}

public protocol DebugLogger {

    func log(_ message: @escaping @autoclosure () -> Any?, level: LogLevel, _ file: StaticString, _ line: Int)
}

extension DebugLogger {
    func log(_ message: @escaping @autoclosure () -> Any?, _ file: StaticString = #file, _ line: Int = #line) {
        log(message, level: .debug, file, line)
    }
}


public enum LogLevel {
    case debug
    case info
    case warning
    case error
}
