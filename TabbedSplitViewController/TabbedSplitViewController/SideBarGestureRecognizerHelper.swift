//
//  SideBarGestureRecognizerHelper.swift
//

import UIKit

let sideBarAnimationDuration: TimeInterval = 0.35
private let maxOverlayAlpha: CGFloat = 0.25
private let minOverlayAlpha: CGFloat = 0.0

class SideBarGestureRecognizerHelper {

    private let sourceView: UIView
    private let targetView: UIView
    private let xConstraint: NSLayoutConstraint
    private let viewWidth: CGFloat
    private let leftOffset: CGFloat

    private let openViewRec: UIGestureRecognizer
    private let closeViewRec: UIGestureRecognizer

    var willOpen: (() -> Void)?
    var didOpen: (() -> Void)?
    var willClose: (() -> Void)?
    var didClose: (() -> Void)?

    var isEnabled: Bool = true {
        didSet {
            openViewRec.isEnabled = isEnabled
            closeViewRec.isEnabled = isEnabled
        }
    }

    private var startingPoint: CGFloat = 0

    private let overlayView = UIView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isHidden = true
        $0.backgroundColor = .black
        $0.alpha = minOverlayAlpha
    }

    var logger: DebugLogger?

    init(base: UIView, target: UIView, targetX: NSLayoutConstraint, targetWidth: CGFloat, leftOffset: CGFloat = 0) {
        sourceView = base
        targetView = target
        xConstraint = targetX
        viewWidth = targetWidth
        self.leftOffset = leftOffset

        let rec1 = UIScreenEdgePanGestureRecognizer()
        sourceView.addGestureRecognizer(rec1)
        openViewRec = rec1

        let rec2 = UIPanGestureRecognizer()
        targetView.addGestureRecognizer(rec2)
        closeViewRec = rec2

        rec1.edges = .left
        rec1.addTarget(self, action: #selector(handleGesture(_:)))
        rec2.addTarget(self, action: #selector(handleGesture(_:)))

        targetView.superview?.insertChildView(overlayView, belowSubview: targetView)

        let overlayTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOverlay))
        overlayView.addGestureRecognizer(overlayTapGestureRecognizer)
    }
    deinit {
        showShadow(false)
        overlayView.removeFromSuperview()
        sourceView.removeGestureRecognizer(openViewRec)
        targetView.removeGestureRecognizer(closeViewRec)
        xConstraint.isActive = false
        logger?.log("Deinit \(type(of: self))")
    }

    @objc private func handleGesture(_ rec: UIGestureRecognizer) {
        let isOpenGestRec = (rec == openViewRec)
        switch rec.state {
        case .began:
            let point = rec.location(ofTouch: 0, in: sourceView).x
            startingPoint = point
            targetView.superview?.insertChildView(overlayView, belowSubview: targetView)
            overlayView.alpha = isOpenGestRec ? minOverlayAlpha : maxOverlayAlpha
            overlayView.isHidden = false
            showShadow(true)
            if isOpenGestRec {
                willOpen?()
            }
            else {
                willClose?()
            }
        case .changed:
            let point = rec.location(ofTouch: 0, in: sourceView).x
            if isOpenGestRec {
                let maxPoint = viewWidth + startingPoint
                xConstraint.constant = ((point < maxPoint) ? point - startingPoint - viewWidth : 0) + leftOffset
            } else {
                xConstraint.constant = ((point < startingPoint) ? point - startingPoint : 0) + leftOffset
            }
            let percent = (-xConstraint.constant + leftOffset) / viewWidth
            overlayView.alpha = maxOverlayAlpha - maxOverlayAlpha * percent
        case .ended:
            let openRemainder = abs(xConstraint.constant - leftOffset)
            let shouldOpen = openRemainder < viewWidth / 2
            let remainder = ((openRemainder / 2) / (viewWidth / 2))
            let duration = sideBarAnimationDuration * TimeInterval(remainder)

            if shouldOpen {
                open(withDuration: duration, animated: true, wasOpening: isOpenGestRec)
            } else {
                close(withDuration: duration, animated: true, wasClosing: !isOpenGestRec)
            }
        case .cancelled:
            break
        default:
            break
        }
    }
    @objc private func didTapOverlay(_ rec: UIGestureRecognizer) {
        close(withDuration: sideBarAnimationDuration)
    }

    func close(withDuration duration: TimeInterval, animated: Bool = true, wasClosing: Bool = true) {
        xConstraint.constant = -viewWidth + leftOffset
        logger?.log("Constant: \(self.xConstraint.constant)")
        willClose?()
        UIView.animate(withDuration: duration, animations: {
            self.sourceView.layoutIfNeeded()
            self.overlayView.alpha = minOverlayAlpha
        }) { completed in
            if completed {
                self.showShadow(false)
                self.openViewRec.isEnabled = true
                self.overlayView.isHidden = true
                self.didClose?()
            }
        }
    }
    func open(withDuration duration: TimeInterval, animated: Bool = true, wasOpening: Bool = true) {
        showShadow(true)
        xConstraint.constant = leftOffset
        logger?.log("Constant: \(self.xConstraint.constant)")
        overlayView.isHidden = false
        willOpen?();
        UIView.animate(withDuration: duration, animations: {
            self.sourceView.layoutIfNeeded()
            self.overlayView.alpha = maxOverlayAlpha
        }) { completed in
            if completed {
                self.openViewRec.isEnabled = false
                self.didOpen?()
            }
        }
    }

    func showShadow(_ show: Bool) {
        if show {
            targetView.layer.shadowColor = UIColor.black.cgColor
            targetView.layer.shadowOffset = CGSize(width: 2.0, height: 0.0)
            targetView.layer.shadowOpacity = 0.5
            targetView.layer.shadowRadius = 2.5
        }
        targetView.layer.masksToBounds = !show
    }

}
