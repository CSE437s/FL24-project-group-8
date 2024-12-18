//import UIKit
//
//struct LoginResponse: Decodable {
//    let success: Bool
//    let message: String? // Assuming there is a key returned when login is successful
//}
//
//class ViewController: UIViewController {
//
//    @IBOutlet weak var passwordForLogin: UITextField!
//    @IBOutlet weak var usernameForLogin: UITextField!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//    
//    @IBAction func loginButtonPressed(_ sender: Any) {
//        guard let username = usernameForLogin.text, !username.isEmpty,
//              let password = passwordForLogin.text, !password.isEmpty else {
//            showAlert(message: "Please enter a valid username and password.")
//            return
//        }
//        
//        // API URL for login
//        guard let url = URL(string: "http://127.0.0.1:8000/auth/login/") else {
//            print("Invalid URL")
//            return
//        }
//
//        // Prepare the request
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        // Create the body for the request
//        let body: [String: String] = ["username": username, "password": password]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
//
//        // Start the network task
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
//                // Decode the response to LoginResponse model
//                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
//                
//                DispatchQueue.main.async {
//                    if loginResponse.success {
//                        // Handle successful login
//                        self?.handleLoginSuccess(key: loginResponse.message)
//                    } else {
//                        // Handle failed login
//                        self?.showAlert(message: "Login failed. Please check your credentials.")
//                    }
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
//    }
//
//    private func handleLoginSuccess(key: String?) {
//        // Handle successful login, e.g., navigate to the home screen
//        print("Login successful with key: \(key ?? "No key returned")")
//        
//        if let homeViewController = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
//            let navigationController = UINavigationController(rootViewController: homeViewController)
//            present(navigationController, animated: true, completion: nil)
//        } else {
//            showAlert(message: "Failed to load HomeViewController")
//        }
//    }
//
//    private func showAlert(message: String) {
//        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//}
import UIKit

struct LoginResponse: Decodable {
    let success: Bool
    let key: String? // Assuming there is a key returned when login is successful
}

class ViewController: UIViewController {

    @IBOutlet weak var passwordForLogin: UITextField!
    @IBOutlet weak var usernameForLogin: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        clearTextFields()
        //dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            view.addGestureRecognizer(tapGesture)
    }
    
    // This method is called every time the view appears, including when returning from HomeViewController
       override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           clearTextFields()  // Call function to clear fields
       }
    


       private func clearTextFields() {
           passwordForLogin.text = ""
           usernameForLogin.text = ""
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
    
    @IBAction func forgotPasswordButtonPressed(_ sender: Any) {
        
        if let forgotPasswordViewController = storyboard?.instantiateViewController(withIdentifier: "ForgotPasswordViewController") as? ForgotPasswordViewController {
                let navigationController = UINavigationController(rootViewController: forgotPasswordViewController)
                present(navigationController, animated: true, completion: nil)
            } else {
                print("Could not instantiate ForgotPasswordViewController")
            }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let username = usernameForLogin.text, !username.isEmpty,
                  let password = passwordForLogin.text, !password.isEmpty else {
                showAlert(message: "Please enter a valid username and password.")
                return
            }
            
            // API URL for login
            guard let url = URL(string: "http://127.0.0.1:8000/auth/login/") else {
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
                // Error handling
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showAlert(message: "Failed to login: \(error.localizedDescription)")
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        self?.showAlert(message: "No response from server")
                    }
                    return
                }

                // Check for HTTP status code
                switch httpResponse.statusCode {
                case 200:
                    // Handle successful login
                    DispatchQueue.main.async {
                        self?.handleLoginSuccess()
                    }
                case 401:
                    // Handle unauthorized error
                    DispatchQueue.main.async {
                        self?.showAlert(message: "Login failed. Please check your credentials.")
                    }
                default:
                    // Handle other status codes
                    DispatchQueue.main.async {
                        self?.showAlert(message: "Error: \(httpResponse.statusCode)")
                    }
                }

                // If you want to print the response body as a string
                if let data = data {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Server Response: \(jsonString)")
                    } else {
                        print("Unable to decode response as string")
                    }
                }
            }

            task.resume()
    }

    private func handleLoginSuccess() {
        // Handle successful login, e.g., navigate to the home screen
//        print("Login successful with key: \(key ?? "No key returned")")
//        
//        if let homeViewController = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
//            let navigationController = UINavigationController(rootViewController: homeViewController)
//            present(navigationController, animated: true, completion: nil)
//        } else {
//            showAlert(message: "Failed to load HomeViewController")
//        }
        UserSession.shared.username = usernameForLogin.text
        clearTextFields()
        if let homeViewController = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
                let navigationController = UINavigationController(rootViewController: homeViewController)
                present(navigationController, animated: true, completion: nil)
            } else {
                print("Could not instantiate HomeViewController")
            }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
