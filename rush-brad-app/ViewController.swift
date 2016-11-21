//
//  ViewController.swift
//  rush-brad-app
//
//  Created by Tommy Romano on 10/17/16.
//  Copyright © 2016 Tommy Romano. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import Firebase

class ViewController: UIViewController {
    
    var myLoginButton: UIButton!
    var user: FIRUser?

    override func viewDidLoad() {
        if let user = FIRAuth.auth()?.currentUser {
            print("logging in automatically")
            DispatchQueue.main.async(execute: { () -> Void in
                self.user = user
                self.performSegue(withIdentifier: "showMain", sender: self)
            })
        } else {
            myLoginButton = UIButton(type: .custom)
            myLoginButton.backgroundColor = UIColor.purple
            myLoginButton.frame = CGRect(x: 0, y: 0, width: 180, height: 40)
            myLoginButton.center = view.center;
            myLoginButton.setTitle("Login", for: .normal)
            
            // Handle clicks on the button
            myLoginButton.addTarget(self, action: #selector(self.loginButtonClicked), for: .touchUpInside)
            
            // Add the button to the view
            view.addSubview(myLoginButton)
        }
    }
    
    // Once the button is clicked, show the login dialog
    @objc func loginButtonClicked() {
        let loginManager = LoginManager()
        loginManager.loginBehavior = LoginBehavior.systemAccount
        loginManager.logIn([ .publicProfile, .email ], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(_, _, let token):
                print("Logged in!")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: token.authenticationToken)
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                    if let e = error {
                        print("error: " + e.localizedDescription)
                    } else {
                        print("logging in after getting token")
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.user = user
                            self.performSegue(withIdentifier: "showMain", sender: self)
                        })
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMain" {
            print("segueing to main")
            let navVC = segue.destination as! UINavigationController
            let destVC = navVC.viewControllers.first! as! RusheeFormViewController
            destVC.user = self.user!
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }


}

