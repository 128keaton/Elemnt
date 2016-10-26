//
//  DetailViewController.swift
//  Elemnt
//
//  Created by Keaton Burleson on 10/22/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit
import ChameleonFramework

class DetailViewController: UITableViewController {

	@IBOutlet var textArea: UITextView!
	@IBOutlet var imageView: UIImageView!

	@IBOutlet var colorView: UIView!
	@IBOutlet var atomicWeight: UILabel!
	@IBOutlet var density: UILabel!
	@IBOutlet var boilingPoint: UILabel!
	@IBOutlet var meltingPoint: UILabel!
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

				
					textView.text = element["desc"] as! String!
				elementImage.image = UIImage(named: "\(detail["name"]!).JPG")

				let data = element["data"] as! [String: String]
				atomicWeight.text = data["atomicWeight"]
				density.text = data["density"]
				boilingPoint.text = data["boilingPoint"]
				meltingPoint.text = data["meltingPoint"]
				
					DispatchQueue.init(label: "128keaton",
					                   qos: .background,
					                   target: nil).async {
						self.colors = UIImage(named: "\(detail["name"]!).JPG")?.getColors()
												
						let color = UIColor.init(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.colorView.frame, andColors: [UIColor(cgColor: (self.colors?.primaryColor.cgColor)!), UIColor.black])
						self.imageView.tintColor = color
	
						DispatchQueue.main.sync {
							let realColor = self.imageView.tintColor
							UIView.animate(withDuration: 0.3, animations: {
								self.colorView.backgroundColor = realColor

							               })
							//CAUSE NESTING BRAH
							//SUPER NESTING!
						}
					}
				

			}
		}
	}


	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0.1
	}
	@IBAction func showSelectionMenu(){
		let alertView = UIAlertController(title: "Share or report?", message: "", preferredStyle: .actionSheet)
		let reportAction = UIAlertAction(title: "Report incorrect", style: .default, handler: { action in
			self.report()
		})
		let shareAction = UIAlertAction(title: "Share", style: .default, handler: { action in
			self.share()
		})
		let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { action in
			self.dismiss(animated: true, completion: nil)
		})
		alertView.addAction(reportAction)
		alertView.addAction(shareAction)
		alertView.addAction(cancelAction)
		self.present(alertView, animated: true, completion: nil)
	}

	func report(){
		
	}
	func share() {
		
		let textToShare = "Check out " + (self.detailItem["name"] as! String) + " on Elemnt!"
		let image = self.imageView.image

		let objectsToShare = [textToShare, image!] as [Any]
		let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)


		activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]


		activityVC.popoverPresentationController?.sourceView = self.view
		self.present(activityVC, animated: true, completion: nil)

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

		if self.detailItem != nil && self.colors != nil {
			DispatchQueue.init(label: "128keaton",
			                   qos: .background,
			                   target: nil).async {

				let color = UIColor.init(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.colorView.frame, andColors: [UIColor(cgColor: (self.colors?.primaryColor.cgColor)!), UIColor.black])
				self.imageView.tintColor = color

				DispatchQueue.main.sync {
					let realColor = self.imageView.tintColor
					UIView.animate(withDuration: 0.3, animations: {
						self.view.backgroundColor = realColor
						self.colorView.backgroundColor = realColor
					               })

				}
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

