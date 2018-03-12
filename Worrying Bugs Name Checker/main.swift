#!/usr/bin/swift
//
//  main.swift
//  Worrying Bugs Name Checker
//
//  Created by Steven Berry on 3/12/18.
//  Copyright © 2018 Super Awesome Software. All rights reserved.
//

import Foundation

extension String {
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex, let range = self.range(of: string, range: searchStartIndex..<self.endIndex), !range.isEmpty {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }
        
        return indices
    }
}

var sema = DispatchSemaphore( value: 0 )
var siteData = Data()

class Delegate : NSObject, URLSessionDataDelegate
{
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        siteData.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        sema.signal()
    }
}

func internetOn() -> Bool {
    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config, delegate: Delegate(), delegateQueue: nil )
    
    guard let url = URL( string:"http://isup.me" ) else { fatalError("Could not create URL object") }
    
    session.dataTask( with: url ).resume()
    
    sema.wait()
    
    if !siteData.isEmpty {
        siteData = Data()
        return true
    } else {
        return false
    }
}

func getFeedData() -> Data? {
    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config, delegate: Delegate(), delegateQueue: nil )
    
    guard let url = URL( string:"https://stevenberry.rocks/worryingbugs/feed/podcast/" ) else { fatalError("Could not create URL object") }
    
    session.dataTask( with: url ).resume()
    
    sema.wait()
    
    if !siteData.isEmpty {
        return siteData
    } else {
        return nil
    }
}

func checkTitle(string: String, feedData: Data) -> Bool {
    if let stringData = String(data: feedData, encoding: .utf8) {
        let startTitles = stringData.indicesOf(string: "<title>")
        let endTitles = stringData.indicesOf(string: "</title>")
        var titles = [String()]
        
        for i in 0..<startTitles.count {
            let start = stringData.index(stringData.startIndex, offsetBy: startTitles[i] + 7)
            let end = stringData.index(stringData.startIndex, offsetBy: endTitles[i] - 8)
            let range = start..<end
            titles.append(String(stringData[range]))
        }
        
        for title in titles {
            if title.lowercased().contains(string.lowercased()) {
                return true
            }
        }
        
        return false
    } else {
        return true
    }
}


if !internetOn() {
    print("Please check your network connection and try again")
    exit(0)
}

if let feedData = getFeedData() {
    print("What is title?")
    let userTitle = readLine()
    print("loading...")
        if let arguments = userTitle?.split(separator: " ") {
        var anyUsed = false
        for argument in arguments {
            let used = checkTitle(string: String(argument), feedData: feedData)
            if used {
                anyUsed = true
                print("\(argument) has already been used")
            }
        }
        if !anyUsed {
            print("All clear")
        }
    }
}



