//
//  FullWidthViewController.swift
//

import UIKit

final class FullWidthViewController: UIViewController {


    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .orange

        let label = UILabel()
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 42)
        label.textAlignment = .center
        label.text = "This is full-width container screen.\nIt is like master-detail but without master."
    }
}
