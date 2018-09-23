//
//  ViewController.swift
//  TabbedSplitViewControllerDemo
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit
import TabbedSplitViewController

class ViewController: UIViewController {

    var onButtonPressed: ((_ text: String) -> Void)?
    var onSwitchTabButtonPressed: ((_ text: String) -> Void)?
    var onInsertTabButtonPressed: ((_ text: String) -> Void)?
    var onRemoveTabButtonPressed: ((_ text: String) -> Void)?

    private lazy var label = UILabel()

    var screenText: String = "" {
        didSet {
            self.label.text = screenText
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = []
        title = screenText

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        let button1 = UIButton(type: .system)
        button1.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        button1.tag = 24
        button1.setTitle("\(screenText) – Open Detail 1", for: .normal)
        button1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button1)

        button1.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10).isActive = true
        button1.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        let button2 = UIButton(type: .system)
        button2.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        button2.tag = 25
        button2.setTitle("\(screenText) – Open Detail 2", for: .normal)
        button2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button2)

        button2.topAnchor.constraint(equalTo: button1.bottomAnchor, constant: 10).isActive = true
        button2.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        let button3 = UIButton(type: .system)
        button3.addTarget(self, action: #selector(button2Pressed(_:)), for: .touchUpInside)
        button3.tag = 34
        button3.setTitle("Switch to the other tab", for: .normal)
        button3.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button3)

        button3.topAnchor.constraint(equalTo: button2.bottomAnchor, constant: 10).isActive = true
        button3.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        let button4 = UIButton(type: .system)
        button4.addTarget(self, action: #selector(button3Pressed(_:)), for: .touchUpInside)
        button4.tag = 35
        button4.setTitle("Insert a tab on index 1", for: .normal)
        button4.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button4)

        button4.topAnchor.constraint(equalTo: button3.bottomAnchor, constant: 10).isActive = true
        button4.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        let button5 = UIButton(type: .system)
        button5.addTarget(self, action: #selector(button4Pressed(_:)), for: .touchUpInside)
        button5.tag = 35
        button5.setTitle("Remove a tab on index 1", for: .normal)
        button5.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button5)

        button5.topAnchor.constraint(equalTo: button4.bottomAnchor, constant: 10).isActive = true
        button5.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    @objc private func buttonPressed(_ button: UIButton) {
        onButtonPressed?(button.title(for: .normal)!)
    }
    @objc private func button2Pressed(_ button: UIButton) {
        onSwitchTabButtonPressed?(button.title(for: .normal)!)
    }
    @objc private func button3Pressed(_ button: UIButton) {
        onInsertTabButtonPressed?(button.title(for: .normal)!)
    }
    @objc private func button4Pressed(_ button: UIButton) {
        onRemoveTabButtonPressed?(button.title(for: .normal)!)
    }

}

