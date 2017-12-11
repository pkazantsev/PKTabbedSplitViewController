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
        NSLayoutConstraint.activate([
            childView.leftAnchor.constraint(equalTo: view.leftAnchor),
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.rightAnchor.constraint(equalTo: view.rightAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        view.setNeedsLayout()
    }
}

extension UIView {

    /// Adds a passed view as a vertical separator, setting a passed color (or `.gray` as a default value),
    /// and a passed width (or 1 screen pixel).
    ///
    /// The passed view will be alignet to the right side of this view with equal height.
    ///
    /// - Parameters:
    ///   - separator: view that will be set as a separator
    ///   - color: separator color
    ///   - width: separator width
    func addVerticalSeparator(_ separator: UIView, color: UIColor = .gray, width: CGFloat? = nil) {
        addSubview(separator)
        let lineWidth = width ?? 1.0 / UIScreen.main.nativeScale
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = color
        separator.accessibilityIdentifier = "Vertical Separator"
        NSLayoutConstraint.activate([
            separator.widthAnchor.constraint(equalToConstant: lineWidth),
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.rightAnchor.constraint(equalTo: rightAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
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

    func log(_ message: @escaping @autoclosure () -> Any?, level: LogLevel, _ function: StaticString, _ line: Int)
}

extension DebugLogger {
    func log(_ message: @escaping @autoclosure () -> Any?, _ function: StaticString = #function, _ line: Int = #line) {
        log(message, level: .debug, function, line)
    }
}


public enum LogLevel {
    case debug
    case info
    case warning
    case error
}
