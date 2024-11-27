//
//  AddAndSendFriendRequestsViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 10/14/24.
//

import UIKit
import Foundation

class AddAndSendFriendRequestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    

    @IBOutlet weak var enteredUserNameToSendRequest: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    var sentRequests: [FriendRequest] = []
    var receivedRequests: [FriendRequest] = []
    
    struct FriendRequest {
        let fromUser: String
        let toUser: String
        let accepted: Bool
        let timestamp: String
        
        init(dictionary: [String: Any]) {
            self.fromUser = dictionary["from_user"] as? String ?? ""
            self.toUser = dictionary["to_user"] as? String ?? ""
            self.accepted = dictionary["accepted"] as? Bool ?? false
            self.timestamp = dictionary["timestamp"] as? String ?? ""
        }
    }

      
        override func viewDidLoad() {
          super.viewDidLoad()

          tableView.delegate = self
          tableView.dataSource = self
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FriendRequestCell")
          fetchFriendRequests()
        }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
      // Function to fetch friend requests (sent and received)
    private func fetchFriendRequests() {
        guard let currentUsername = UserSession.shared.username else {
            showAlert(message: "User not logged in.")
            return
        }

        guard let url = URL(string: "http://127.0.0.1:8000/friend-request/list/") else {
            showAlert(message: "Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "username": currentUsername
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Failed to fetch friend requests: \(error.localizedDescription)")
                }
                return
            }
            
            if let data = data {
                do {
                    let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    if let sentList = responseDict?["sent_requests"] as? [[String: Any]] {
                        self?.sentRequests = sentList.map { FriendRequest(dictionary: $0) }
                    }
                    
                    if let receivedList = responseDict?["received_requests"] as? [[String: Any]] {
                        self?.receivedRequests = receivedList.map { FriendRequest(dictionary: $0) }
                    }
                    
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.showAlert(message: "Invalid response from server.")
                    }
                }
            }
        }
        task.resume()
    }


    
    
    
    @IBAction func sendFriendRequest(_ sender: Any) {
        guard let currentUsername = UserSession.shared.username,
                     let targetUsername = enteredUserNameToSendRequest.text, !targetUsername.isEmpty else {
                   showAlert(message: "Please enter the username to send the request.")
                   return
               }
        if currentUsername == targetUsername {
               showAlert(message: "You cannot send a friend request to yourself.")
               return
           }
               
               // Call the function to send the friend request
               sendFriendRequestToBackend(fromUsername: currentUsername, toUsername: targetUsername)
        
    }
    
    private func sendFriendRequestToBackend(fromUsername: String, toUsername: String) {
        guard let url = URL(string: "http://127.0.0.1:8000/friend-request/send/") else {
            showAlert(message: "Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "from_username": fromUsername,
            "to_username": toUsername
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Failed to send friend request: \(error.localizedDescription)")
                }
                return
            }
            
            if let data = data {
                do {
                    let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let message = responseDict?["message"] as? String {
                        DispatchQueue.main.async {
                            self?.showAlert(message: message)
                            self!.increaseUserPoints()
                        }
                    } else if let error = responseDict?["error"] as? String {
                        DispatchQueue.main.async {
                            self?.showAlert(message: error)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.showAlert(message: "Invalid response from server.")
                    }
                }
            }
        }
        task.resume()
    }
    
    func increaseUserPoints() {
        // Step 1: Fetch the current points of the user
        getCurrentPoints { [weak self] currentPoints, error in
            // Handle errors if the points could not be fetched
            if let error = error {
                print("Error fetching points: \(error)")
                return
            }
            
            // Ensure currentPoints is available
            guard let currentPoints = currentPoints else {
                print("Failed to fetch current points.")
                return
            }
            
            // Step 2: Increase the points by 1
            let newPoints = currentPoints + 1
            
            // Step 3: Update the points on the backend
            self?.updatePoints(currentPoints: newPoints) { success, message in
                if success {
                    // Successfully updated points
                    print("Success: \(message ?? "")")
                } else {
                    // Error updating points
                    print("Error updating points: \(message ?? "")")
                }
            }
        }
    }


    
    func getCurrentPoints(completion: @escaping (Int?, String?) -> Void) {
        guard let username = UserSession.shared.username else {
            completion(nil, "Username not found in UserSession.")
            return
        }
        
        let urlString = "http://127.0.0.1:8000/user/get-points/?username=\(username)"
        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, "Request failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                completion(nil, "No data received.")
                return
            }
            
            do {
                if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let points = responseJson["points"] as? Int {
                    completion(points, nil)  // Successfully retrieved points
                } else {
                    completion(nil, "Invalid response format.")
                }
            } catch {
                completion(nil, "Failed to parse response data.")
            }
        }
        
        task.resume()
    }

    
    
    func updatePoints(currentPoints: Int, completion: @escaping (Bool, String?) -> Void) {
        guard let username = UserSession.shared.username else {
            completion(false, "Username not found in UserSession.")
            return
        }
        
        let urlString = "http://127.0.0.1:8000/user/update-points/"
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": username,
            "points": currentPoints  // Send updated points value
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            completion(false, "Failed to serialize request body.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "Request failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                completion(false, "No data received.")
                return
            }
            
            do {
                if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = responseJson["message"] as? String {
                    if message == "Points updated successfully." {
                        completion(true, "Points updated successfully.")
                    } else {
                        completion(false, "Failed to update points.")
                    }
                } else {
                    completion(false, "Invalid response format.")
                }
            } catch {
                completion(false, "Failed to parse response data.")
            }
        }
        
        task.resume()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    
    private func acceptFriendRequest(fromUser: String, toUser: String) {
        guard let url = URL(string: "http://127.0.0.1:8000/friend-request/accept/") else {
            showAlert(message: "Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "from_username": fromUser,
            "to_username": toUser
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Failed to accept friend request: \(error.localizedDescription)")
                }
                return
            }
            
            if let data = data {
                do {
                    let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let message = responseDict?["message"] as? String {
                        DispatchQueue.main.async {
                            self?.showAlert(message: message)
                        }
                        self?.fetchFriendRequests()  // Reload after accepting
                    } else if let error = responseDict?["error"] as? String {
                        DispatchQueue.main.async {
                            self?.showAlert(message: error)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.showAlert(message: "Invalid response from server.")
                    }
                }
            }
        }
        task.resume()
    }
    


    // Number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Two sections: Sent and Received
    }

    // Title for each section
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Sent Friend Requests" : "Received Friend Requests"
    }

    // Number of rows for each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? (sentRequests.isEmpty ? 1 : sentRequests.count) : (receivedRequests.isEmpty ? 1 : receivedRequests.count)
    }

    // Populating each row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendRequestCell", for: indexPath)

        if indexPath.section == 0 {
            // Sent requests section
            if sentRequests.isEmpty {
                cell.textLabel?.text = "No sent friend requests"
            } else {
                let request = sentRequests[indexPath.row]
                cell.textLabel?.text = "Sent to: \(request.toUser)"
                // Make sure there is no Accept button in the Sent section
                for subview in cell.contentView.subviews {
                    subview.removeFromSuperview()
                }
            }
        } else {
            // Received requests section
            if receivedRequests.isEmpty {
                cell.textLabel?.text = "No received friend requests"
            } else {
                let request = receivedRequests[indexPath.row]
                cell.textLabel?.text = "From: \(request.fromUser)"

                // Remove any existing subviews (e.g., buttons) before adding new ones
                for subview in cell.contentView.subviews {
                    subview.removeFromSuperview()
                }

                // If the received request is not accepted, show the Accept button
                if !request.accepted {
                    let acceptButton = UIButton(type: .system)
                    acceptButton.setTitle("Accept", for: .normal)
                    acceptButton.setTitleColor(.systemBlue, for: .normal)
                    acceptButton.frame = CGRect(x: cell.contentView.frame.width - 100, y: 10, width: 80, height: 30)
                    acceptButton.tag = indexPath.row // Tag to identify the row
                    acceptButton.addTarget(self, action: #selector(acceptRequestButtonTapped(_:)), for: .touchUpInside)

                    cell.contentView.addSubview(acceptButton)
                }
            }
        }

        return cell
    }



 


    @objc func acceptRequestButtonTapped(_ sender: UIButton) {
        let requestIndex = sender.tag

        // Safeguard: Only proceed if the array is not empty and the index is valid
        if requestIndex >= 0 && requestIndex < receivedRequests.count {
            let friendRequest = receivedRequests[requestIndex]
            
            // Pass the `fromUser` (which is a String) to the `acceptFriendRequest` method
            acceptFriendRequest(fromUser: friendRequest.fromUser, toUser: UserSession.shared.username ?? "")
        } else {
            print("Invalid request index or empty array.")
        }
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


