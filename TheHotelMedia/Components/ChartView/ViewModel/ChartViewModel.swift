//
//  ChartViewModel.swift
//  HotelMedia
//
//  Created by MAC on 03/09/24.
//

import SwiftUI
import Combine


class ChartViewModel: ObservableObject {
    
    @Published var chartData: ChartData? = nil
    var cancellables = Set<AnyCancellable>()
    @Published var accountReachedData: [LineChartData] = (0...6).map {
        LineChartData(period: Double($0), value: Double.random(in: 0...0), type: .reached)
    }

    @Published var followersData: [LineChartData] = (0...6).map {
        LineChartData(period: Double($0), value: Double.random(in: 0...0), type: .followers)
    }

    @Published var engagedData: [LineChartData] = (0...6).map {
        LineChartData(period: Double($0), value: Double.random(in: 0...0), type: .engaged)
    }

    @Published var redirectData: [LineChartData] = (0...6).map {
        LineChartData(period: Double($0), value: Double.random(in: 0...0), type: .redirect)
    }
    
    @Published var yAxis: [Int] = []
    
    @Published var xAxis: [String] = [
        "Sun",
        "Mon",
        "Tue",
        "Wed",
        "Thu",
        "Fri",
        "Sat",
    ]
    
    @Published var showReachDetail: Bool = true
    @Published var showFollowersDetail: Bool = true
    @Published var showRedirectDetail: Bool = true
    @Published var showEngagedDetail: Bool = true
    
    init() {
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $chartData
            .sink { [weak self] data in
                guard let self else { return }
                guard let data else { return }
                
                if let accountReached = data.accountReached,
                   let websiteRedirection = data.websiteRedirection,
                   let totalFollowers = data.totalFollowers {
                    
                    self.accountReachedData = updateAccountReachData(dataArray: accountReached)
                    self.redirectData = updateWebsiteRedirectionData(dataArray: websiteRedirection)
                    self.followersData = updateTotalFollowersData(dataArray: totalFollowers)
                    
                    var yAxisInt: [Int] = []
                    
                    var accountReachValueArray: [Double] = []
                    var followersValueArray: [Double] = []
                    var redirectValueArray: [Double] = []
                    
                    for item in accountReachedData {
                        accountReachValueArray.append(item.value)
                    }
                    
                    for item in followersData {
                        followersValueArray.append(item.value)
                    }
                    
                    for item in redirectData {
                        redirectValueArray.append(item.value)
                    }
                    
                    let accountReachMax = accountReachValueArray.max() ?? 0
                    let followersMax = followersValueArray.max() ?? 0
                    let redirectMax = redirectValueArray.max() ?? 0
                    
                    let max = max(accountReachMax, followersMax, redirectMax)
                    yAxisInt.append(Int(max))
                    
                    let accountReachMin = accountReachValueArray.min() ?? 0
                    let followersMin = followersValueArray.min() ?? 0
                    let redirectMin = redirectValueArray.min() ?? 0
                    
                    let min = min(accountReachMin, followersMin, redirectMin)
                    yAxisInt.append(Int(min))
                    
                    if yAxisInt.count == 2, yAxisInt[0] - yAxisInt[1] > 5 {
                        let midValue = Double(yAxisInt[0] + yAxisInt[1]) / 2
                        let result = Int(ceil(midValue))
                        yAxisInt.insert(result, at: 1)
                        
                        let midValue2 = Double(yAxisInt[0] + yAxisInt[1]) / 2
                        let result2 = Int(ceil(midValue2))
                        yAxisInt.insert(result2, at: 1)
                        
                        let midvalue3 = Double(yAxisInt[2] + yAxisInt[3]) / 2
                        let result3 = Int(ceil(midvalue3))
                        yAxisInt.insert(result3, at: 3)
                        
                    } else if yAxisInt.count == 2 {
                        let count = yAxisInt[0] - yAxisInt[1]
                        
                        let max = yAxisInt[0]
                        for i in 1..<count {
                            yAxisInt.insert(max - i, at: i)
                        }
                    }
                    
                    self.yAxis = yAxisInt
                    
                    var xAxis: [String] = []
                    
                    if accountReached.count > 27 {
                        xAxis.append(accountReached[0].labelName ?? "")
                        
                        for i in 1..<5 {
                            xAxis.append(accountReached[(i * 6) - 1].labelName ?? "")
                        }
                        
                        if let lastLabel = accountReached.last?.labelName {
                            xAxis.append(lastLabel)
                        }
                    } else {
                        for item in accountReached {
                            xAxis.append(item.labelName ?? "")
                        }
                    }
                    
                    
                    self.xAxis = xAxis
                }
                
            }
            .store(in: &cancellables)
    }
    
    
    func updateAccountReachData(dataArray: [AccountReached]) -> [LineChartData] {
        var array: [LineChartData] = []
        
        for (index, item) in dataArray.enumerated() {
            array.append(LineChartData(period: Double(index), value: Double(item.accountReach ?? 0), type: .reached))
        }
        
        return array
    }
    
    
    func updateTotalFollowersData(dataArray: [TotalFollower]) -> [LineChartData] {
        var array: [LineChartData] = []
        
        for (index, item) in dataArray.enumerated() {
            array.append(LineChartData(period: Double(index), value: Double(item.followers ?? 0), type: .followers))
        }
        
        return array
    }
    
    
    func updateWebsiteRedirectionData(dataArray: [WebsiteRedirection]) -> [LineChartData] {
        var array: [LineChartData] = []
        
        for (index, item) in dataArray.enumerated() {
            array.append(LineChartData(period: Double(index), value: Double(item.redirection ?? 0), type: .redirect))
        }
        
        return array
    }
}
