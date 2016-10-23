//
//  MasterViewController.swift
//  Elemnt
//
//  Created by Keaton Burleson on 10/22/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate {

	var detailViewController: DetailViewController? = nil
	var managedObjectContext: NSManagedObjectContext? = nil

	var dataDictionary: NSMutableDictionary?
	var dataArray: [String]? = []


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

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 0
	}
	func filterContentForSearchText(searchText: String, scope: DataMode) {
		filteredNameArray = dataArray?.filter({ (element) -> Bool in
			return element.lowercased().contains(searchText.lowercased())
		                                      })

		filteredNumberArray = dataArray?.filter({ (element) -> Bool in
			return String(getAtomicNumber(forValue: element)).contains(searchText)
		                                        })
		
		if scope == .Alphabetically {
			filteredArray = filteredNameArray
		} else {
			filteredArray = filteredNumberArray
		}


		self.tableView.reloadData()


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
	func setupData(mode: DataMode) {
		dataArray?.removeAll()
		if let path = Bundle.main.path(forResource: "data", ofType: "plist") {
			dataDictionary = NSMutableDictionary(contentsOfFile: path)
		}

		for name in (dataDictionary?.allKeys)! {

			dataArray?.append(name as! String)
		}
		if mode == .Alphabetically {
			dataArray = dataArray?.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending })

		} else {


			dataArray = dataArray?.sorted(by: { self.getAtomicNumber(forValue: $0) < self.getAtomicNumber(forValue: $1) })

		}
		self.tableView.reloadData()
	}

	func getAtomicNumber(forValue: String) -> Int {
		let key = NSString(string: forValue)

		let dictionary = self.dataDictionary?.object(forKey: key) as! [String: Any]

		let number = Int(dictionary["number"] as! String)

		return number!


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
			let indexPath = self.tableView.indexPathForSelectedRow
			let wtf = dataArray?[(indexPath?.row)!]
			let swift = NSString(string: wtf!)
			print(swift)

			if let element = dataDictionary?.object(forKey: swift) {
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
		return self.dataArray!.count
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
			let rawName = dataArray?[indexPath.row]
			name = NSString(string: rawName!)
		}


		if let element = dataDictionary?.object(forKey: name!) {
			let element = element as! NSDictionary
			cell.number?.text = element["number"] as? String
			cell.elementImage?.getFrom(data: element["image"] as! Data, contentMode: .scaleAspectFit)

		}

		cell.name?.text = name as? String
		return cell
	}


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
