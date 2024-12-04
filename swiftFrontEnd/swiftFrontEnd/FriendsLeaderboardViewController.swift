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
   
    func fetchFriendStreak(friendUsername: String, completion: @escaping (Int?, String?) -> Void) {
        // Update the URL string
        let urlString = "http://127.0.0.1:8000/user/get-streak/?username=\(friendUsername)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL")
            return
        }
        
        // Create the URL session and data task to fetch data
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, "Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                completion(nil, "No data received")
                return
            }
            
            // Parse the JSON response
            do {
                if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let streak = responseJson["streak"] as? Int {
                    
                    // Print the fetched streak value for debugging
                    print("Fetched streak for \(friendUsername): \(streak)")
                    
                    // Return the streak or handle the zero case
                    if streak >= 0 {
                        completion(streak, nil) // If the streak is valid (including 0)
                    } else {
                        completion(0, nil) // If the streak is negative (fall back to 0)
                    }
                } else {
                    completion(nil, "Invalid response format")
                }
            } catch {
                completion(nil, "Failed to parse response data")
            }
        }
        
        task.resume()
    }

    func fetchAllStreaks(friendUsernames: [String]) {
        let dispatchGroup = DispatchGroup()
        var streaks = [String: Int]()
        var errorMessages = [String: String]()
        
        for friendUsername in friendUsernames {
            dispatchGroup.enter()
            
            fetchFriendStreak(friendUsername: friendUsername) { streak, errorMessage in
                if let streak = streak {
                    streaks[friendUsername] = streak
                } else if let errorMessage = errorMessage {
                    errorMessages[friendUsername] = errorMessage
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Now that all the streaks have been fetched, update the UI or chart
            print("Fetched streaks: \(streaks)")
            print("Error messages: \(errorMessages)")
            
            // You can now proceed to update the chart or display the streak values
            self.updateChartWithStreaks(streaks: streaks)
        }
    }



    func updateChartWithStreaks(streaks: [String: Int]) {
        var streakEntries = [BarChartDataEntry]()
        var friendNames = [String]()

        // Populate streakEntries and friendNames
        for (index, friendUsername) in streaks.keys.enumerated() {
            let streak = streaks[friendUsername] ?? 0
            let entry = BarChartDataEntry(x: Double(index), y: Double(streak))
            streakEntries.append(entry)
            friendNames.append(friendUsername)
        }

        if streakEntries.isEmpty {
            print("No streaks to display.")
            return
        }

        // Create the BarChartDataSet for the streaks
        let streakDataSet = BarChartDataSet(entries: streakEntries, label: "Friend Streaks")
        streakDataSet.colors = ChartColorTemplates.pastel()

        // Combine the data into BarChartData
        let combinedData = BarChartData(dataSets: [streakDataSet])
        self.streakChartView.data = combinedData

        // Update the chart appearance
        self.configureStreakChartAppearance(friendNames)
    }



    func updateChartWithStreaks(_ friends: [Any]) {
        var entries = [BarChartDataEntry]()
        var friendNames = [String]()

        // Use DispatchGroup to handle asynchronous updates
        let dispatchGroup = DispatchGroup()

        for (index, friend) in friends.enumerated() {
            if let friendData = friend as? [String: Any], let friendUsername = friendData["friend__username"] as? String {
                
                dispatchGroup.enter() // Enter the dispatch group before updating
                
                // Generate a random streak value between 1 and 10
                let randomStreak = Int.random(in: 1...10)
                
                print("Assigned streak for \(friendUsername): \(randomStreak)")  // Debugging line
                
                let entry = BarChartDataEntry(x: Double(index), y: Double(randomStreak))
                entries.append(entry)
                friendNames.append(friendUsername)
                
                dispatchGroup.leave() // Leave the dispatch group after assigning the streak
            } else {
                print("Invalid friend data: \(friend)")
            }
        }

        // Once all streaks have been assigned
        dispatchGroup.notify(queue: .main) {
            if entries.isEmpty {
                print("No streaks to display.")
                return
            }
            
            // Create a BarChartDataSet for streaks with random values
            let dataSet = BarChartDataSet(entries: entries, label: "Streaks")
            dataSet.colors = ChartColorTemplates.colorful()  // Customize the colors

            let data = BarChartData(dataSet: dataSet)
            self.streakChartView.data = data
            
            // Update the chart appearance after setting the data
            self.configureStreakChartAppearance(friendNames)
        }
    }



    func configureStreakChartAppearance(_ friendNames: [String]) {
        guard !friendNames.isEmpty else {
            print("No friend names available.")
            return
        }

        // Set up x-axis labels (friend names)
        streakChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: friendNames)
        streakChartView.xAxis.labelPosition = .bottom
        streakChartView.xAxis.labelRotationAngle = 0
        streakChartView.xAxis.wordWrapEnabled = true
        streakChartView.xAxis.labelCount = friendNames.count

        // Set up y-axis
        streakChartView.leftAxis.axisMinimum = 0
        streakChartView.rightAxis.enabled = false  // Disable right axis

        // Animate the chart
        streakChartView.animate(yAxisDuration: 1.0)
    }

    
    func setupScrollView() {
        // Initialize the UIScrollView
        scrollView = UIScrollView()
        
        // Set the scroll view's frame to occupy part of the screen
        let scrollViewHeight = self.view.frame.size.height * 0.5 // Scroll view height is 75% of the screen height
        scrollView.frame = CGRect(x: 0, y: 100, width: self.view.frame.size.width, height: scrollViewHeight)
        
        // Add the scroll view to the main view
        self.view.addSubview(scrollView)
        
        // Enable scrolling
        scrollView.isScrollEnabled = true
        
        // Calculate the bottom inset as 1/4 of the screen height
        let bottomInset = self.view.frame.size.height / 4
        
        // Set the content insets to add space at the top and calculated space at the bottom
        scrollView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: bottomInset, right: 0)
        
        // Adjust the content size, making room for the content inside
        scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: scrollViewHeight * 1.5)
        
    
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
    
    
    func fetchAllStreaksAndPoints(friendUsernames: [String]) {
        var streaks = [String: Int]()
        var points = [String: Int]()
        let group = DispatchGroup() // Used to wait for all requests to complete

        for username in friendUsernames {
            // Fetch streaks
            group.enter()
            guard let streaksURL = URL(string: "http://127.0.0.1:8000/user/get-streak/?username=\(username)") else { continue }

            let streaksTask = URLSession.shared.dataTask(with: streaksURL) { data, response, error in
                defer { group.leave() } // Signal completion of this request

                if let error = error {
                    print("Error fetching streaks for \(username): \(error)")
                    return
                }

                guard let data = data else {
                    print("No data received for streaks for \(username).")
                    return
                }

                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let streak = jsonResponse?["streak"] as? Int {
                        streaks[username] = streak
                    }
                } catch {
                    print("Error parsing streaks response for \(username): \(error)")
                }
            }
            streaksTask.resume()

            // Fetch points
            group.enter()
            guard let pointsURL = URL(string: "http://127.0.0.1:8000/user/get-points/?username=\(username)") else { continue }

            let pointsTask = URLSession.shared.dataTask(with: pointsURL) { data, response, error in
                defer { group.leave() } // Signal completion of this request

                if let error = error {
                    print("Error fetching points for \(username): \(error)")
                    return
                }

                guard let data = data else {
                    print("No data received for points for \(username).")
                    return
                }

                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let point = jsonResponse?["points"] as? Int {
                        points[username] = point
                    }
                } catch {
                    print("Error parsing points response for \(username): \(error)")
                }
            }
            pointsTask.resume()
        }

        // Wait for all requests to complete
        group.notify(queue: .main) {
            print("Fetched streaks: \(streaks)")
            print("Fetched points: \(points)")

            // Update the chart with both streaks and points
            self.updateChartWithStreaksAndPoints(streaks: streaks, points: points)
        }
    }

    func updateChartWithStreaksAndPoints(streaks: [String: Int], points: [String: Int]) {
        DispatchQueue.main.async {
            // Prepare entries for points (for barChartView)
            var pointsEntries = [BarChartDataEntry]()
            var usernames = [String]()

            for (index, (username, streak)) in streaks.enumerated() {
                let point = points[username] ?? 0
                pointsEntries.append(BarChartDataEntry(x: Double(index), y: Double(point)))
                usernames.append(username)
            }
            
            // Update the first chart (barChartView) with points data
            let pointsDataSet = BarChartDataSet(entries: pointsEntries, label: "Points")
            pointsDataSet.colors = [UIColor.blue]
            let pointsData = BarChartData(dataSet: pointsDataSet)
            self.barChartView.data = pointsData

            // Set x-axis labels to usernames for points chart
            self.barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: usernames)
            self.barChartView.xAxis.granularity = 1
            self.barChartView.notifyDataSetChanged()

            // Prepare entries for streaks (for streakChartView)
            var streakEntries = [BarChartDataEntry]()

            for (index, (username, streak)) in streaks.enumerated() {
                streakEntries.append(BarChartDataEntry(x: Double(index), y: Double(streak)))
            }
            
            // Update the second chart (streakChartView) with streak data
            let streakDataSet = BarChartDataSet(entries: streakEntries, label: "Streaks")
            streakDataSet.colors = [UIColor.red]
            let streakData = BarChartData(dataSet: streakDataSet)
            self.streakChartView.data = streakData

            // Set x-axis labels to usernames for streak chart
            self.streakChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: usernames)
            self.streakChartView.xAxis.granularity = 1
            self.streakChartView.notifyDataSetChanged()
        }
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
                    let friendUsernames = friends.compactMap { $0["friend__username"] as? String }
                    DispatchQueue.main.async {
                        self.fetchAllStreaksAndPoints(friendUsernames: friendUsernames)
                        
                    }
                } else {
                    print("No 'friends' data available.")
                }
            } catch {
                print("Error parsing response: \(error.localizedDescription)")
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
                
                fetchFriendStreak(friendUsername: friendUsername) { streak, error in
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
        barChartView.xAxis.labelRotationAngle = 0  // Rotate labels to avoid overlap
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
