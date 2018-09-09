//
//  TabBar.swift
//  TabbedSplitViewController
//
//  Created by Pavel Kazantsev on 9/9/18.
//  Copyright © 2018 PaKaz.net. All rights reserved.
//

import UIKit

private let pkTabBarItemCellIdentifier = "PkTabBarItemCellIdentifier"
private let pkSideBarTabBarItemCellIdentifier = "PkSideBarTabBarItemCellIdentifier"

private protocol TabBarViewModel {

    var title: String { get }
    var image: UIImage { get }
    var selectedImage: UIImage? { get }
    var navigationBarImage: UIImage? { get }
    var navigationBarSelectedImage: UIImage? { get }

}
extension PKTabBarItem: TabBarViewModel {}

// MARK: - Main tab bar

class PKTabBar: UIViewController {

    let tabBar = PKTabBarTabsList<UIViewController>()
    let actionsBar = PKTabBarTabsList<TabBarAction>()

    var shouldAddVerticalSeparator: Bool = true
    var verticalSeparatorColor: UIColor = .gray {
        didSet {
            verticalSeparator.backgroundColor = verticalSeparatorColor
        }
    }
    var backgroundColor: UIColor = .white {
        didSet {
            view.backgroundColor = backgroundColor
        }
    }

    private let verticalSeparator = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = backgroundColor

        actionsBar.isCompact = true

        addChildViewController(tabBar)
        addChildView(tabBar.view, bottom: false)
        addChildViewController(actionsBar)
        addChildView(actionsBar.view, top: false)

        tabBar.view.bottomAnchor.constraint(equalTo: actionsBar.view.topAnchor, constant: 8.0).isActive = true

        view.layoutIfNeeded()
        tabBar.didMove(toParentViewController: self)
        actionsBar.didMove(toParentViewController: self)

        tabBar.view.backgroundColor = nil
        tabBar.shouldDisplayArrow = true
        actionsBar.view.backgroundColor = nil
        // Should not change color when selected
        actionsBar.view.tintColor = .black
        actionsBar.shouldDisplayArrow = false

        if shouldAddVerticalSeparator {
            view.addVerticalSeparator(verticalSeparator, color: verticalSeparatorColor)
        }
    }
}

// MARK: - Tab bar items list

class PKTabBarTabsList<Action>: UITableViewController {
    var items = [PKTabBarItem<Action>]() {
        didSet {
            tableView.reloadData()
        }
    }
    var isOpen: Bool = false {
        didSet {
            if shouldDisplayArrow, let cell = tableView.cellForRow(at: IndexPath(row: selectedItemIndex, section: 0)) as? PKTabBarItemTableViewCell {
                cell.isOpen = isOpen
            }
        }
    }

    /// Initial value: -1, don't select anything. Can not set -1 anytime later.
    var selectedItemIndex: Int = -1 {
        didSet {
            if selectedItemIndex >= 0 || selectedItemIndex < items.count {
                didSelectCallback?(items[selectedItemIndex], selectedItemIndex)
            } else {
                selectedItemIndex = 0
            }
            if selectedItemIndex != oldValue {
                tableView.selectRow(at: IndexPath(row: selectedItemIndex, section: 0), animated: true, scrollPosition: .none)
            }
        }
    }
    /// The view is shrinked to the size of the tabs
    fileprivate var isCompact: Bool = false
    var didSelectCallback: ((PKTabBarItem<Action>, Int) -> Void)?
    var shouldDisplayArrow = true {
        didSet {
            (0..<items.count)
                .map { tableView.cellForRow(at: IndexPath(row: $0, section: 0)) }
                .compactMap { $0 as? PKTabBarItemTableViewCell }
                .forEach { $0.shouldDisplayArrow = self.shouldDisplayArrow }
        }
    }

    private var heightConstraint: NSLayoutConstraint? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "Tab Bar View"

        tableView.isScrollEnabled = false
        tableView.estimatedRowHeight = 40
        tableView.separatorStyle = .none

        if isCompact {
            heightConstraint = view.heightAnchor.constraint(equalToConstant: 44.0)
            heightConstraint?.isActive = true
        } else {
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 32))
        }

        registerCells()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if selectedItemIndex >= 0, items.count > selectedItemIndex {
            tableView.selectRow(at: IndexPath(row: selectedItemIndex, section: 0), animated: true, scrollPosition: .none)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isCompact, let constraint = heightConstraint {
            let newHeight = tableView.contentSize.height + 16.0
            if constraint.constant != newHeight {
                constraint.constant = newHeight
                view.setNeedsLayout()
            }
        }
    }

    fileprivate func registerCells() {
        tableView.register(PKTabBarItemTableViewCell.self, forCellReuseIdentifier: pkTabBarItemCellIdentifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: pkTabBarItemCellIdentifier, for: indexPath) as! PKTabBarItemTableViewCell

        if items.count > indexPath.row {
            let item = items[indexPath.row]
            cell.item = item
            cell.shouldDisplayArrow = shouldDisplayArrow
            cell.setSelected(selectedItemIndex == indexPath.row, animated: false)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItemIndex = indexPath.row
    }
}

// MARK: - Tab bar for a navigation side bar

class PKTabBarAsSideBar: PKTabBarTabsList<UIViewController> {

