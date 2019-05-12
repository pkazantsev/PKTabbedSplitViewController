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

    var onCloseButtonPressed: ((_ animated: Bool) -> Void)?

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
        view.backgroundColor = .white

        if onCloseButtonPressed != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeDetail(_:)))
        }

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text

        view.addSubview(label)

        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        let button = UIButton(type: .system)
        button.setTitle("Open modal screen", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(button)

        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8).isActive = true
        button.addTarget(self, action: #selector(openModalScreen), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        print("viewDidLayoutSubviews(): Detail view width: \(view.frame.width)")
    }

    @objc private func closeDetail(_ sender: UIBarButtonItem) {
        onCloseButtonPressed?(true)
    }
    @objc private func closeModal(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @objc private func openModalScreen(_ sender: UIButton) {
        let vc = DemoModalViewController()
        vc.view.backgroundColor = .gray
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeModal(_:)))

        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .formSheet

        present(navVc, animated: true, completion: nil)
    }

}

private class DemoModalViewController: UIViewController {


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        print("DemoModalViewController.viewWillTransition(to:with:)")
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        print("DemoModalViewController.willTransition(to:with:)")
    }

}
