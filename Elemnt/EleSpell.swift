//
//  EleSpell.swift
//  Elemnt
//
//  Created by Keaton Burleson on 10/24/16.
//
//

import Foundation
import UIKit
import Alamofire
import HTMLReader
import Agrume

class EleSpell: UIViewController {

	var agrume: Agrume!
	@IBOutlet var textField: UITextField?
	var images: [UIImage]? = []

	var imageURLS: [String]? = []
	func parseURL(string: String) {
		print("parsine \(string)")
		let string = removeSpecialCharsFromString(text: string)
		Alamofire.request("http://periodictable.com/MSP/ElementBanners?preset=" + string.replacingOccurrences(of: " ", with: "%20")).responseString { response in
			print("requesting")
			let document = HTMLDocument(string: response.result.value!)
			let bigTable = document.nodes(matchingSelector: "table")
			if (bigTable.atIndex(index: 3) != nil) || string != ""{
				let validTable = bigTable[3]
				let innerTable = validTable.firstNode(matchingSelector: "table")
				let imageRows = innerTable?.nodes(matchingSelector: "td")
				for td in imageRows! {
					let imageTag = td.firstNode(matchingSelector: "img")
					let img = imageTag?.attributes["src"]
					let image = try! UIImage(data: Data(contentsOf: URL(string: img!)!))!
					
					if (self.imageURLS?.contains(img!))! == false{
						self.imageURLS?.append(img!)
						self.images?.append(image)
					}
				}
				if self.images?.count != 0 {
					print(self.images?.count ?? 0)
					self.showImage()

				}
			}else{
				let alert = UIAlertController(title: "Error", message: "Sorry, '\(string)' cannot be spelled with elements. Try something else.", preferredStyle: .alert)
				let ok = UIAlertAction(title: "Okay", style: .default, handler: { (UIAlertAction) in
					self.dismiss(animated: true, completion: nil)
				})
				alert.addAction(ok)
				self.present(alert, animated: true, completion: nil)
			}
		}

	}

	func removeSpecialCharsFromString(text: String) -> String {
		let okayChars : Set<Character> =
			Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_".characters)
		return String(text.characters.filter {okayChars.contains($0) })
	}
	
	func stitchImages(images: [UIImage], isVertical: Bool) -> UIImage {
		var stitchedImages: UIImage!
		if images.count > 0 {
			var maxWidth = CGFloat(0), maxHeight = CGFloat(0)
			for image in images {
				if image.size.width > maxWidth {
					maxWidth = image.size.width
				}
				if image.size.height > maxHeight {
					maxHeight = image.size.height
				}
			}
			var totalSize: CGSize, maxSize = CGSize(width: maxWidth, height: maxHeight)
			if isVertical {
				totalSize = CGSize(width: maxSize.width, height: maxSize.height * (CGFloat)(images.count))
			} else {
				totalSize = CGSize(width: maxSize.width * (CGFloat)(images.count), height: maxSize.height)
			}
			UIGraphicsBeginImageContext(totalSize)
			for image in images {
				var rect: CGRect, offset = (CGFloat)((images as NSArray).index(of: image))
				if isVertical {
					rect = CGRect(x: 0, y: maxSize.height * offset, width: maxSize.width, height: maxSize.height)
				} else {
					rect = CGRect(x: maxSize.width * offset, y: 0, width: maxSize.width, height: maxSize.height)
				}
				image.draw(in: rect)
			}
			stitchedImages = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
		}
		return stitchedImages
	}


	func shouldShare(image: UIImage) {
		let textToShare = "I spelled " + "geometry" + " in elements!"


		let objectsToShare = [textToShare, image] as [Any]
		let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)


		activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]


		activityVC.popoverPresentationController?.sourceView = self.view
		agrume.present(activityVC, animated: true, completion: nil)
	}

	@IBAction func spell() {
		self.parseURL(string: (self.textField?.text)!)
	}
	func showImage() {

		agrume = Agrume(image: self.stitchImages(images: self.images!, isVertical: false), backgroundBlurStyle: .dark)
		agrume.useActionMenu = true
		if(UIDevice.current.userInterfaceIdiom == .phone){
			agrume.showFrom(self, backgroundSnapshotVC: self)
		}else{
			agrume.showFrom(self, backgroundSnapshotVC: self)
		}

		agrume.didTapActivityButton = { [unowned self] image in
			self.shouldShare(image: image)
		}
		self.images?.removeAll()
		self.imageURLS?.removeAll()


	}

}


