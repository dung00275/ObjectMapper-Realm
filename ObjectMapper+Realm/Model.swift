//
//  Model.swift
//  ObjectMapper+Realm
//
//  Created by Dung Vu on 4/25/16.
//  Copyright © 2016 Dung Vu. All rights reserved.
//

import Foundation
import ObjectMapper
import Realm
import RealmSwift

class Model: Object, Mappable {
    
    dynamic var identify:NSInteger = 0
    dynamic var name:String?
    dynamic var fullName:String?
    dynamic var createAt:String?
    dynamic var updateAt:String?
    
    required convenience init?(_ map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        identify <- map["id"]
        name <- map["name"]
        fullName <- map["full_name"]
        createAt <- map["created_at"]
        updateAt <- map["updated_at"]
    }
}

class ServerResponse: Mappable {
    var totalCount:Int?
    var items:List<Model>?
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        totalCount <- map["total_count"]
        items <- (map["items"],ArrayTransform<Model>())
    }
}

// MARK: ---  Transform List Realm
class ArrayTransform<T:RealmSwift.Object where T:Mappable> : TransformType {
    typealias Object = List<T>
    typealias JSON = Array<AnyObject>
    
    let mapper = Mapper<T>()
    
    func transformFromJSON(value: AnyObject?) -> List<T>? {
        let result = List<T>()
        if let tempArr = value as! Array<AnyObject>? {
            for entry in tempArr {
                let mapper = Mapper<T>()
                let model : T = mapper.map(entry)!
                result.append(model)
            }
        }
        return result
    }
    
    func transformToJSON(value: Object?) -> JSON? {
        var results = [AnyObject]()
        if let value = value {
            for obj in value {
                let json = mapper.toJSON(obj)
                results.append(json)
            }
        }
        return results
    }
}
