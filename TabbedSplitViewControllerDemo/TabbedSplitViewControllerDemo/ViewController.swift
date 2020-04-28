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
    var onTableButtonPressed: ((_ text: String) -> Void)?
    var onSwitchTabButtonPressed: ((_ text: String) -> Void)?
    var onInsertTabButtonPressed: ((_ text: String) -> Void)?
    var onRemoveTabButtonPressed: ((_ text: String) -> Void)?

    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var detailButton1: UIButton!
    @IBOutlet private weak var detailButton2: UIButton!
    @IBOutlet private weak var detailTVCButton: UIButton!
    @IBOutlet private weak var switchButton: UIButton!
    @IBOutlet private weak var addTabBarItemButton: UIButton!
    @IBOutlet private weak var removeTabBarItemButton: UIButton!

    var screenText: String = "" {
        didSet {
            self.updateButtonsText()
        }
    }

    private init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateButtonsText()
        self.enableButtons()
    }

    private func updateButtonsText() {
        title = screenText

        self.label?.text = screenText
        detailButton1?.setTitle("\(screenText) – Open Detail 1", for: .normal)
        detailButton2?.setTitle("\(screenText) – Open Detail 2", for: .normal)
    }
    private func enableButtons() {
        self.detailButton1?.isEnabled = onButtonPressed != nil
        self.detailButton2?.isEnabled = onButtonPressed != nil
        self.detailTVCButton?.isEnabled = onTableButtonPressed != nil
        self.switchButton?.isEnabled = onSwitchTabButtonPressed != nil
        self.addTabBarItemButton?.isEnabled = onInsertTabButtonPressed != nil
        self.removeTabBarItemButton?.isEnabled = onRemoveTabButtonPressed != nil
    }

    @IBAction private func detailButtonPressed(_ button: UIButton) {
        onButtonPressed?(button.title(for: .normal)!)
    }
    @IBAction private func detailTVCButtonPressed(_ button: UIButton) {
        onTableButtonPressed?(button.title(for: .normal)!)
    }
    @IBAction private func switchButtonPressed(_ button: UIButton) {
        onSwitchTabButtonPressed?(button.title(for: .normal)!)
    }
    @IBAction private func addTabBarItemButtonPressed(_ button: UIButton) {
        onInsertTabButtonPressed?(button.title(for: .normal)!)
    }
    @IBAction private func removeTabBarItemButtonPressed(_ button: UIButton) {
        onRemoveTabButtonPressed?(button.title(for: .normal)!)
    }

}

