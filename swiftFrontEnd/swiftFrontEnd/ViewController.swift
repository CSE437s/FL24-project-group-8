//
//  ViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//

import UIKit

struct User: Decodable {
    let key: String
}

class ViewController: UIViewController {
    @IBOutlet weak var usernameForLogin: UITextField!
    @IBOutlet weak var passwordForLogin: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func loginButtonPressed(_ sender: Any) {
            //Todo; use django to login
        guard let username = usernameForLogin.text, !username.isEmpty,
              let password = passwordForLogin.text, !password.isEmpty else {
            showAlert(message: "Please enter username and password.")
            return
        }
        
        // API URL for login
        guard let url = URL(string: "http://127.0.0.1:8000/api/auth/login/") else {
            print("Invalid URL")
            return
        }

        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create the body for the request
        let body: [String: String] = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        // Start the network task
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                // Handle error here
                DispatchQueue.main.async {
                    self?.showAlert(message: "Failed to login: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self?.showAlert(message: "No data returned from server")
                }
                return
            }

            do {
                // Decode the response to User model
                let user = try JSONDecoder().decode(User.self, from: data)
                DispatchQueue.main.async {
                    self?.handleLoginSuccess()
                }
            } catch {
                // Handle decoding errors
                DispatchQueue.main.async {
                    self?.showAlert(message: "Failed to decode response: \(error.localizedDescription)")
                }
            }
        }

        task.resume()
        
    }
    
    private func handleLoginSuccess() {
        // For example, print the username and token (or save them)
        print("Login successful for user:")
//        print("Token: \(user.token)")
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
            
            // Create a UINavigationController with HomeViewController as the root
            let navigationController = UINavigationController(rootViewController: homeViewController)
            
            // Present the UINavigationController modally
            present(navigationController, animated: true, completion: nil)
        // Navigate to the next screen, such as the homepage
       
//        if let homeViewController = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
//                print("in if")
//                navigationController?.pushViewController(homeViewController, animated: true)
//            } else {
//                print("Could not instantiate HomeViewController")
//            }
    }
    
    private func showAlert(message: String) {
           let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           present(alert, animated: true, completion: nil)
       }
    

}

