//
//  DetailController.swift
//  TabbedSplitViewControllerDemo
//
//  Created by Pavel Kazantsev on 12/25/16.
//  Copyright © 2016 Pavel Kazantsev. All rights reserved.
//

import UIKit

class DetailController: UIViewController {

    private let text: String

    init(text: String) {
        self.text = text

        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = text

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(close(_:)))

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text

        view.addSubview(label)

        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    @objc private func close(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }

}
