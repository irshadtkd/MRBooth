//
//  UIApplication+TopViewController.swift
//  MRBooth
//

#if os(iOS)
import UIKit

extension UIApplication {
    static var topViewController: UIViewController? {
        guard let scene = shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return nil
        }
        return topViewController(from: root)
    }

    private static func topViewController(from base: UIViewController) -> UIViewController {
        if let nav = base as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        if let presented = base.presentedViewController {
            return topViewController(from: presented)
        }
        return base
    }
}
#endif
