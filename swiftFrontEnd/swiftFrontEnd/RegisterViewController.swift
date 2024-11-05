import UIKit

struct User: Decodable {
    let username: String
    let email: String
}

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var emailOfUser: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var nameOfUser: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        //dismiss keyboard
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
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        guard let name = nameOfUser.text, !name.isEmpty,
              let email = emailOfUser.text, !email.isEmpty,
              let username = username.text, !username.isEmpty,
              let password = password.text, !password.isEmpty,
              let confirmPassword = confirmPassword.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }
        
        guard let url = URL(string: "http://127.0.0.1:8000/auth/register/") else {
               print("Invalid URL")
               return
           }

           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           
           let body: [String: String] = [
               "username": username,
               "password": password,
               "email": email
           ]
           request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
           
           let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
               if let error = error {
                   DispatchQueue.main.async {
                       self?.showAlert(title: "Error", message: "Failed to register: \(error.localizedDescription)")
                   }
                   return
               }
               
               if let httpResponse = response as? HTTPURLResponse {
                   if httpResponse.statusCode == 201 {
                       // Show success alert with appropriate title
                       DispatchQueue.main.async {
                           self?.showAlert(title: "Success", message: "Registration successful! Please check your email to verify your account.")
                       }
                   } else {
                       // Handle non-201 responses here
                       DispatchQueue.main.async {
                           let responseString = String(data: data ?? Data(), encoding: .utf8) ?? "No response"
                           self?.showAlert(title: "Error", message: "Error: \(httpResponse.statusCode)\nResponse: \(responseString)")
                       }
                   }
               }
           }
           task.resume()
    }
    
    private func handleLoginSuccess(user: User) {
        print("Login successful for user: \(user.username)")
//        let homeViewController = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
//        let navigationController = UINavigationController(rootViewController: homeViewController)
//        present(navigationController, animated: true, completion: nil)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goBackToLoginView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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


    
    
//    @IBAction func registerButtonPressed(_ sender: Any) {
//        
//            //Todo: input the info into API Call to register user
//            
//        guard let name = nameOfUser.text, !name.isEmpty,
//                   let email = emailOfUser.text, !email.isEmpty,
//                   let usernameText = username.text, !usernameText.isEmpty,
//                   let passwordText = password.text, !passwordText.isEmpty,
//                   let confirmPasswordText = confirmPassword.text, !confirmPasswordText.isEmpty else {
//                 showAlert(message: "Please fill in all fields.")
//                 return
//             }
//             
//             // Check if passwords match
//             if passwordText != confirmPasswordText {
//                 showAlert(message: "Passwords do not match.")
//                 return
//             }
//             
//             // API URL for registration
//             guard let url = URL(string: "http://127.0.0.1:8000/auth/register/") else {
//                 print("Invalid URL")
//                 return
//             }
//
//             // Prepare the request
//             var request = URLRequest(url: url)
//             request.httpMethod = "POST"
//             request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//             
//             // Create the body for the request
//             let body: [String: String] = [
//                 "username": usernameText,  // Use the correct variable
//                 "password": passwordText,   // Use the correct variable
//                 "email": email              // Use the correct variable
//             ]
//             
//             request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
//             print(body)
//             
//             // Start the network task
//             let task = URLSession.shared.dataTask(with: request) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
//                 // Check for errors
//                 if let error = error {
//                     DispatchQueue.main.async {
//                         self?.showAlert(message: "Failed to register: \(error.localizedDescription)")
//                     }
//                     return
//                 }
//
//                 // Check for valid data
//                 guard let data = data else {
//                     DispatchQueue.main.async {
//                         self?.showAlert(message: "No data returned from server")
//                     }
//                     return
//                 }
//
//                 // Attempt to decode the response
//                 do {
//                     let user = try JSONDecoder().decode(User.self, from: data)
//                     DispatchQueue.main.async {
//                         self?.handleLoginSuccess()
//                     }
//                 } catch {
//                     let responseString = String(data: data, encoding: .utf8) ?? "No response"
//                     DispatchQueue.main.async {
//                         self?.showAlert(message: "Failed to decode response: \(error.localizedDescription)\nResponse: \(responseString)")
//                     }
//                 }
//             }
//
//             task.resume()
//         }
//         
//         private func showAlert(message: String) {
//             let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
//             alert.addAction(UIAlertAction(title: "OK", style: .default))
//             present(alert, animated: true, completion: nil)
//         }
//         
//         private func handleLoginSuccess() {
//             // Navigate to the next screen or perform any actions after a successful registration
//             print("Registration successful!")
//         }
//     }




  
