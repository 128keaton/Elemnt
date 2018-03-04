//
//  MasterViewController.swift
//  Elemnt
//
//  Created by Keaton Burleson on 10/22/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit
import CoreData
import HTMLReader
import Alamofire
import MobileCoreServices

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UITableViewDragDelegate {
	
	
	var detailViewController: DetailViewController? = nil
	var managedObjectContext: NSManagedObjectContext? = nil

	var dataDictionary: NSMutableDictionary?
	var dataArray: [String]? = []
	var sortedArray: [String]? = []

	var filteredNameArray: [String]? = []
	var filteredNumberArray: [String]? = []
	var filteredArray: [String]? = []
	var settingsDictionary: [String: Any] = ["enableSpelling": 0, "version": 0]
	
	var sortedAtomically = false
	
	
	let searchController = UISearchController(searchResultsController: nil)
	
	
	override func viewDidAppear(_ animated: Bool) {
		self.addGestures()
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UINib(nibName: "ElementItemCell", bundle: nil), forCellReuseIdentifier: "elementCell")

		if let split = self.splitViewController {
			let controllers = split.viewControllers
			self.detailViewController = (controllers[controllers.count - 1] as! UINavigationController).topViewController as? DetailViewController
		}
		
		if #available(iOS 11.0, *) {
			self.navigationController?.navigationBar.prefersLargeTitles = true
		}
		
		
		
		searchController.searchResultsUpdater = self
		searchController.dimsBackgroundDuringPresentation = false
		searchController.searchBar.placeholder = "112"
		searchController.searchBar.sizeToFit()
		searchController.searchBar.barStyle = .black
		searchController.searchBar.barTintColor = UIColor.black
		searchController.searchBar.delegate = self
		searchController.searchBar.scopeButtonTitles = ["Number", "Title"]

		definesPresentationContext = true
		tableView.tableHeaderView = searchController.searchBar
		if #available(iOS 11.0, *) {
			tableView.dragDelegate = self
		}
		extendedLayoutIncludesOpaqueBars = true
		
		setupData(mode: .Alphabetically)

		downloadSettings()

	}
	
	func addGestures() {
		let sortTap = UITapGestureRecognizer(target: self, action: #selector(resort))
		sortTap.numberOfTapsRequired = 2
		self.navigationController?.navigationBar.addGestureRecognizer(sortTap)
		
		let titleTap = UITapGestureRecognizer(target: self, action: #selector(openTitleMenu))
		titleTap.numberOfTapsRequired = 1
		self.navigationController?.navigationBar.addGestureRecognizer(titleTap)
		
		titleTap.require(toFail: sortTap)
		
	}
	
	@objc func openTitleMenu() {
		self.showActionMenu()
	}
	func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
		if searchBar.selectedScopeButtonIndex == 0 {
			filterContentForSearchText(searchText: searchController.searchBar.text!, scope: .Numerically)
			searchBar.placeholder = "112"
		} else {
			filterContentForSearchText(searchText: searchController.searchBar.text!, scope: .Alphabetically)
			searchBar.placeholder = "Hydrogen"
		}

	}

	@IBAction func returnToHome(segue: UIStoryboardSegue) {

	}
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 0
	}
	
	func filterContentForSearchText(searchText: String, scope: DataMode) {

		let predicate = NSPredicate(format: "SELF beginswith[c] %@", searchText)
		filteredNameArray = dataArray?.filter({ (element) -> Bool in
			return predicate.evaluate(with: element)
		})

		filteredNumberArray = dataArray?.filter({ (element) -> Bool in
			return predicate.evaluate(with: String(getAtomicNumber(forValue: element)))
		})

		if scope == .Alphabetically {
			filteredArray = filteredNameArray
		} else {
			filteredArray = filteredNumberArray
		}
		self.tableView.reloadData()

	}
	func downloadSettings() {
		if let settings = UserDefaults.standard.object(forKey: "settings") {
			settingsDictionary = settings as! [String: Any]
		}
		Alamofire.request("https://raw.githubusercontent.com/128keaton/Elemnt/swift/settings.plist").responsePropertyList { response in
			if let plist = response.result.value {
				if (plist as! [String: Any])["version"] as! NSNumber != (self.settingsDictionary["version"]) as! NSNumber {
					self.settingsDictionary = plist as! [String: Any]
					UserDefaults.standard.set(self.settingsDictionary, forKey: "settings")
					UserDefaults.standard.synchronize()

				}
			}
		}
	}
	func downloadElements() -> NSMutableDictionary {
		var dictionary: NSMutableDictionary?
		Alamofire.request("https://raw.githubusercontent.com/128keaton/Elemnt/swift/remote_data.plist").responsePropertyList { response in
			
			if let plist = response.result.value {
				dictionary = plist as? NSMutableDictionary
			} else {
				if let path = Bundle.main.path(forResource: "data", ofType: "plist") {
					dictionary = NSMutableDictionary(contentsOfFile: path)
				}
			}
		}
		if dictionary == nil {
			if let path = Bundle.main.path(forResource: "data", ofType: "plist") {
				dictionary = NSMutableDictionary(contentsOfFile: path)
			}
		}
		return dictionary!
	}
	
	func showActionMenu() {
		let actionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		let spellFunction = UIAlertAction(title: "Spell in elements (beta)", style: .default, handler: { (UIAlertAction) in
			self.performSegue(withIdentifier: "showSpell", sender: self)
		})
		let aboutFunction = UIAlertAction(title: "About", style: .default, handler: { (UIAlertAction) in
			self.performSegue(withIdentifier: "showAbout", sender: self)
		})
		let cancelFunction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (UIAlertAction) in
			self.dismiss(animated: true, completion: nil)
		})

		if settingsDictionary["enableSpelling"] as! NSNumber != 0 {
			actionMenu.addAction(spellFunction)
		}
		actionMenu.addAction(aboutFunction)
		actionMenu.addAction(cancelFunction)
		actionMenu.popoverPresentationController?.sourceView = self.view
		self.present(actionMenu, animated: true, completion: nil)
	}
	
	@objc func resort() {
		if sortedAtomically == true {
			sortedAtomically = false
			setupData(mode: .Alphabetically)
		} else {
			sortedAtomically = true
			setupData(mode: .Numerically)
		}
	}

	func parseURL() {
		var newElementsDictionary: [String: Any]! = [:]

		for i in 0..<10 {
			var stringNumber: String!
			if i < 100 && i > 9 {
				stringNumber = String("0\(i)")
			} else if i <= 9 {
				stringNumber = String("00\(i)")
			} else {
				stringNumber = String(i)
			}
			let requestURL = "http://periodictable.com/Elements/\(stringNumber!)/index.html"
			Alamofire.request(requestURL).responseString { response in
				let document = HTMLDocument(string: response.result.value!)
				let firstTable = document.firstNode(matchingSelector: "table")
				let ourRow = firstTable?.nodes(matchingSelector: "tr")
				let rowTest = ourRow?[10].nodes(matchingSelector: "td")[3]
				let h1 = rowTest?.firstNode(matchingSelector: "h1")
				let elementName = h1?.textContent
				if elementName != nil {
					let undescription = rowTest?.textContent
					var frmt = "Full technical data\n"

					let range = undescription?.range(of: frmt)
					let removable = undescription?.substring(to: (range?.lowerBound)!)
					var actualDescription = (undescription?.replacingOccurrences(of: removable!, with: ""))
					frmt = "\nDensity"
					
					var atomicWeight = rowTest?.textContent.replacingOccurrences(of: "\(elementName!)\n", with: "")
					if let atomicWeightRange = atomicWeight?.range(of: "Density") {
						atomicWeight = atomicWeight?.substring(to: atomicWeightRange.lowerBound)
					}

					var density = rowTest?.textContent.replacingOccurrences(of: "\(elementName!)\n", with: "").replacingOccurrences(of: atomicWeight!, with: "")
					if let densityRange = density?.range(of: "Melting") {
						density = density?.substring(to: densityRange.lowerBound)

					}
					
					var meltingPoint = rowTest?.textContent.replacingOccurrences(of: "\(elementName!)\n", with: "").replacingOccurrences(of: atomicWeight!, with: "").replacingOccurrences(of: density!, with: "").replacingOccurrences(of: "g/cm3", with: "")

					if let meltingPointRange = meltingPoint?.range(of: "Boiling") {
						meltingPoint = meltingPoint?.substring(to: meltingPointRange.lowerBound)
					}
					var boilingPoint = rowTest?.textContent.replacingOccurrences(of: "\(elementName!)\n", with: "").replacingOccurrences(of: atomicWeight!, with: "").replacingOccurrences(of: density!, with: "").replacingOccurrences(of: meltingPoint!, with: "").replacingOccurrences(of: "g/cm3", with: "")

					if let boilingPointRange = boilingPoint?.range(of: "\nFull technical data\n") {
						boilingPoint = boilingPoint?.substring(to: boilingPointRange.lowerBound)
					}
					let dataDictionary = ["atomicWeight": atomicWeight?.replacingOccurrences(of: "[note]", with: "*").replacingOccurrences(of: "\(String(describing: elementName))\n", with: "").replacingOccurrences(of: "Atomic Weight", with: "").replacingOccurrences(of: "\n", with: ""), "density": density?.replacingOccurrences(of: "[note]", with: "*").replacingOccurrences(of: "Density", with: "").replacingOccurrences(of: "\n", with: ""), "meltingPoint": meltingPoint?.replacingOccurrences(of: "[note]", with: "*").replacingOccurrences(of: "Melting Point", with: "").replacingOccurrences(of: "\n", with: ""), "boilingPoint": boilingPoint?.replacingOccurrences(of: "[note]", with: "*").replacingOccurrences(of: "Boiling Point", with: "").replacingOccurrences(of: "\n", with: "")]

					actualDescription = actualDescription?.replacingOccurrences(of: "Full technical data\n", with: "")
					actualDescription = actualDescription?.replacingOccurrences(of: ".Scroll down to see examples of \(elementName!).", with: "")
					
					let elementDictionary = ["name": elementName!, "desc": actualDescription!, "data": dataDictionary, "number": i] as [String: Any]
					newElementsDictionary[elementName!] = elementDictionary
					let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
					let path = paths.appending("/test.plist")

					let testDict = NSDictionary(dictionary: newElementsDictionary)


					testDict.write(toFile: path, atomically: true)

				}
			}
		}
	}



	func setupData(mode: DataMode) {
		dataArray?.removeAll()
		sortedArray?.removeAll()
		
		self.dataDictionary = self.downloadElements()
		
		for name in (dataDictionary?.allKeys)! {

			dataArray?.append(name as! String)
		}
		if mode == .Alphabetically {
			sortedArray = dataArray?.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending })
		} else {
			sortedArray = dataArray?.sorted(by: { self.getAtomicNumber(forValue: $0) < self.getAtomicNumber(forValue: $1) })
		}
		self.tableView.reloadData()
	}

	func getAtomicNumber(forValue: String) -> Int {
		let key = NSString(string: forValue)
		let dictionary = self.dataDictionary?.object(forKey: key) as! [String: Any]
		let number = Int(truncating: dictionary["number"] as! NSNumber)

		return number
	}
	override func viewWillAppear(_ animated: Bool) {
		self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
		super.viewWillAppear(animated)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
			self.navigationController?.navigationBar.gestureRecognizers?.removeAll()
			var name: NSString?
			let indexPath = self.tableView.indexPathForSelectedRow
			if searchController.isActive == true && searchController.searchBar.text != "" {
				let rawName = filteredArray?[(indexPath?.row)!]
				name = NSString(string: rawName!)
			} else {
				let rawName = sortedArray?[(indexPath?.row)!]
				name = NSString(string: rawName!)
			}

			if let element = dataDictionary?.object(forKey: name!) {
				(segue.destination.childViewControllers[0] as! DetailViewController).detailItem = element as? NSDictionary
			}

		}
	}


// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		self.performSegue(withIdentifier: "showDetail", sender: self)
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if searchController.isActive && searchController.searchBar.text != "" {
			return (self.filteredArray?.count)!
		}
		return self.sortedArray!.count
	}
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		//because I LOVE SPEED
		return 84
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "elementCell", for: indexPath) as! ElementItemCell
		var name: NSString?
		if searchController.isActive == true && searchController.searchBar.text != "" {
			let rawName = filteredArray?[indexPath.row]
			name = NSString(string: rawName!)
		} else {
			let rawName = sortedArray?[indexPath.row]
			name = NSString(string: rawName!)
		}
		
		if let element = dataDictionary?.object(forKey: name!) {
			let element = element as! NSDictionary
			cell.number?.text = "\(element["number"]!)"
			cell.elementImage?.loadImageNamed(name: name! as String)
		}
		cell.name?.text = (name! as String)
		return cell
	}
	
	
	func getImageData(elementName: String) -> URL{
		// Define a UIImage object
		let elementImage = UIImage.init(named: "\(elementName).JPG")!
		let elementImageData = UIImageJPEGRepresentation(elementImage, 0.8)
		
		// Write to temporary url *sigh*
		let temporaryURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())\(elementName).JPG")
		print(temporaryURL)
		try! elementImageData?.write(to: temporaryURL)
		return temporaryURL
	}
	
	@available(iOS 11.0, *)
	func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
		var elementName = "Hydrogen"
		
		if searchController.isActive == true && searchController.searchBar.text != "" {
			elementName = (filteredArray?[indexPath.row])!
		} else {
			elementName = (sortedArray?[indexPath.row])!
		}
		
		let itemProvider = NSItemProvider(contentsOf:self.getImageData(elementName: elementName) )
		
		return [
			UIDragItem(itemProvider: itemProvider!)
		]
	}
	
	
	@available(iOS 11.0, *)
	func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		return self.dragItems(for: indexPath)
	}
	
}



extension MasterViewController: UISearchResultsUpdating {
	@available(iOS 8.0, *)
	public func updateSearchResults(for searchController: UISearchController) {
		let searchBar = searchController.searchBar
		if searchBar.selectedScopeButtonIndex == 0 {
			filterContentForSearchText(searchText: searchController.searchBar.text!, scope: .Numerically)
		} else {
			filterContentForSearchText(searchText: searchController.searchBar.text!, scope: .Alphabetically)
		}

	}

	func updateSearchResultsForSearchController(searchController: UISearchController) {
		let searchBar = searchController.searchBar
		if searchBar.selectedScopeButtonIndex == 0 {
			filterContentForSearchText(searchText: searchController.searchBar.text!, scope: .Numerically)
		} else {
			filterContentForSearchText(searchText: searchController.searchBar.text!, scope: .Alphabetically)
		}

	}
}

