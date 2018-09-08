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
            let logger = Logger()
            viewController.logger = logger
            var config = viewController.config
            config.showMasterAsSideBarWithSizeChange = { size, traits, config in
                logger.log("hideMaster: traits.userInterfaceIdiom = \(traits.userInterfaceIdiom)")
                logger.log("hideMaster: size.width = \(size.width)")
                /// Master should be hidden on iPad in Portrait or in multi-tasking mode unless it's iPhone-width.
                let should = traits.userInterfaceIdiom == .pad && size.width <= 768 && size.width > 512
                logger.log("hideMaster: \(should)")
                return should
            }
            config.showDetailAsModalWithSizeChange = { size, traits, config in
                logger.log("hideDetail: traits.horizontalSizeClass = \(traits.horizontalSizeClass)")
                logger.log("hideDetail: size.width = \(size.width)")
                /// Use on iPad in compact mode and on iPhone except Plus models in landscape
                let should = traits.horizontalSizeClass == .compact && size.width <= (70 + 320 + 320)
                logger.log("hideDetail: \(should)")
                return should
            }
            config.showTabBarAsSideBarWithSizeChange = { size, traits, config in
                logger.log("hideTabBar: traits.horizontalSizeClass = \(traits.horizontalSizeClass)")
                logger.log("hideTabBar: size.width = \(size.width)")
                /// Use on iPad in compact mode and on iPhone 4s/5/5s/SE
                let should = traits.horizontalSizeClass == .compact && size.width <= 320
                logger.log("hideTabBar: \(should)")
                return should
            }
            config.tabBarBackgroundColor = .purple
            config.detailBackgroundColor = .blue
            config.verticalSeparatorColor = .orange

            let vc1 = ViewController()
            vc1.screenText = "Screen 1111"
            vc1.onButtonPressed = { [unowned viewController] text in
                let controller = DetailController(text: "Button: \(text)")
                controller.onCloseButtonPressed = viewController.dismissDetailViewController
                let navController = UINavigationController(rootViewController: controller)
                viewController.showDetailViewController(navController, sender: nil)
            }
            let vc2 = ViewController()
            vc2.onButtonPressed = { [unowned viewController] text in
                let controller = DetailController(text: "Button: \(text)")
                controller.onCloseButtonPressed = viewController.dismissDetailViewController
                let navController = UINavigationController(rootViewController: controller)
                viewController.showDetailViewController(navController, sender: nil)
            }
            vc2.screenText = "Screen 22222"

            viewController.config = config
            // Main tab bar – view controllers
            viewController.addToTabBar(PKTabBarItem(title: "Screen 1", image: #imageLiteral(resourceName: "Peotr"), selectedImage: #imageLiteral(resourceName: "Peotr2"), action: vc1.embeddedInNavigationController()))
            // Second screen's icon is rendered as template so it changes tint color when selected,
            //   unlike the first screen's icon.
            viewController.addToTabBar(PKTabBarItem(title: "Screen 2", image: #imageLiteral(resourceName: "Address"), action: vc2.embeddedInNavigationController()))
            // Actions bar – closures
            viewController.addToActionBar(PKTabBarItem(title: "About", image: #imageLiteral(resourceName: "About")) { [unowned viewController] in
                let alert = UIAlertController(title: "About", message: "TabbedSplitViewController v0.1", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Close", style: .default))
                viewController.present(alert, animated: true)
            })

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

