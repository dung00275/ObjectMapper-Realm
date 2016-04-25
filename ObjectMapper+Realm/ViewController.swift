//
//  ViewController.swift
//  ObjectMapper+Realm
//
//  Created by Dung Vu on 4/25/16.
//  Copyright © 2016 Dung Vu. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper
import RealmSwift

let kBaseGitHub = "https://api.github.com"

private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}

enum Router:URLRequestConvertible {
    case Repositories(string:String)
    
    var URLRequest: NSMutableURLRequest{
        var params:[String:AnyObject]?
        var urlRequest:NSURL!
        
        let baseURL = NSURL(string: kBaseGitHub)
        
        switch self {
        case .Repositories(let query):
           urlRequest = NSURL(string: "search/repositories", relativeToURL: baseURL)!
           params = [String:AnyObject]()
           params?["order"] = "desc"
           params?["q"] = query.URLEscapedString
        }
        
        let request = NSURLRequest(URL: urlRequest)
        let encoding = ParameterEncoding.URL.encode(request, parameters: params)
        return encoding.0
    }
}



class ViewController: UIViewController {

    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var searchBar:UISearchBar!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var serverResponse:ServerResponse?
    
    var realm:Realm?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print(Realm.Configuration.defaultConfiguration.fileURL)
    
        do{
            
            realm = try Realm()
        }catch let error as NSError{
            showAlertError(error,controller: self)
            
        }
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

func showAlertError(error:NSError,controller:UIViewController?){
    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
    let cancel = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
    alert.addAction(cancel)
    
    controller?.presentViewController(alert, animated: true, completion: nil)
    
}

extension ViewController{
    
    
    
    func searchRepo(query:String?,completion:((inner:() throws -> ServerResponse?) ->())?){
        guard let query = query where query.characters.count > 0 else{
            completion?(inner: {throw NSError(domain: "com.demo", code: 676, userInfo: [NSLocalizedDescriptionKey:"No Keyword to Search!!!"])})
            return
        }
        
        let manager = Manager.sharedInstance
        
        manager.request(Router.Repositories(string: query)).response { (_, response, data, error) in
            
            guard let data = data else {
                completion?(inner: {throw NSError(domain: "com.demo", code: 787, userInfo: [NSLocalizedDescriptionKey:"No Data Response!!!"])})
                
                return
            }
            
            do{
                
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                let serverResponse = Mapper<ServerResponse>().map(json)
                
                completion?(inner:{return serverResponse})
                
            }catch let error as NSError{
                completion?(inner:{throw error})
                
            }
            
        }
        
    }
}

extension ViewController:UITableViewDataSource{
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serverResponse?.items?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell")
        
        if cell == nil{
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "Cell")
            
        }
        if let item = serverResponse?.items?[indexPath.item] {
            cell?.textLabel?.text = item.name
            cell?.detailTextLabel?.text = item.fullName
        }
        
        return cell!
    }
    
}


extension ViewController:UISearchBarDelegate{
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            searchBar.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        indicator.startAnimating()
        
        searchRepo(searchBar.text) { [weak self] (inner) in
            self?.indicator.stopAnimating()
            
            do{
                self?.serverResponse =  try inner()
                NSOperationQueue.mainQueue().addOperationWithBlock({ 
                    self?.tableView.reloadData()
                })
                try self?.saveToRealmDataBase()
                
            }catch let error as  NSError {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    showAlertError(error,controller: self)
                    })
            }

        }
    }
    
    func saveToRealmDataBase() throws{
        guard let serverResponse = serverResponse , items = serverResponse.items where items.count > 0 else{
            throw NSError(domain: "com.demo", code: 565, userInfo: [NSLocalizedDescriptionKey:"No Item To Save"])
        }
        
        try realm?.write({ 
            realm?.add(items)
        })
        
    }
}
