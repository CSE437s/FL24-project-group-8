//
//  RegisterViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//

import UIKit

class RegisterViewController: UIViewController {
    @IBOutlet weak var nameOfUser: UITextField!
    @IBOutlet weak var emailOfUser: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        //Todo: input the info into API Call to register user
        
        guard let name = nameOfUser.text, !name.isEmpty,
                    let email = emailOfUser.text, !email.isEmpty,
                    let username = username.text, !username.isEmpty,
                    let password = password.text, !password.isEmpty,
                    let confirmPassword = confirmPassword.text, !confirmPassword.isEmpty else {
                  showAlert(message: "Please fill in all fields.")
                  return
              }
              
        // API URL for login
        guard let url = URL(string: "http://127.0.0.1:8000/api/auth/registration/") else {
            print("Invalid URL")
            return
        }

        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the body for the request
        let body: [String: String] = [
            "username": username,
            "password1": password,
            "password2": confirmPassword,
            "email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        print(body)
        // Start the network task
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Failed to register: \(error.localizedDescription)")
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
                let responseString = String(data: data, encoding: .utf8)
                print("Response: \(responseString ?? "No response")")
                
                let user = try JSONDecoder().decode(User.self, from: data)
                DispatchQueue.main.async {
                    self?.handleLoginSuccess()
                }
            } catch {
                DispatchQueue.main.async {
                    let responseString = String(data: data, encoding: .utf8) ?? "No response"
                    self?.showAlert(message: "Failed to decode response: \(error.localizedDescription)\nResponse: \(responseString)")
                }
            }
        }
        task.resume()
        
//        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            if let error = error {
//                // Handle error here
//                DispatchQueue.main.async {
//                    self?.showAlert(message: "Failed to login: \(error.localizedDescription)")
//                }
//                return
//            }
//
//            guard let data = data else {
//                DispatchQueue.main.async {
//                    self?.showAlert(message: "No data returned from server")
//                }
//                return
//            }
//
//            do {
//                // Decode the response to User model
//                let user = try JSONDecoder().decode(User.self, from: data)
//                DispatchQueue.main.async {
//                    self?.handleLoginSuccess()
//                }
//            } catch {
//                // Handle decoding errors
//                DispatchQueue.main.async {
//                    self?.showAlert(message: "Failed to decode response: \(error.localizedDescription)")
//                }
//            }
//        }
//
//        task.resume()
        
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


