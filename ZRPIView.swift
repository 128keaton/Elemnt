//
//  ZoomRotatePanImageView.swift
//
//
//  Created by Keaton Burleson on 10/23/16.
//
//

import Foundation
import UIKit
class ZoomRotatePanImageView: UIImageView, UIGestureRecognizerDelegate {
	var pinchGesture: UIPinchGestureRecognizer!
	var panGesture: UIPanGestureRecognizer!
	var rotateGesture: UIRotationGestureRecognizer!
	var tapGesture: UITapGestureRecognizer!
	var hasZoomed = false
	var originalCenter: CGPoint!

	override init(image: UIImage?, highlightedImage: UIImage?) {
		super.init(image: image, highlightedImage: highlightedImage)
		self.setupGestures()
	}

	override init(image: UIImage?) {
		super.init(image: image)
		self.setupGestures()
	}
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.setupGestures()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.setupGestures()
	}

	func setupGestures() {
		self.isUserInteractionEnabled = true
		pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(sender:)))
		tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
		rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(sender:)))
		panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))

		pinchGesture.delegate = self
		panGesture.delegate = self
		rotateGesture.delegate = self
		tapGesture.delegate = self
		self.originalCenter = self.center
		self.addGestureRecognizer(panGesture)
		self.addGestureRecognizer(pinchGesture)
		self.addGestureRecognizer(tapGesture)
		self.addGestureRecognizer(rotateGesture)
		self.contentMode = .scaleAspectFit

	}
	func reset() {
		self.transform = CGAffineTransform.identity
		self.center = self.originalCenter
		self.hasZoomed = false
	}
	func reset(withAnimation: Bool) {
		if withAnimation == false {
			self.reset()
		} else {
			UIView.animate(withDuration: 0.25, animations: {
				self.transform = CGAffineTransform.identity
				self.center = self.originalCenter
			               })
		}
		self.hasZoomed = false
	}
	func handleTap(sender: UITapGestureRecognizer) {
		self.reset(withAnimation: true)
	}
	func handleRotate(sender: UIRotationGestureRecognizer) {
		sender.view?.transform = self.transform.rotated(by: sender.rotation)
		sender.rotation = 0


	}
	func handlePinch(sender: UIPinchGestureRecognizer) {
		self.hasZoomed = true
		sender.view?.transform = self.transform.scaledBy(x: sender.scale, y: sender.scale)
		sender.scale = 1

	}
	func handlePan(sender: UIPanGestureRecognizer) {
		if sender.state == .began || sender.state == .changed {
			if hasZoomed == true {
				let translation = sender.translation(in: self.superview)
				let translationCenter = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)

				self.center = translationCenter
				sender.setTranslation(CGPoint.zero, in: self)
			}
		}
	}
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}
