//
//  RusheeTableViewController.swift
//  rush-brad-app
//
//  Created by Tommy Romano on 10/17/16.
//  Copyright © 2016 Tommy Romano. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

struct RusheeInfo {
    var name: String!
    var rating: Double!
    var image: UIImage?
}

class RusheeTableViewController: UITableViewController {
    
    var user: FIRUser!
    var ref: FIRDatabaseReference!
    var rushees: [RusheeInfo] = []

    override func viewDidLoad() {
        print("VIEW LOADED")
        super.viewDidLoad()
        self.ref = FIRDatabase.database().reference().child("rushees")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ref.observe(FIRDataEventType.value, with: { (snapshot: FIRDataSnapshot) in
            if !snapshot.exists() {
                return
            }
            print("GOT SNAPSHOT")
            var newRushees = [RusheeInfo]()
            for item in snapshot.children {
                let value = (item as! FIRDataSnapshot).value as! [String: AnyObject]
                var info = RusheeInfo()
                info.name = "\(value["firstName"]!) \(value["lastName"]!)"
                info.rating = value["averageRating"] as? Double ?? 0.0
                if let url = NSURL(string: (value["pictureURL"] as! String)) {
                    if let data = NSData(contentsOf: url as URL) {
                        info.image = UIImage(data: data as Data)
                    } else {
                        info.image = UIImage(named: "default.png")
                    }
                }
                newRushees.append(info)
            }
            
            self.rushees = newRushees
            self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rushees.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rushee", for: indexPath)
        let rushee = rushees[indexPath.row]
        cell.textLabel?.text = rushee.name
        cell.detailTextLabel?.text = String.init(format: "Rating: %.1f / 5", rushee.rating)
        if let image = rushee.image {
            cell.imageView?.image = image
        }
        return cell
    }

}
