//
//  AppDelegate.swift
//  TabbedSplitViewControllerDemo
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit
import TabbedSplitViewController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if let viewController = self.window?.rootViewController as? TabbedSplitViewController {
            viewController.logger = Logger()
            var config = viewController.config
            config.showMasterAsSideBarWithSizeChange = { size, traits, config in
                print("showMasterAsSideBarWithSizeChange(): traits.userInterfaceIdiom = \(traits.userInterfaceIdiom)")
                print("showMasterAsSideBarWithSizeChange(): size.width = \(size.width)")
                /// Master should be hidden on iPad in Portrait or in multi-tasking mode unless it's iPhone-width.
                let should = traits.userInterfaceIdiom == .pad && size.width <= 768 && size.width > 512
                print("showMasterAsSideBarWithSizeChange(): \(should)")
                return should
            }
            config.showDetailAsModalWithSizeChange = { size, traits, config in
                print("showDetailAsModalWithSizeChange(): traits.horizontalSizeClass = \(traits.horizontalSizeClass)")
                print("showDetailAsModalWithSizeChange(): size.width = \(size.width)")
                /// Use on iPad in compact mode and on iPhone except Plus models in landscape
                let should = traits.horizontalSizeClass == .compact && size.width <= (70 + 320 + 320)
                print("showDetailAsModalWithSizeChange(): \(should)")
                return should
            }
            config.showTabBarAsSideBarWithSizeChange = { size, traits, config in
                print("showTabBarAsSideBarWithSizeChange(): traits.horizontalSizeClass = \(traits.horizontalSizeClass)")
                print("showTabBarAsSideBarWithSizeChange(): size.width = \(size.width)")
                /// Use on iPad in compact mode and on iPhone 4s/5/5s/SE
                let should = traits.horizontalSizeClass == .compact && size.width <= 320
                print("showTabBarAsSideBarWithSizeChange(): \(should)")
                return should
            }

            let vc1 = ViewController()
            vc1.screenText = "Screen 1111"
            vc1.onButtonPressed = { [unowned viewController] text in
                let controller = DetailController(text: "Button: \(text)")
                let navController = UINavigationController(rootViewController: controller)
                viewController.showDetailViewController(navController, sender: nil)
            }
            let vc2 = ViewController()
            vc2.onButtonPressed = { [unowned viewController] text in
                let controller = DetailController(text: "Button: \(text)")
                let navController = UINavigationController(rootViewController: controller)
                viewController.showDetailViewController(navController, sender: nil)
            }
            vc2.screenText = "Screen 22222"

            viewController.config = config
            viewController.add(PKTabBarItem(with: vc1.embeddedInNavigationController(), title: "Screen 1", image: #imageLiteral(resourceName: "Peotr")))
            viewController.add(PKTabBarItem(with: vc2.embeddedInNavigationController(), title: "Screen 2", image: #imageLiteral(resourceName: "Peotr")))
        }

        return true
    }

}

extension UIViewController {

    /// Returns navigation controller instance with current controller as a root view controller
    func embeddedInNavigationController() -> UINavigationController {
        return embeddedInNavigationController(presentationStyle: .none)
    }
    /// Returns navigation controller instance with current controller as a root view controller
    func embeddedInNavigationController(presentationStyle: UIModalPresentationStyle) -> UINavigationController {
        let navController = UINavigationController(rootViewController: self)
        navController.modalPresentationStyle = presentationStyle
        return navController
    }
    
}

