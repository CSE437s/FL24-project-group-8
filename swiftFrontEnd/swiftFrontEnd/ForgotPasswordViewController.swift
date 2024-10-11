//
//  ForgotPasswordViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 10/11/24.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailOfUser: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func resetPasswordButton(_ sender: Any) {
            
        guard let email = emailOfUser.text, !email.isEmpty else {
             showAlert(title: "Error", message: "Please enter your email.")
             return
         }
         
        guard let url = URL(string: "http://localhost:8000/auth/password-reset/") else {
            showAlert(title: "Error", message: "Invalid URL.")
            return
        }

         
         let body: [String: String] = ["email": email]
         guard let bodyData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
             showAlert(title: "Error", message: "Failed to serialize request data.")
             return
         }
         
         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         request.httpBody = bodyData
         
         let task = URLSession.shared.dataTask(with: request) { data, response, error in
             DispatchQueue.main.async {
                 if let error = error {
                     self.showAlert(title: "Error", message: "Request failed: \(error.localizedDescription)")
                     return
                 }
                 
                 if let httpResponse = response as? HTTPURLResponse {
                     if httpResponse.statusCode == 200 {
                         self.showAlert(title: "Success", message: "Password reset request was successful.")
                     } else {
                         self.showAlert(title: "Error", message: "Account with this email does not exist or invalid email.")
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
