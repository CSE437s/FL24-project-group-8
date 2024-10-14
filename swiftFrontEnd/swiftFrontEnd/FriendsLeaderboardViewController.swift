//
//  FriendsLeaderboardViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//
import UIKit
import DGCharts

class FriendsLeaderboardViewController: UIViewController {
    
    // Declare the BarChartView programmatically
    var barChartView: BarChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the BarChartView programmatically
        setupBarChartView()

        // Call the function to fetch friends and display them on the chart
        fetchFriendsList()
    }
    
    // Setup BarChartView programmatically
    func setupBarChartView() {
        // Initialize BarChartView
        barChartView = BarChartView()
        
        // Set the chart view's frame
        barChartView.frame = CGRect(x: 0, y: 100, width: self.view.frame.size.width, height: 300)
        
        // Add the chart view to the view hierarchy
        self.view.addSubview(barChartView)
        
        // Customize the appearance of the chart
        barChartView.noDataText = "No data available"
        barChartView.chartDescription.enabled = false
        barChartView.legend.enabled = true
    }
    
    // Function to fetch the list of friends from the backend
    func fetchFriendsList() {
        // Access the username from UserSession.shared
        guard let username = UserSession.shared.username else {
            print("Username not found in UserSession.")
            return
        }

        guard let url = URL(string: "http://127.0.0.1:8000/get_friends_list?username=\(username)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching friends: \(error)")
                return
            }

            guard let data = data else { return }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let friends = jsonResponse?["friends"] as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.updateChartWithFriends(friends)
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }
        
        task.resume()
    }

    // Function to update the bar chart with friends and made-up leaderboard numbers
    func updateChartWithFriends(_ friends: [[String: Any]]) {
        var entries = [BarChartDataEntry]()
        var friendNames = [String]()

        for (index, friend) in friends.enumerated() {
            guard let friendName = friend["friend"] as? String else { continue }
            let score = Int.random(in: 50...100)  // Generating a random score for the friend
            
            let entry = BarChartDataEntry(x: Double(index), y: Double(score))
            entries.append(entry)
            friendNames.append(friendName)
        }

        // Set up the data set
        let dataSet = BarChartDataSet(entries: entries, label: "Leaderboard Scores")
        dataSet.colors = ChartColorTemplates.joyful()  // Customize colors

        // Set up the bar chart data
        let data = BarChartData(dataSet: dataSet)
        barChartView.data = data

        // Customize the chart appearance
        configureChartAppearance(friendNames)
    }
    
    // Function to configure the chart's appearance (labels, axis, etc.)
    func configureChartAppearance(_ friendNames: [String]) {
        // Set the labels for the x-axis
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: friendNames)
        barChartView.xAxis.granularity = 1
        barChartView.xAxis.labelRotationAngle = -45  // Optional: rotate labels if they overlap

        // Customize y-axis (scores)
        barChartView.leftAxis.axisMinimum = 0
        barChartView.rightAxis.enabled = false  // Hide the right axis
        barChartView.legend.enabled = true  // Show legend
        
        // More customization (optional)
        barChartView.animate(yAxisDuration: 1.0)  // Add animation
    }
}
