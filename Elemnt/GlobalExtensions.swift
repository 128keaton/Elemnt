//
//  GlobalExtensions.swift
//  Elemnt
//
//  Created by Keaton Burleson on 10/25/16.
//
//

import Foundation
import UIKit

// from https://gist.github.com/klein-artur/025a0fa4f167a648d9ea
extension UIColor {
	func getComplementaryColor() -> UIColor {
		
		let ciColor = CIColor(color: self)
		
		// get the current values and make the difference from white:
		let compRed: CGFloat = 1.0 - ciColor.red
		let compGreen: CGFloat = 1.0 - ciColor.green
		let compBlue: CGFloat = 1.0 - ciColor.blue
		
		return UIColor(red: compRed, green: compGreen, blue: compBlue, alpha: 1.0)
	}
}
enum DataMode {
	case Alphabetically
	case Numerically
}

extension UIImageView {
	func getFrom(data: Data, contentMode: UIViewContentMode) {
		
		
		let backgroundQueue = DispatchQueue(label: "128keaton",
		                                    qos: .background,
		                                    target: nil)
		
		backgroundQueue.sync(execute: {
			self.contentMode = contentMode
			self.image = UIImage(data: data)
			
		})
		
	}
	
}

// from https://gist.github.com/fumoboy007/d869e66ad0466a9c246d
public class AsyncImageView: UIImageView {
	private class ImageLoadOperation {
		private(set) var isCancelled: Bool = false
		
		func cancel() {
			isCancelled = true
		}
	}
	private var imageLoadOperation: ImageLoadOperation?
	
	private func cancel() {
		if let imageLoadOperation = imageLoadOperation {
			imageLoadOperation.cancel()
			self.imageLoadOperation = nil
		}
	}
	
	override public var image: UIImage? {
		willSet {
			cancel()
		}
	}
	
	public func loadImageNamed(name: String) {
		cancel()
		
		let pathToImageOrNil = AsyncImageView.pathToImageNamed(name: name)
		guard let pathToImage = pathToImageOrNil else {
			super.image = nil
			return
		}
		
		let imageLoadOperation = ImageLoadOperation()
		self.imageLoadOperation = imageLoadOperation
		
		DispatchQueue.global(qos: .userInteractive).async {
			let imageOrNil = UIImage(contentsOfFile: pathToImage)
			guard let image = imageOrNil else {
				return
			}
			
			let decodedImage = AsyncImageView.decodeImage(image: image)
			
			DispatchQueue.main.async {
				guard !imageLoadOperation.isCancelled else {
					return
				}
				
				super.image = decodedImage
			}
		}
	}
	
	private static func pathToImageNamed(name: String) -> String? {
		let screenScale = UIScreen.main.scale
		
		var resourceNames = [String]()
		switch screenScale {
		case 3:
			resourceNames.append(name + "@3x")
			fallthrough
			
		case 2:
			resourceNames.append(name + "@2x")
			fallthrough
			
		case 1:
			resourceNames.append(name)
			
		default:
			break
		}
		
		for resourceName in resourceNames {
			if let pathToImage = Bundle.main.path(forResource: resourceName, ofType: "JPG") {
				return pathToImage
			}
		}
		
		return nil
	}
	
	private static func decodeImage(image: UIImage) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
		defer {
			UIGraphicsEndImageContext()
		}
		
		image.draw(at: CGPoint.zero)
		
		return UIGraphicsGetImageFromCurrentImageContext()!
	}
}
// from: http://stackoverflow.com/questions/29605708/best-way-to-check-if-object-is-out-of-bounds-in-array

extension Array {
	func atIndex(index: Int) -> Any? {
		if index < 0 || index > self.count - 1 {
			return nil
		}
		return self[index]
	}
}

