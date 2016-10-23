//
//  DetailViewController.swift
//  Elemnt
//
//  Created by Keaton Burleson on 10/22/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit
import ChameleonFramework

class DetailViewController: UIViewController {

	@IBOutlet var textArea: UITextView!
	@IBOutlet var imageView: UIImageView!

	var colors: UIImageColors!

	var imageData: Data!
	func configureView() {
		// Update the user interface for the detail item.

		if let detail = self.detailItem {
			self.title = detail["name"] as! String!
			if let textView = self.textArea, let elementImage = self.imageView {
				var element = [String: Any]()
				for (key, value) in detail {
					element[key as! String] = value
				}

				if element["image"] != nil {
					textView.text = element["desc"] as! String!
					elementImage.getFrom(data: element["image"] as! Data, contentMode: .scaleAspectFit)

					DispatchQueue.init(label: "128keaton",
					                   qos: .background,
					                   target: nil).async {
						self.colors = self.imageView.image?.getColors()

						let color = UIColor.init(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.view.frame, andColors: [UIColor(cgColor: (self.colors?.primaryColor.cgColor)!), UIColor.black])
						self.imageView.tintColor = color

						DispatchQueue.main.sync {
							let realColor = self.imageView.tintColor
							UIView.animate(withDuration: 0.3, animations: {
								self.view.backgroundColor = realColor

							               })
							//CAUSE NESTING BRAH
							//SUPER NESTING!
						}
					}
				}

			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
			NotificationCenter.default.addObserver(self, selector: #selector(DetailViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

		self.configureView()
		self.imageView.layer.cornerRadius = 8



	}
	func rotated()
	{
		//fix for gradient wierdness when rotating

		DispatchQueue.init(label: "128keaton",
		                   qos: .background,
		                   target: nil).async {

			let color = UIColor.init(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.view.frame, andColors: [UIColor(cgColor: (self.colors?.primaryColor.cgColor)!), UIColor.black])
			self.imageView.tintColor = color

			DispatchQueue.main.sync {
				let realColor = self.imageView.tintColor
				UIView.animate(withDuration: 0.3, animations: {
					self.view.backgroundColor = realColor

				               })

			}
		}

	}


	func updateScrollviewSizing() {
		var contentRect: CGRect?
		for view in self.view.subviews {
			if view is UIScrollView {
				let scrollView = view as! UIScrollView
				for view in scrollView.subviews {
					contentRect = CGRect().union(view.frame)
				}
				scrollView.contentSize = (contentRect?.size)!
			}
		}
	}
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	var detailItem: NSDictionary! {
		didSet {
			// Update the view.
				self.configureView()
		}
	}


}

