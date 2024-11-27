//
//  FriendsLeaderboardViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//
import UIKit
import DGCharts

class ChartMarker: MarkerView {
    var text = ""

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        super.refreshContent(entry: entry, highlight: highlight)
        text = String(entry.y)
    }

    override func draw(context: CGContext, point: CGPoint) {
        super.draw(context: context, point: point)

        var drawAttributes = [NSAttributedString.Key : Any]()
        drawAttributes[.font] = UIFont.systemFont(ofSize: 15)
        drawAttributes[.foregroundColor] = UIColor.white
        drawAttributes[.backgroundColor] = UIColor.darkGray

        self.bounds.size = (" \(text) " as NSString).size(withAttributes: drawAttributes)
        self.offset = CGPoint(x: 0, y: -self.bounds.size.height - 2)

        let offset = self.offsetForDrawing(atPoint: point)

        drawText(text: " \(text) " as NSString, rect: CGRect(origin: CGPoint(x: point.x + offset.x, y: point.y + offset.y), size: self.bounds.size), withAttributes: drawAttributes)
    }

    func drawText(text: NSString, rect: CGRect, withAttributes attributes: [NSAttributedString.Key : Any]? = nil) {
        let size = text.size(withAttributes: attributes)
        let centeredRect = CGRect(x: rect.origin.x + (rect.size.width - size.width) / 2.0, y: rect.origin.y + (rect.size.height - size.height) / 2.0, width: size.width, height: size.height)
        text.draw(in: centeredRect, withAttributes: attributes)
    }
}

class FriendsLeaderboardViewController: UIViewController {
    
    var scrollView: UIScrollView!
    var barChartView: BarChartView!
    var streakChartView: BarChartView!

    
    // Add title label
    var titleLabel: UILabel!
    
    // Add button to demonstrate below the chart
    var actionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the title label
        setupScrollView()
        setupTitleLabel()
        setupGradientBackground()
        // Initialize the BarChartView programmatically
        setupBarChartView()
        setupStreakChartView()
        // Set up the action button
        
