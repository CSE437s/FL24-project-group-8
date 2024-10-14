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
        
        // Initializer to create FriendRequest from a dictionary
        init(dictionary: [String: Any]) {
            self.fromUser = dictionary["from_user"] as? String ?? ""
            self.toUser = dictionary["to_user"] as? String ?? ""
            self.accepted = dictionary["accepted"] as? Bool ?? false
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
    


    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Sent Friend Requests" // Title for sent requests section
        } else {
            return "Received Friend Requests" // Title for received requests section
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return sentRequests.isEmpty ? 1 : sentRequests.count // Sent requests count
        } else {
            return receivedRequests.isEmpty ? 1 : receivedRequests.count // Received requests count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendRequestCell", for: indexPath)

        if indexPath.section == 0 {
            if sentRequests.isEmpty {
                // Display a message if there are no sent requests
                cell.textLabel?.text = "No sent friend requests"
            } else {
                // Show sent requests in the cell (no accept button needed here)
                let friendRequest = sentRequests[indexPath.row]
                cell.textLabel?.text = "Sent to: \(friendRequest.toUser)"
            }
        } else {
            if receivedRequests.isEmpty {
                // Display a message if there are no received requests
                cell.textLabel?.text = "No received friend requests"
            } else {
                // Show received requests in the cell (with an accept button if not accepted)
                let friendRequest = receivedRequests[indexPath.row]
                cell.textLabel?.text = "From: \(friendRequest.fromUser)"
                
                // Add an "Accept" button for received friend requests (only if not accepted)
                if !friendRequest.accepted {
                    let acceptButton = UIButton(type: .system)
                    acceptButton.setTitle("Accept", for: .normal)
                    acceptButton.frame = CGRect(x: 200, y: 10, width: 100, height: 30)
                    acceptButton.tag = indexPath.row
                    acceptButton.addTarget(self, action: #selector(acceptRequestButtonTapped), for: .touchUpInside)
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


