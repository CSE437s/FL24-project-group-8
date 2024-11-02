//
//  ForgotPasswordViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 10/11/24.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailOfUser: UITextField!
    @IBOutlet weak var username: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.3).cgColor,
            UIColor.systemTeal.withAlphaComponent(0.1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    @IBAction func resetPasswordButton(_ sender: Any) {
            
        guard let email = emailOfUser.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email.")
            return
        }
        
        // Ensure username is not empty
        guard let username = username.text, !username.isEmpty else {
            showAlert(title: "Error", message: "Please enter your username.")
            return
        }
        
        // Create the URL
        guard let url = URL(string: "http://localhost:8000/auth/password-reset/") else {
            showAlert(title: "Error", message: "Invalid URL.")
            return
        }
        
        // Prepare the body with both email and username
        let body: [String: String] = ["email": email, "username": username]
        
        // Serialize the body into JSON data
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            showAlert(title: "Error", message: "Failed to serialize request data.")
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "Error", message: "Request failed: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self.showAlert(title: "Success", message: "Password reset request was successful.")
                    } else if httpResponse.statusCode == 404 {
                        self.showAlert(title: "Error", message: "Account with this email and username does not exist.")
                    } else {
                        self.showAlert(title: "Error", message: "Something went wrong. Please try again.")
                    }
                }
                
                if let data = data, let responseData = String(data: data, encoding: .utf8) {
                    print("Response: \(responseData)")
                }
            }
        }
        
        task.resume()
     }

     // Helper function to display an alert
     func showAlert(title: String, message: String) {
         let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
         let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
         alertController.addAction(okAction)
         present(alertController, animated: true, completion: nil)
     }
    
    
    @IBAction func goBackToLoginButtonPressed(_ sender: Any) {
//        if let loginViewController = storyboard?.instantiateViewController(withIdentifier: "loginViewController") as? ViewController {
//              let navigationController = UINavigationController(rootViewController: loginViewController)
//              present(navigationController, animated: true, completion: nil)
//          } else {
//              print("Could not instantiate loginViewController")
//          }
        dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
