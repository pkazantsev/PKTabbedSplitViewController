import UIKit
import XCTest
@testable import TabbedSplitViewControllerDemo
import TabbedSplitViewController

class DemoConfigTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func test() {
        let testCases: [(String, CGFloat, UIUserInterfaceSizeClass, Bool, Bool, Bool, UIUserInterfaceIdiom)] = [
            // Split-view separator width: 10pt

            // iPhones, portrait:
            ("iPhone 4\" Portrait",     320, .compact,  true, false,  true, .phone), // 4s/5/5s/SE
            ("iPhone 4.7\" Portrait",   375, .compact, false, false,  true, .phone), // 6/6s/7/8/X/Xs
            ("iPhone 5.5\" Portrait",   414, .compact, false, false,  true, .phone), // *Plus/XR/Xs Max
            // iPhones, landscape:
            ("iPhone 4s Landscape",     480, .compact, false, false,  true, .phone), // 4s
            ("iPhone SE Landscape",     568, .compact, false, false,  true, .phone), // 5/5s/SE
            ("iPhone 4.7\" Landscape",  667, .compact, false, false,  true, .phone), // 6/6s/7/8
            ("iPhone Plus Landscape",   736, .regular, false, false, false, .phone), // *Plus
            ("iPhone X/Xs Landscape",   724, .compact, false, false, false, .phone), // X/Xs, (812 - 44 * 2) – notch margins
            ("iPhone Xs Max Landscape", 808, .regular, false, false, false, .phone), // XR/Xs Max, (896 - 44 * 2) – notch margins

            // iPads, 1/3 (lanscape, portrait):
            ("iPad 9.7\"/ 1/3 screen",  320, .compact,  true, false,  true, .pad), // Both 9.7" and 10.5"
            ("iPad 12.9\" 1/3 screen",  375, .compact, false, false,  true, .pad),
            // iPads, full-screen, portrait:
            ("iPad 9.7\" Portrait",     768, .regular, false,  true, false, .pad),
            ("iPad 10.5\" Portrait",    834, .regular, false,  true, false, .pad),
            ("iPad 12.9\" Portrait",   1024, .regular, false, false, false, .pad),
            // iPads, full-screen, landscape:
            ("iPad 9.7\" Landscape",   1024, .regular, false, false, false, .pad),
            ("iPad 10.5\" Landscape",  1112, .regular, false, false, false, .pad),
            ("iPad 12.9\" Landscape",  1366, .regular, false, false, false, .pad),
            // iPads, half-screen, portrait:
            ("iPad 9.7\" 1/2, Port.",   379, .compact, false, false,  true, .pad),
            ("iPad 10.5\" 1/2, Port.",  412, .compact, false, false,  true, .pad),
            ("iPad 12.9\" 1/2, Port.",  507, .compact, false, false,  true, .pad),
            // iPads, half-screen, landscape:
            ("iPad 9.7\" 1/2, Lands.",  507, .compact, false, false,  true, .pad),
            ("iPad 10.5\" 1/2, Lands.", 551, .compact, false, false,  true, .pad),
            ("iPad 12.9\" 1/2, Lands.", 678, .regular, false,  true, false, .pad),
            // iPads, portrait, wide:
            ("iPad 9.7\" 2/3, Port.",   438, .compact, false, false,  true, .pad),
            ("iPad 10.5\" 2/3, Port.",  504, .compact, false, false,  true, .pad),
            ("iPad 12.9\" 2/3, Port.",  639, .compact, false, false,  true, .pad),
            // iPads, landscape, 2/3:
            ("iPad 9.7\" 2/3, Lands.",  694, .regular, false,  true, false, .pad),
            ("iPad 10.5\" 2/3, Lands.", 782, .regular, false,  true, false, .pad),
            ("iPad 12.9\" 2/3, Lands.", 981, .regular, false, false, false, .pad),
        ]

        let delegate = (UIApplication.shared.delegate as? AppDelegate)
        guard let splitVC = delegate?.window?.rootViewController as? TabbedSplitViewController else {
            return XCTFail("Split view controller not found")
        }
        let config = splitVC.config

        for size in testCases {
            let (title, width, sizeClass, shouldTabHidden, shouldMasterHidden, shouldDetailHidden, idiom) = size

            let traits = UITraitCollection(traitsFrom: [UITraitCollection(horizontalSizeClass: sizeClass),
                                                        UITraitCollection(userInterfaceIdiom: idiom)])
            let isTabHidden = config.showTabBarAsSideBarWithSizeChange!(CGSize(width: width, height: 999), traits, config)
            let isMasterHidden = config.showMasterAsSideBarWithSizeChange!(CGSize(width: width, height: 999), traits, config)
            let isDetailHidden = config.showDetailAsModalWithSizeChange!(CGSize(width: width, height: 999), traits, config)

            XCTAssert(isTabHidden == shouldTabHidden
                && isMasterHidden == shouldMasterHidden
                && isDetailHidden == shouldDetailHidden,
                      "\(title) failed, actual values: \(String(describing: isTabHidden)), \(String(describing: isMasterHidden)), \(String(describing: isDetailHidden))")
        }
    }
    
}
