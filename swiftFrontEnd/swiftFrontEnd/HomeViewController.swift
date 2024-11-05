//
//  HomeViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//

import UIKit
import UserNotifications


class HomeViewController: UIViewController {

    @IBOutlet weak var usernameTextLabel: UILabel!
    @IBOutlet weak var dailyQuestButton: UIButton!
    @IBOutlet weak var translateButton: UIButton!
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet weak var learnButton: UIButton!
    @IBOutlet weak var createContentButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Request notification authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
        
        
        if let username = UserSession.shared.username {
            usernameTextLabel.text = username
              }
        setupGradientBackground()
        // Setup button styles
          setupButtonAppearance(button: dailyQuestButton, iconName: "calendar")
          setupButtonAppearance(button: createContentButton, iconName: "square.and.pencil")
          setupButtonAppearance(button: translateButton, iconName: "globe")
          setupButtonAppearance(button: friendsButton, iconName: "person.2")
          setupButtonAppearance(button: learnButton, iconName: "book")
        // Do any additional setup after loading the view.
        scheduleDailyQuestReminder() // Schedule the notification
    }
    
    func scheduleDailyQuestReminder() {
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Configure the notification content
        let content = UNMutableNotificationContent()
        content.title = "Daily Quest Reminder"
        content.body = "Don't forget to submit your daily quest in the ASL App!"
        content.sound = .default

        // Set up the trigger to fire at 8:00 PM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 8 // 8 PM
        dateComponents.minute = 37

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create the notification request
        let request = UNNotificationRequest(identifier: "dailyQuestReminder", content: content, trigger: trigger)

        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily quest notification: \(error)")
            }
        }
    }

    
    private func setupButtonAppearance(button: UIButton, iconName: String) {
        // Set icon and title for the button
        let icon = UIImage(systemName: iconName)
        button.setImage(icon, for: .normal)
        
        // Align icon to the left of the title
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .systemBlue // Customize color as needed
        button.setTitleColor(.systemBlue, for: .normal)
        
        // Add padding between icon and title
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        
        // Round corners and add border
        button.layer.cornerRadius = 10 // Adjust radius as needed
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.clipsToBounds = true
    }
    

    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
           
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "loginViewController") as? ViewController {
               loginVC.modalPresentationStyle = .fullScreen
               self.present(loginVC, animated: true, completion: nil)
           }
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
