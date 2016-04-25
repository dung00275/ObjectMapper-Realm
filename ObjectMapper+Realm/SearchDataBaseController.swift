//
//  SearchDataBaseController.swift
//  ObjectMapper+Realm
//
//  Created by Dung Vu on 4/25/16.
//  Copyright © 2016 Dung Vu. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class SearchDataBaseController: UIViewController {
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var items:List<Model> = List<Model>()
    var realm:Realm?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do{
            
            realm = try Realm()
        }catch let error as NSError{
            showAlertError(error,controller: self)
            
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
}

extension SearchDataBaseController:UITableViewDataSource{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell")
        
        if cell == nil{
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "Cell")
            
        }
        
        let item = items[indexPath.item]
        cell?.textLabel?.text = item.name
        cell?.detailTextLabel?.text = item.fullName
        
        return cell!
    }
}

extension SearchDataBaseController:UISearchBarDelegate{
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            searchBar.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        do{
            try searchInDataBase(searchBar.text)
        }catch let error as NSError {
            showAlertError(error, controller: self)
        }
        
    }
    
    func searchInDataBase(query:String?) throws{
        guard let query = query where query.characters.count > 0 else{
            throw NSError(domain: "com.demo", code: 676, userInfo: [NSLocalizedDescriptionKey:"No Keyword to Search!!!"])
        }
        
        defer{
            tableView.reloadData()
        }
        
        let predicate = NSPredicate(format: "name BEGINSWITH [c]%@", query)
        self.items.removeAll()        
        guard let result = realm?.objects(Model).filter(predicate) where result.count > 0 else{
            throw NSError(domain: "com.demo", code: 5464, userInfo: [NSLocalizedDescriptionKey:"No Item!!!"])
        }
        
        for item in result{
            items.append(item)
        }
    }
    
    
}