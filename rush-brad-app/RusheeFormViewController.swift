//
//  RusheeFormViewController.swift
//  rush-brad-app
//
//  Created by Tommy Romano on 11/20/16.
//  Copyright © 2016 Tommy Romano. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import MobileCoreServices

class RusheeFormViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var netIDField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var yearField: UISegmentedControl!
    @IBOutlet weak var activitiesField: UITextField!
    @IBOutlet weak var rushingWithField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    

    var user: FIRUser!
    var ref: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    var rushees: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Rushee"
        self.ref = FIRDatabase.database().reference().child("rushees")
        self.storageRef = FIRStorage.storage().reference(forURL: "gs://rush-brad.appspot.com").child("rushees")
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(RusheeFormViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        self.cameraButton.addTarget(self, action: #selector(RusheeFormViewController.imageTapped(_:)), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: UIBarButtonItemStyle.plain, target: self, action: #selector(RusheeFormViewController.submit(_:)))
        
        self.getExistingRushees()
    }
    
    func dismissKeyboard() {
        print("tapping")
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func submit(_ sender: AnyObject) {
        validateFields(onSuccess: self.sendToFirebase )
    }
    
    func validateFields(onSuccess successHandler: () -> Void) {
        var error:Bool = false
        for field in [firstNameField, lastNameField, netIDField, phoneField] {
            if field!.text == nil || field!.text?.characters.count == 0 {
                field!.layer.borderWidth = 1.0
                field!.layer.borderColor = UIColor.red.cgColor
                error = true
            } else {
                field!.layer.borderWidth = 0.0
            }
        }
        if error {
            let alert = UIAlertController(title: "Error", message: "Please fill out the required fields", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            successHandler()
        }
    }
    
    func sendToFirebase() {
        let key = self.getKey()
        
        let data = UIImageJPEGRepresentation(fixOrientation(self.imageView.image!), 0.9)
        let imageRef = self.storageRef.child("\(key).jpg")
        
        var json:[String : Any] = [
            "firstName": self.firstNameField.text!,
            "lastName": self.lastNameField.text!,
            "netID": self.netIDField.text!,
            "email": self.netIDField.text! + "@duke.edu",
            "phoneNumber": self.phoneField.text!,
            "year": String(2020 - self.yearField.selectedSegmentIndex),
            "activities": self.activitiesField.text!.toList(),
            "rushingWith": self.rushingWithField.text!.toList()
        ]
        
        if rushees[self.netIDField.text!] == nil {
            json["numRatings"] = 0
        }
        
        let loadingAlert = self.createLoadingAlert()

        present(loadingAlert, animated: true, completion: nil)
        
        imageRef.put(data!, metadata: nil) { metadata, error in
            if (error != nil) {
                print(error!)
            } else {
                let downloadURL = metadata!.downloadURL()
                json["pictureURL"] =  downloadURL!.absoluteString
                self.ref.child(key).updateChildValues(
                    json,
                    withCompletionBlock: { (error, ref) in
                        loadingAlert.dismiss(animated: true, completion: {
                            self.submitCompleteBlock(error: error, ref: ref)
                        })
                })
            }
        }
    }
    
    func createLoadingAlert(withMessage message:String? = nil) -> UIAlertController {
        let loadingAlert = UIAlertController(title: nil, message: message ?? "Please wait...", preferredStyle: .alert)
        
        loadingAlert.view.tintColor = UIColor.black
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        loadingAlert.view.addSubview(loadingIndicator)
        
        return loadingAlert
    }
    
    func getKey() -> String {
        let netID = self.netIDField.text!
        if rushees[netID] == nil {
            return self.ref.childByAutoId().key
        }
        return rushees[netID]!
    }
    
    func imageTapped(_ img: AnyObject) {
        let cam = UIImagePickerControllerSourceType.camera
        let ok = UIImagePickerController.isSourceTypeAvailable(cam)
        if (!ok) {
            print("no camera")
            return
        }
        let desiredType = kUTTypeImage as NSString as String
        let arr = UIImagePickerController.availableMediaTypes(for: cam)
        print(arr ?? "")
        if arr?.index(of: desiredType) == nil {
            print("no capture")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.mediaTypes = [desiredType]
        picker.delegate = self
        
        self.present(picker, animated: true, completion: nil)
    }
    
    func submitCompleteBlock(error: Error?, ref: FIRDatabaseReference) {
        if let e = error {
            let alert = UIAlertController(title: "Error", message: "Could not upload rushee due to error: \(e)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        let alert = UIAlertController(title: "Success", message: "Rushee successfully added", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { _ in
            self.clearFields()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let im = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        self.dismiss(animated: true) {
            let type = info[UIImagePickerControllerMediaType] as? String
            if type != nil {
                switch type! {
                case kUTTypeImage as NSString as String:
                    if im != nil {
                        self.imageView.image = im
                    }
                default:break
                }
            }
        }
    }
    
    func clearFields() {
        for field in [firstNameField, lastNameField, netIDField, phoneField, activitiesField, rushingWithField] {
            field!.text = ""
        }
        imageView.image = #imageLiteral(resourceName: "default.png")
    }
    
    func fixOrientation(_ img:UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImageOrientation.up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.draw(in: rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return normalizedImage;
    }
    
    func getExistingRushees() {
        let loadingAlert = self.createLoadingAlert(withMessage: "Loading rushees...")
        present(loadingAlert, animated: true, completion: nil)
        ref.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot: FIRDataSnapshot) in
            if !snapshot.exists() {
                return
            }
            print("GOT SNAPSHOT")
            var newRushees = [String:String]()
            for item in snapshot.children {
                let snapshot = item as! FIRDataSnapshot
                let values = snapshot.value as! [String: AnyObject]
                let netID = values["netID"] as? String
                if let checked = netID {
                    newRushees[checked] = snapshot.key
                } else {
                    print("Rushee missing netID")
                }
            }
            self.rushees = newRushees
            let alert = UIAlertController(title: nil, message: "Existing rushees loaded", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
            loadingAlert.dismiss(animated: true) {
                self.present(alert, animated: true, completion: nil)
            }
        })
    }

}

extension String {
    
    func toList() -> [String] {
        if (self.characters.count == 0) {
            return []
        }
        let list = self.components(separatedBy: ",")
        return list.map {
            $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
}
