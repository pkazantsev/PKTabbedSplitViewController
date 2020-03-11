//
//  Utils.swift
//

import UIKit


class SideBarWrapper<T>: UIViewController where T: UIViewController {

    let childVC: T

    init(childVC: T) {
        self.childVC = childVC

        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        addChild(childVC)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            view.addSubview(childVC.view)
            view.safeAreaLayoutGuide.alignBounds(with: childVC.view)
        } else {
            addChildView(childVC.view)
        }
        childVC.didMove(toParent: self)
    }
}
