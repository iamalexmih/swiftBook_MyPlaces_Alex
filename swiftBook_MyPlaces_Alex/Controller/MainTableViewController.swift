//
//  MainTableViewController.swift
//  swiftBook_MyPlaces_Alex
//
//  Created by Алексей Попроцкий on 10.07.2022.
//

import UIKit
import RealmSwift

class MainTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var searchController = UISearchController(searchResultsController: nil)
    private var places: Results<Place>!
    private var ascendingSort = true // will be used for Sorted Reversed
    private var filteredPlaces: Results<Place>!
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        places = realm.objects(Place.self)
        
        //Setup the search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
//MARK: - other funcs
    
    func setRatingMainScreen(rating: Double, cell: CustomCell) {

        let ratingInt = Int(rating) - 1
        
        for indexStar in 0...4 {
            cell.starsCollection[indexStar].image = #imageLiteral(resourceName: "emptyStar") // обнуляем звезды
        }
        
        if ratingInt<0 { return }
        
        for indexStar in 0...ratingInt {
            cell.starsCollection[indexStar].image = #imageLiteral(resourceName: "filledStar")
        }
    }
    
    private func sorting() {
        if segmentedControlSorted.selectedSegmentIndex == 0 {
            places = places.sorted(byKeyPath: "date", ascending: ascendingSort)
        } else {
            places = places.sorted(byKeyPath: "name", ascending: ascendingSort)
        }
        tableView.reloadData()
    }
    
//MARK: - IBActions and IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControlSorted: UISegmentedControl!
    @IBOutlet weak var labelButtonSortedReversed: UIBarButtonItem!
        
    @IBAction func actionSegmentedControl(_ sender: UISegmentedControl) {
        sorting()
    }
    
    @IBAction func pressButtonSortedReversed(_ sender: Any) {
        ascendingSort.toggle()
        if ascendingSort {
            labelButtonSortedReversed.image = #imageLiteral(resourceName: "AZ")
        } else {
            labelButtonSortedReversed.image = #imageLiteral(resourceName: "ZA")
        }
        sorting()
    }
    
// MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredPlaces.count
        }
        return places.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
        
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        
        cell.labelName.text = place.name
        cell.labelLocation.text = place.location
        cell.labelTypePlace.text = place.type
        cell.imagePreviewPlace.image = UIImage(data: place.imageData!)
        setRatingMainScreen(rating: place.rating, cell: cell)
        
        return cell
    }
    
// MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    //Delete info "Place".
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let place = places[indexPath.row]
        if editingStyle == .delete {
            // Delete the row from the data source
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
// MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueEditPlace" {
            guard let indexPathSelectCell = tableView.indexPathForSelectedRow else { return }
        
            let placeForEdit = isFiltering ? filteredPlaces[indexPathSelectCell.row] : places[indexPathSelectCell.row]
            
            let editPlaceVC = segue.destination as! NewPlacesController
            editPlaceVC.currentPlace = placeForEdit
        }
    }
    
    @IBAction func unwindSegue(_ unwindSegue: UIStoryboardSegue) {
        
        guard let newPlaceVC = unwindSegue.source as? NewPlacesController else { return }
        newPlaceVC.savePlace()
        tableView.reloadData()
    }
}


// MARK: - Extension
extension MainTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults( for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText)
        tableView.reloadData()
    }
}
