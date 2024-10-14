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
    
    var barChartView: BarChartView!
    
    // Add title label
    var titleLabel: UILabel!
    
    // Add button to demonstrate below the chart
    var actionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the title label
        setupTitleLabel()
        
        // Initialize the BarChartView programmatically
        setupBarChartView()

        // Set up the action button
        
        // Call the function to fetch friends and display them on the chart
        fetchFriendsList()
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
    
    // Setup BarChartView programmatically
    func setupBarChartView() {
        // Initialize BarChartView
        barChartView = BarChartView()
        
        // Set the chart view's frame: 60% of screen height
        let chartHeight = self.view.frame.size.height * 0.6
        barChartView.frame = CGRect(x: 0, y: 150, width: self.view.frame.size.width, height: chartHeight)  // Adjust y-position to be below the title
        
        // Add the chart view to the view hierarchy
        self.view.addSubview(barChartView)
        
        // Customize the appearance of the chart
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

           // Iterate through the friends array
           for (index, friend) in friends.enumerated() {
               if let friendData = friend as? [String: Any], let friendUsername = friendData["friend__username"] as? String {
                   let score = Int.random(in: 50...100)  // Random score for demonstration
                   
                   // Debugging: print out the friend data and score
                   print("Friend username: \(friendUsername), Score: \(score)")
                   
                   let entry = BarChartDataEntry(x: Double(index), y: Double(score))
                   entries.append(entry)
                   friendNames.append(friendUsername)
               } else {
                   print("Invalid friend data: \(friend)")
               }
           }

           // If no friends data or scores, print and return
           if entries.isEmpty {
               print("No friends or scores to display.")
               return
           }

           // Set up the data set
           let dataSet = BarChartDataSet(entries: entries, label: "Leaderboard Scores")
           dataSet.colors = ChartColorTemplates.joyful()  // Customize colors

           // Set up the bar chart data
           let data = BarChartData(dataSet: dataSet)
           barChartView.data = data

           // Customize the chart appearance
           configureChartAppearance(friendNames)
           
           // Add friend names on top of the bars
           addFriendNamesOnBars(friendNames)
       }

       // Function to configure the chart's appearance (labels, axis, etc.)
       func configureChartAppearance(_ friendNames: [String]) {
           // Set the labels for the x-axis
           barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: friendNames)
           barChartView.xAxis.granularity = 1
           barChartView.xAxis.labelRotationAngle = -45  // 

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
           
           // Set the text to display the names of friends
           marker.text = friendNames.joined(separator: ", ")
       }



}
