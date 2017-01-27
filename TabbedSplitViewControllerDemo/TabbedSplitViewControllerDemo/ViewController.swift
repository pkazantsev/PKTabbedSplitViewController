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

        button1.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        button1.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        let button2 = UIButton(type: .system)
        button2.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        button2.tag = 25
        button2.setTitle("\(screenText) – Open Detail 2", for: .normal)
        button2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button2)

        button2.topAnchor.constraint(equalTo: view.topAnchor, constant: 70).isActive = true
        button2.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    @objc private func buttonPressed(_ button: UIButton) {
        onButtonPressed?(button.title(for: .normal)!)
    }

}