        // Call the function to fetch friends and display them on the chart
        fetchFriendsList()
    }
    
    func setupStreakChartView() {
        // Initialize the second BarChartView (Streaks)
        streakChartView = BarChartView()
        
        // Set the frame for the second chart (Streaks)
        let chartHeight = self.view.frame.size.height * 0.25
        streakChartView.frame = CGRect(x: 0, y: barChartView.frame.maxY + 20, width: self.view.frame.size.width, height: chartHeight)
        
        // Add it to the scroll view
        scrollView.addSubview(streakChartView)
        
        // Customize the appearance of the second chart (Streaks)
        streakChartView.noDataText = "No data available"
        streakChartView.chartDescription.enabled = false
        streakChartView.legend.enabled = true
    }

    func fetchFriendStreak(for username: String, completion: @escaping (Int?, String?) -> Void) {
        let urlString = "http://127.0.0.1:8000/user/get-streak/?username=\(username)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
                   let streak = responseJson["streak"] as? Int {
                    print("Fetched streak for \(username): \(streak)")  // Debug print
                    completion(streak, nil)
                } else {
                    completion(nil, "Invalid response format.")
                }
            } catch {
                completion(nil, "Failed to parse response data.")
            }
        }
        
        task.resume()
    }
    

    func updateChartWithStreaks(_ friends: [Any]) {
        var entries = [BarChartDataEntry]()
        var friendNames = [String]()

        let dispatchGroup = DispatchGroup()

        for (index, friend) in friends.enumerated() {
            if let friendData = friend as? [String: Any], let friendUsername = friendData["friend__username"] as? String {
                
                dispatchGroup.enter() // Enter before starting the request
                
                fetchFriendStreak(for: friendUsername) { streak, error in
                    if let error = error {
                        print("Error fetching streak for \(friendUsername): \(error)")
                        dispatchGroup.leave() // Leave the group on error
                        return
                    }
                    
                    guard let streak = streak else {
                        print("No streak found for \(friendUsername)")
                        dispatchGroup.leave() // Leave the group if no streak
                        return
                    }
                    
                    let entry = BarChartDataEntry(x: Double(index), y: Double(streak))
                    entries.append(entry)
                    friendNames.append(friendUsername)
                    
                    dispatchGroup.leave() // Leave after fetching the streak
                }
            } else {
                print("Invalid friend data: \(friend)")
            }
        }

        dispatchGroup.notify(queue: .main) {
            if entries.isEmpty {
                print("No friends or streaks to display.")
                return
            }
            
            let dataSet = BarChartDataSet(entries: entries, label: "Streaks")
            dataSet.colors = ChartColorTemplates.colorful()  // Customize colors

            let data = BarChartData(dataSet: dataSet)
            self.streakChartView.data = data
            
            self.configureStreakChartAppearance(friendNames)
        }
    }

    func configureStreakChartAppearance(_ friendNames: [String]) {
        // Set the labels for the x-axis of the streak chart
        streakChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: friendNames)
        streakChartView.xAxis.granularity = 1
        streakChartView.xAxis.labelPosition = .bottom
        streakChartView.xAxis.labelRotationAngle = -45
        streakChartView.xAxis.wordWrapEnabled = true
        streakChartView.xAxis.labelCount = friendNames.count

        // Customize y-axis (streaks)
        streakChartView.leftAxis.axisMinimum = 0
        streakChartView.rightAxis.enabled = false
        streakChartView.legend.enabled = true

        streakChartView.animate(yAxisDuration: 1.0)
    }
    
    
    func setupScrollView() {
        // Initialize the UIScrollView
        scrollView = UIScrollView()
        
        // Set the scroll view's frame to match the width of the screen
        scrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        // Add the scroll view to the main view
        self.view.addSubview(scrollView)
        
        // Enable scrolling and set content size
        scrollView.isScrollEnabled = true
        scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height * 1.5)
    }
    
    
    
    
    // Function to setup title label
    func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.text = "Friends Leaderboard"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.frame = CGRect(x: 0, y: 50, width: self.view.frame.size.width, height: 50)
        
        self.view.addSubview(titleLabel)
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
    
    private func addRandomCircles() {
        let numberOfCircles = 8  // Number of random circles to generate
        let circleColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        
        for _ in 0..<numberOfCircles {
            let circleSize = CGFloat.random(in: 30...100)  // Random size for each circle
            let circleLayer = CAShapeLayer()
            let circlePath = UIBezierPath(
                ovalIn: CGRect(
                    x: CGFloat.random(in: 0...view.bounds.width - circleSize),
                    y: CGFloat.random(in: 0...view.bounds.height - circleSize),
                    width: circleSize,
                    height: circleSize
                )
            )
            
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = circleColor
            view.layer.insertSublayer(circleLayer, at: 1) // Insert above the gradient layer
        }
    }
    
    // Setup BarChartView programmatically
 
    func setupBarChartView() {
        // Initialize the first BarChartView (Leaderboard scores)
        barChartView = BarChartView()
        
        // Set the frame for the first chart (Leaderboard)
        let chartHeight = self.view.frame.size.height * 0.25
        barChartView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: chartHeight)
        
        // Add it to the scroll view
        scrollView.addSubview(barChartView)
        
        // Customize the appearance of the first chart
        barChartView.noDataText = "No data available"
        barChartView.chartDescription.enabled = false
        barChartView.legend.enabled = true
    }
    
    // Function to setup action button (below the chart)
    func setupActionButton() {
        actionButton = UIButton(type: .system)
        actionButton.setTitle("Action Button", for: .normal)
        actionButton.frame = CGRect(x: 50, y: 500, width: self.view.frame.size.width - 100, height: 50)  // Adjust y-position to be below the chart
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        self.view.addSubview(actionButton)
    }
    
    // Button tap handler
    @objc func buttonTapped() {
        print("Button tapped!")
    }

    func fetchFriendsList() {
        guard let username = UserSession.shared.username else {
            print("Username not found in UserSession.")
            return
        }

        guard let url = URL(string: "http://127.0.0.1:8000/friends/list/?username=\(username)") else {
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

            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("Response from server: \(jsonResponse)")  // Log the full response

                if let friends = jsonResponse?["friends"] as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.updateChartWithFriends(friends)
                    }
                } else {
                    print("No 'friends' data found in the response.")
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }
        
        task.resume()
    }

    func updateChartWithFriends(_ friends: [Any]) {
        var entries = [BarChartDataEntry]()
        var friendNames = [String]()

        // Create a DispatchGroup to handle async operations
        let dispatchGroup = DispatchGroup()

        // Iterate through the friends array
        for (index, friend) in friends.enumerated() {
            if let friendData = friend as? [String: Any], let friendUsername = friendData["friend__username"] as? String {
                
                // Step 1: Make a POST request to get points for each friend
                dispatchGroup.enter() // Enter the group before starting the request
                
                // Fetch the points for each friend
                fetchFriendPoints(for: friendUsername) { score, error in
                    if let error = error {
                        print("Error fetching points for \(friendUsername): \(error)")
                        dispatchGroup.leave() // Leave the group if there's an error
                        return
                    }
                    
                    guard let score = score else {
                        print("No score found for \(friendUsername)")
                        dispatchGroup.leave() // Leave the group if score is nil
                        return
                    }
                    
                    // Step 2: Debugging - print out the friend data and score
                    print("Friend username: \(friendUsername), Score: \(score)")
                    
                    // Create BarChartDataEntry for the score
                    let entry = BarChartDataEntry(x: Double(index), y: Double(score))
                    entries.append(entry)
                    friendNames.append(friendUsername)
                    
                    // Leave the group after fetching the score
                    dispatchGroup.leave()
                }
                
                // Step 2: Fetch the streak for each friend (in parallel to score fetch)
                dispatchGroup.enter() // Enter the group for streak fetching
                
                fetchFriendStreak(for: friendUsername) { streak, error in
                    if let error = error {
                        print("Error fetching streak for \(friendUsername): \(error)")
                        dispatchGroup.leave() // Leave the group if there's an error
                        return
                    }
                    
                    guard let streak = streak else {
                        print("No streak found for \(friendUsername)")
                        dispatchGroup.leave() // Leave the group if streak is nil
                        return
                    }
                    
                    // Step 3: Debugging - print out the friend data and streak
                    print("Friend username: \(friendUsername), Streak: \(streak)")
                    
                    // Optionally, you could use streak to update the chart, such as adding it as another bar or label
                    // For example, if you want to visualize the streak, you could create a second bar for each friend.
                    // Or use it as another data series in the chart.
                    
                    // You can add another BarChartDataEntry or modify the chart to display streak values.
                    // For simplicity, we’ll print it for now:
                    print("Streak for \(friendUsername): \(streak)")
                    
                    dispatchGroup.leave() // Leave the group after fetching the streak
                }
            } else {
                print("Invalid friend data: \(friend)")
            }
        }
        
        // When all requests have completed, update the chart
        dispatchGroup.notify(queue: .main) {
            // If no friends data or scores, print and return
            if entries.isEmpty {
                print("No friends or scores to display.")
                return
            }
            
            // Set up the data set for scores
            let dataSet = BarChartDataSet(entries: entries, label: "Leaderboard Scores")
            dataSet.colors = ChartColorTemplates.joyful()  // Customize colors

            // Set up the bar chart data
            let data = BarChartData(dataSet: dataSet)
            self.barChartView.data = data

            // Customize the chart appearance
            self.configureChartAppearance(friendNames)
            
            // Add friend names on top of the bars
            self.addFriendNamesOnBars(friendNames)
        }
    }

    
    func fetchFriendPoints(for username: String, completion: @escaping (Int?, String?) -> Void) {
        // Construct the URL with the username appended to the path
        let urlString = "http://127.0.0.1:8000/user/get-points/?username=\(username)"
        
        // Ensure the URL is valid
        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL.")
            return
        }
        
        // Create the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // Since you're fetching data, you likely want to use GET
        
        // Set the Content-Type header to "application/json"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, "Request failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                completion(nil, "No data received.")
                return
            }
            
            do {
                // Attempt to parse the response data into a JSON object
                if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let points = responseJson["points"] as? Int {
                    // Return the score from the response
                    completion(points, nil)
                } else {
                    completion(nil, "Invalid response format.")
                }
            } catch {
                completion(nil, "Failed to parse response data.")
            }
        }
        
        task.resume()
    }


    // Function to configure the chart's appearance (labels, axis, etc.)
    func configureChartAppearance(_ friendNames: [String]) {
        // Set the labels for the x-axis
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: friendNames)
        barChartView.xAxis.granularity = 1
        barChartView.xAxis.labelPosition = .bottom // Ensure labels are at the bottom
        barChartView.xAxis.labelRotationAngle = -45  // Rotate labels to avoid overlap
        barChartView.xAxis.wordWrapEnabled = true // Allow wrapping if space is tight
        barChartView.xAxis.labelCount = friendNames.count // Show all friend names

        // Customize y-axis (scores)
        barChartView.leftAxis.axisMinimum = 0
        barChartView.rightAxis.enabled = false  // Hide the right axis
        barChartView.legend.enabled = true  // Show legend

        // More customization (optional)
        barChartView.animate(yAxisDuration: 1.0)  // Add animation
    }

    
       // Function to add friend names directly on top of the bars using ChartMarker
    func addFriendNamesOnBars(_ friendNames: [String]) {
        // Customizing the marker to show friend names on top of the bars
        let marker = ChartMarker()
        marker.chartView = barChartView
        barChartView.marker = marker

        // Use the index of each bar to set the label for that bar
        for (index, name) in friendNames.enumerated() {
            if let entry = barChartView.data?.dataSets[0].entryForIndex(index) {
                // Dynamically calculate the label's position
                let label = UILabel()
                label.text = name
                label.font = UIFont.systemFont(ofSize: 12)  // Adjust font size to fit the bar
                label.textColor = UIColor.white
                label.sizeToFit()  // Resize the label based on the text
                
                // Calculate position: center the label horizontally over the bar and adjust vertically
                let xPos = CGFloat(entry.x) - (label.frame.size.width / 2)
                let yPos = entry.y + 5  // Adjust 5 units above the bar for better positioning

                // Set label's frame and position
                label.frame = CGRect(x: xPos, y: yPos, width: label.frame.size.width, height: label.frame.size.height)

                // Add the label to the chart view
                barChartView.addSubview(label)
            }
        }
    }


}
