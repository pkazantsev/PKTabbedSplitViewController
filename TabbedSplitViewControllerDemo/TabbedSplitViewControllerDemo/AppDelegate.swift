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

        let minDetailWidth: CGFloat = 320
        let masterWidth: CGFloat = 320
        let tabBarWidth:CGFloat = 70

        if let viewController = self.window?.rootViewController as? TabbedSplitViewController {
            let logger = Logger()
            viewController.logger = logger
            var config = viewController.config
            config.showMasterAsSideBarWithSizeChange = { size, traits, config in
                logger.log("hideMaster: traits.userInterfaceIdiom = \(traits.userInterfaceIdiom)")
                logger.log("hideMaster: size.width = \(size.width)")
                /// Master should be hidden on iPad in Portrait or in multi-tasking mode unless it's iPhone-width.
                let should = traits.userInterfaceIdiom == .pad
                            && size.width >= 678 /* iPad 12" half-screen */
                            && size.width <= 978 /* iPad 12" 2/3 screen */

                logger.log("hideMaster: \(should)")
                return should
            }
            config.showDetailAsModalWithSizeChange = { size, traits, config in
                logger.log("hideDetail: traits.horizontalSizeClass = \(traits.horizontalSizeClass)")
                logger.log("hideDetail: size.width = \(size.width)")
                /// Use on iPad in compact mode and on iPhone except Plus models in landscape
                let should = traits.horizontalSizeClass == .compact
                            // iPhone X/Xs Landscape
                            && size.width < (tabBarWidth + masterWidth + minDetailWidth)
                logger.log("hideDetail: \(should)")
                return should
            }
            config.showTabBarAsSideBarWithSizeChange = { size, traits, config in
                logger.log("hideTabBar: traits.horizontalSizeClass = \(traits.horizontalSizeClass)")
                logger.log("hideTabBar: size.width = \(size.width)")
                /// Use on iPad in compact mode and on iPhone 4s/5/5s/SE
                let should = traits.horizontalSizeClass == .compact && size.width < 375 /* Regular iPhone width */
                logger.log("hideTabBar: \(should)")
                return should
            }
            config.tabBarBackgroundColor = .purple
            config.detailBackgroundColor = .blue
            config.verticalSeparatorColor = .orange

            viewController.config = config

            // Master view controllers
            let vc1 = ViewController()
            vc1.screenText = "Screen 1111"
            vc1.onButtonPressed = { [unowned viewController] text in
                let controller = DetailController(text: "Button: \(text)")
                controller.onCloseButtonPressed = {
                    let time = Date()
                    viewController.dismissDetailViewController(animated: $0) {
                        print("\(Date().timeIntervalSince(time)) Finished dismissing \("Button: \(text)")")
                    }
                }
                let navController = UINavigationController(rootViewController: controller)
                let time = Date()
                viewController.showDetailViewController(navController) {
                    print("\(Date().timeIntervalSince(time)) Finished presenting \("Button: \(text)")")
                }
            }
            vc1.onSwitchTabButtonPressed = { [unowned viewController] text in
                viewController.selectedTabBarItemIndex = 1
            }
            let vc2 = ViewController()
            vc2.screenText = "Screen 22222"
            vc2.onButtonPressed = { [unowned viewController] text in
                let controller = DetailController(text: "Button: \(text)")
                controller.onCloseButtonPressed = {
                    let time = Date()
                    viewController.dismissDetailViewController(animated: $0) {
                        print("\(Date().timeIntervalSince(time)) Finished dismissing \("Button: \(text)")")
                    }
                }
                let navController = UINavigationController(rootViewController: controller)
                let time = Date()
                viewController.showDetailViewController(navController) {
                    print("\(Date().timeIntervalSince(time)) Finished presenting \("Button: \(text)")")
                }
            }
            vc2.onSwitchTabButtonPressed = { [unowned viewController] text in
                viewController.selectedTabBarItemIndex = 0
            }
            vc2.onInsertTabButtonPressed = { [unowned viewController] text in
                self.insertNewTab(to: viewController, at: 1)
            }

            // Default detail view controller, optional
            let defaultDetailVC = storyboard().instantiateViewController(withIdentifier: "DefaultDetailScreen")
            viewController.defaultDetailViewController = defaultDetailVC

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

    private func insertNewTab(to vc: TabbedSplitViewController, at index: Int) {
        let vc3 = ViewController()
        vc3.screenText = "Screen 33333"
        vc3.onRemoveTabButtonPressed = { [unowned vc] text in
            vc.removeFromTabBar(at: index)
        }
        vc.insertToTabBar(PKTabBarItem(title: "Multiline Tab Title", image: #imageLiteral(resourceName: "Address"), action: vc3.embeddedInNavigationController()), at: index)
    }

    private func storyboard() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
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

