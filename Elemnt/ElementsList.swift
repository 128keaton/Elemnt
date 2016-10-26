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

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate {

	var detailViewController: DetailViewController? = nil
	var managedObjectContext: NSManagedObjectContext? = nil

	var dataDictionary: NSMutableDictionary?
	var dataArray: [String]? = []
	var sortedArray: [String]? = []

	var filteredNameArray: [String]? = []
	var filteredNumberArray: [String]? = []
	var filteredArray: [String]? = []

	let searchController = UISearchController(searchResultsController: nil)


	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UINib(nibName: "ElementItemCell", bundle: nil), forCellReuseIdentifier: "elementCell")

		if let split = self.splitViewController {
			let controllers = split.viewControllers
			self.detailViewController = (controllers[controllers.count - 1] as! UINavigationController).topViewController as? DetailViewController
		}

		searchController.searchResultsUpdater = self
		searchController.dimsBackgroundDuringPresentation = false
		searchController.searchBar.placeholder = "112"
		searchController.searchBar.sizeToFit()
		searchController.searchBar.barStyle = .black
		searchController.searchBar.delegate = self
		searchController.searchBar.scopeButtonTitles = ["Number", "Title"]

		definesPresentationContext = true
		tableView.tableHeaderView = searchController.searchBar
		extendedLayoutIncludesOpaqueBars = true

		setupData(mode: .Alphabetically)


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

	@IBAction func showActionMenu() {
		let actionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		let spellFunction = UIAlertAction(title: "Spell in elements", style: .default, handler: { (UIAlertAction) in
			self.performSegue(withIdentifier: "showSpell", sender: self)
		                                  })
		let aboutFunction = UIAlertAction(title: "About Elemnt", style: .default, handler: { (UIAlertAction) in
			self.performSegue(withIdentifier: "showAbout", sender: self)
		                                  })
		let cancelFunction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (UIAlertAction) in
			self.dismiss(animated: true, completion: nil)
		                                   })

		actionMenu.addAction(spellFunction)
		actionMenu.addAction(aboutFunction)
		actionMenu.addAction(cancelFunction)
		actionMenu.popoverPresentationController?.sourceView = self.view
		self.present(actionMenu, animated: true, completion: nil)
	}
	@IBAction func resort(sender: UIBarButtonItem) {
		//stupid, I know, but LAAAAZY
		if sender.image == #imageLiteral(resourceName: "sorted-numerically") {
			sender.image = #imageLiteral(resourceName: "sorted-alphabetically")
			setupData(mode: .Alphabetically)

		} else {
			sender.image = #imageLiteral(resourceName: "sorted-numerically")
			setupData(mode: .Numerically)
		}
	}

	func parseURL() {
		var newElementsDictionary: [String: Any]! = [:]
		
		for i in 0..<10{

	//	let number = self.getAtomicNumber(forValue: element)
		var stringNumber: String!
		if i < 100 && i > 9 {
			stringNumber = String("0\(i)")
		} else if i <= 9 {
			stringNumber = String("00\(i)")
			print(stringNumber)
		} else {
			stringNumber = String(i)
	   }
		let requestURL = "http://periodictable.com/Elements/\(stringNumber!)/index.html"
		print(requestURL)
		Alamofire.request(requestURL).responseString { response in

			let document = HTMLDocument(string: response.result.value!)

			let firstTable = document.firstNode(matchingSelector: "table")

			let ourRow = firstTable?.nodes(matchingSelector: "tr")


			let rowTest = ourRow?[10].nodes(matchingSelector: "td")[3]

			let h1 = rowTest?.firstNode(matchingSelector: "h1")
			let elementName = h1?.textContent

			//	let dataTable = rowTest?.firstNode(matchingSelector: "table")?.nodes(matchingSelector: "tr")

			if elementName != nil {
				let undescription = rowTest?.textContent
				var frmt = "Full technical data\n"

				let range = undescription?.range(of: frmt)
				let removable = undescription?.substring(to: (range?.lowerBound)!)
				var actualDescription = (undescription?.replacingOccurrences(of: removable!, with: ""))



				frmt = "\nDensity"
				//print(undescription)

				var atomicWeight = rowTest?.textContent.replacingOccurrences(of: "\(elementName!)\n", with: "")
				if let atomicWeightRange = atomicWeight?.range(of: "Density"){
					atomicWeight = atomicWeight?.substring(to: atomicWeightRange.lowerBound)
				}
				print(atomicWeight!)

				var density = rowTest?.textContent.replacingOccurrences(of: "\(elementName!)\n", with: "").replacingOccurrences(of: atomicWeight!, with: "")
				if let densityRange = density?.range(of: "Melting"){
					density = density?.substring(to: densityRange.lowerBound)
				
				}

				print(density!)
				var meltingPoint = rowTest?.textContent.replacingOccurrences(of: "\(elementName!)\n", with: "").replacingOccurrences(of: atomicWeight!, with: "").replacingOccurrences(of: density!, with: "").replacingOccurrences(of: "g/cm3", with: "")

				if let meltingPointRange = meltingPoint?.range(of: "Boiling"){
					meltingPoint = meltingPoint?.substring(to: meltingPointRange.lowerBound)
				}
				print(meltingPoint!)


		
				
				var boilingPoint = rowTest?.textContent.replacingOccurrences(of: "\(elementName!)\n", with: "").replacingOccurrences(of: atomicWeight!, with: "").replacingOccurrences(of: density!, with: "").replacingOccurrences(of: meltingPoint!, with: "").replacingOccurrences(of: "g/cm3", with: "")

				if let boilingPointRange = boilingPoint?.range(of: "\nFull technical data\n"){
						boilingPoint = boilingPoint?.substring(to: boilingPointRange.lowerBound)
				}
			
	


				print(boilingPoint!)


				let dataDictionary = ["atomicWeight" : atomicWeight?.replacingOccurrences(of: "[note]", with: "*").replacingOccurrences(of: "\(elementName)\n", with: "").replacingOccurrences(of: "Atomic Weight", with: "").replacingOccurrences(of: "\n", with: ""), "density" : density?.replacingOccurrences(of: "[note]", with: "*").replacingOccurrences(of: "Density", with: "").replacingOccurrences(of: "\n", with: ""), "meltingPoint" : meltingPoint?.replacingOccurrences(of: "[note]", with: "*").replacingOccurrences(of: "Melting Point", with: "").replacingOccurrences(of: "\n", with: ""), "boilingPoint" : boilingPoint?.replacingOccurrences(of: "[note]", with: "*").replacingOccurrences(of: "Boiling Point", with: "").replacingOccurrences(of: "\n", with: "")]

				actualDescription = actualDescription?.replacingOccurrences(of: "Full technical data\n", with: "")
				actualDescription = actualDescription?.replacingOccurrences(of: ".Scroll down to see examples of \(elementName!).", with: "")
						print("Element: \(elementName!).\nDescription: \(actualDescription!)")
				let elementDictionary = ["name": elementName!, "desc": actualDescription!, "data" : dataDictionary, "number" : i] as [String: Any]
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
		if let path = Bundle.main.path(forResource: "data", ofType: "plist") {
			dataDictionary = NSMutableDictionary(contentsOfFile: path)
		}

		for name in (dataDictionary?.allKeys)! {

			dataArray?.append(name as! String)
		}
		if mode == .Alphabetically {
			sortedArray = dataArray?.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending })

		} else {


			sortedArray = dataArray?.sorted(by: { self.getAtomicNumber(forValue: $0) < self.getAtomicNumber(forValue: $1) })

		}

		print(self.dataArray?.count ?? 0)
		self.tableView.reloadData()
	}

	func getAtomicNumber(forValue: String) -> Int {
		let key = NSString(string: forValue)

		let dictionary = self.dataDictionary?.object(forKey: key) as! [String: Any]

		let number = Int(dictionary["number"] as! NSNumber)

		return number


	}
	override func viewWillAppear(_ animated: Bool) {
		self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
		super.viewWillAppear(animated)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
			var name: NSString?
			let indexPath = self.tableView.indexPathForSelectedRow
			if searchController.isActive == true && searchController.searchBar.text != "" {

				let rawName = filteredArray?[(indexPath?.row)!]
				name = NSString(string: rawName!)
			} else {
				let rawName = sortedArray?[(indexPath?.row)!]
				name = NSString(string: rawName!)
			}
			print(name!)

			if let element = dataDictionary?.object(forKey: name!) {
				print(element)
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
			print(self.filteredArray?.count ?? 0)
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

		cell.name?.text = name as? String
		return cell
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

