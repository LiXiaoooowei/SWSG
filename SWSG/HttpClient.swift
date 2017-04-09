//
//  HttpClient.swift
//  SWSG
//
//  Created by dinhvt on 9/4/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import Foundation

class HttpClient {
    
    typealias PostCallback = (String?, HttpClientError?) -> Void
    
    public func get(urlString: String) {
        let url = URL(string: urlString)
        
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
    
            let json = try! JSONSerialization.jsonObject(with: data, options: [])
            print(json)
        }
    
        task.resume()
    }
    
    public func post(urlString: String, jsonData: Any, authHeaderValue: String, completion: PostCallback?) {
        let data = try! JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        request.httpBody = data
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // check for fundamental networking error
            guard let data = data, error == nil else {
                print("error=\(error)")
                return
            }
            
            // check for http errors
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }
        
        task.resume()
    }
}

enum HttpClientError: Error {
    case networkError
    case httpError
}