    var actionItems: [PKTabBarItem<TabBarAction>] = []
    var actionSelectedCallback: ((PKTabBarItem<TabBarAction>, Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "Tab Bar Side Bar View"
    }

    fileprivate override func registerCells() {
        tableView.register(PKSideTabBarItemTableViewCell.self, forCellReuseIdentifier: pkSideBarTabBarItemCellIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return actionItems.isEmpty ? 1 : 2
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        return actionItems.count
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return " "
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: pkSideBarTabBarItemCellIdentifier, for: indexPath) as! PKSideTabBarItemTableViewCell

        if indexPath.section == 0, items.count > indexPath.row {
            let item = items[indexPath.row]
            configureCell(cell, for: item)
            cell.setSelected(selectedItemIndex == indexPath.row, animated: false)
        }
        if indexPath.section == 1, actionItems.count > indexPath.row {
            let item = actionItems[indexPath.row]
            configureCell(cell, for: item)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard indexPath.section == 1 else {
            return indexPath
        }
        if actionItems.count > indexPath.row {
            let item = actionItems[indexPath.row]
            actionSelectedCallback?(item, selectedItemIndex)
        }

        return nil
    }

    private func configureCell<T>(_ cell: PKSideTabBarItemTableViewCell, for item: PKTabBarItem<T>) {
        cell.shouldDisplayArrow = false
        cell.item = item
    }
}

private class PKTabBarItemTableViewCell: UITableViewCell {

    fileprivate let titleLabel = UILabel().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    fileprivate let iconImageView = UIImageView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    fileprivate let arrowImageView = UIImageView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.alpha = 0.0
        $0.contentMode = .center
        $0.tintColor = nil
    }

    fileprivate var item: TabBarViewModel! {
        didSet {
            guard let anItem = item else { return }
            configureCell(with: anItem)
        }
    }

    fileprivate var shouldDisplayArrow = true {
        didSet {
            configureArrow()
        }
    }
    fileprivate var isOpen = false {
        didSet {
            configureArrow()
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        titleLabel.textColor = isSelected ? self.tintColor : .black
    }

    private lazy var openArrowImage = UIImage(named: "Tab Bar Arrow Open", in: Bundle(for: PKTabBarItemTableViewCell.self), compatibleWith: nil)
    private lazy var closeArrowImage = UIImage(named: "Tab Bar Arrow Close", in: Bundle(for: PKTabBarItemTableViewCell.self), compatibleWith: nil)

    fileprivate override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureLabel()
        configureImageView()

        contentView.addSubview(titleLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(arrowImageView)

        addConstraints()

        configureCell()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        arrowImageView.alpha = 0.0
        iconImageView.tintColor = nil
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        let doSelect = {
            self.arrowImageView.alpha = selected ? 1.0 : 0.0
            self.titleLabel.textColor = selected ? self.tintColor : .black
            self.iconImageView.tintColor = selected ? self.tintColor : .black
            self.iconImageView.image = selected ? self.item.selectedImage ?? self.item.image : self.item.image
        }
        if animated {
            UIView.animate(withDuration: 0.32, animations: doSelect)
        } else {
            doSelect()
        }
    }

    fileprivate func configureCell() {
        selectionStyle = .none
    }
    fileprivate func configureCell(with item: TabBarViewModel) {
        titleLabel.text = item.title
        iconImageView.image = isSelected && item.selectedImage != nil ? item.selectedImage : item.image
    }

    fileprivate func configureLabel() {
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
        titleLabel.textAlignment = .center
    }

    fileprivate func configureImageView() {
        iconImageView.contentMode = .center
    }
    fileprivate func configureArrow() {
        arrowImageView.isHidden = !shouldDisplayArrow
        // When we activate 'shouldDisplayArrow' for all cells,
        //   the deselected ones should have their arrow hidden
        arrowImageView.alpha = isSelected && shouldDisplayArrow ? 1.0 : 0.0
        if shouldDisplayArrow && isSelected {
            arrowImageView.image = isOpen ? closeArrowImage : openArrowImage
        }
    }

    fileprivate func addConstraints() {
        let views: [String: UIView] = ["titleLabel": titleLabel, "iconImageView": iconImageView]

        let constraints: [[NSLayoutConstraint]] = [
            .constraints(withVisualFormat: "V:|-5-[iconImageView]-5-[titleLabel]-5-|", views: views),
            .constraints(withVisualFormat: "H:|[iconImageView]|", options: .directionLeadingToTrailing, views: views),
            .constraints(withVisualFormat: "H:|[titleLabel]|", options: .directionLeadingToTrailing, views: views)
        ]

        NSLayoutConstraint.activate(constraints.flatMap { $0 } + [
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6.0),
            arrowImageView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor)
            ])
    }

}

private class PKSideTabBarItemTableViewCell: PKTabBarItemTableViewCell {

    fileprivate override func configureCell(with item: TabBarViewModel) {
        titleLabel.text = item.title
        if isSelected, let image = item.navigationBarSelectedImage {
            iconImageView.image = image
        } else {
            iconImageView.image = item.navigationBarImage ?? item.image
        }
    }

    fileprivate override func configureLabel() {
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
    }

    fileprivate override func configureImageView() {
        iconImageView.contentMode = .scaleAspectFit
    }

    fileprivate override func addConstraints() {
        let views: [String: UIView] = ["titleLabel": titleLabel, "iconImageView": iconImageView]

        let constraints: [[NSLayoutConstraint]] = [
            .constraints(withVisualFormat: "H:|-[iconImageView]-[titleLabel]-|", options: .directionLeadingToTrailing, views: views),
            .constraints(withVisualFormat: "V:|-[iconImageView(24)]-|", views: views),
            .constraints(withVisualFormat: "V:|-[titleLabel]-|", views: views)
        ]
        NSLayoutConstraint.activate(constraints.flatMap { $0 })
    }

}