//
//  ChartView.swift
//  HotelMedia
//
//  Created by MAC on 03/09/24.
//

import SwiftUI
import Charts

enum LineChartType: String, CaseIterable, Plottable {
    case reached = "AccountReached"
    case followers = "TotalFollowers"
    case engaged = "Engaged"
    case redirect = "Website Redirection"
    
    var color: Color {
        switch self {
        case .reached:
                .hmOlive
        case .followers:
                .hmPurple
        case .engaged:
                .hmDarkGreen
        case .redirect:
                .hmDarkPink
        }
    }
    
}

struct LineChartData: Identifiable {
    
    var id = UUID().uuidString
    var period: Double
    var value: Double
    
    var type: LineChartType
}

struct ChartView: View {
    
    @StateObject var viewModel: ChartViewModel
    @Binding var chartData: ChartData?
    let weekdayLabels = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Chart {
                    ForEach(viewModel.accountReachedData) { data in
                        LineMark(
                            x: .value("Day", data.period),
                            y: .value("Reach", data.value),
                            series: .value("Reached", "Reached")
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .foregroundStyle(data.type.color)
                        .interpolationMethod(.monotone)
                    }
                    
                    ForEach(viewModel.followersData) { data in
                        LineMark(
                            x: .value("Day", data.period),
                            y: .value("Followers", data.value),
                            series: .value("Followers", "Followers")
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .foregroundStyle(data.type.color)
                        .interpolationMethod(.monotone)
                    }
                    
                    ForEach(viewModel.engagedData) { data in
                        LineMark(
                            x: .value("Day", data.period),
                            y: .value("Enagaged", data.value),
                            series: .value("Engaged", "Engaged")
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .foregroundStyle(data.type.color)
                        .interpolationMethod(.monotone)
                    }
                    
                    ForEach(viewModel.redirectData) { data in
                        LineMark(
                            x: .value("Day", data.period),
                            y: .value("Redirection", data.value),
                            series: .value("Redirection", "Redirection")
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .foregroundStyle(data.type.color)
                        .interpolationMethod(.monotone)
                    }
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
                .padding(.leading, 45)
                .padding(.bottom, 38)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    Rectangle()
                        .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        .frame(width: 1.5)
                        .offset(x: 43)
                        .padding(.bottom, 38)
                        .padding(.top, 10)
                    , alignment: .leading
                )
                .overlay(
                    Rectangle()
                        .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        .frame(height: 1.5)
                        .offset(y: -38)
                        .padding(.leading, 45)
                        .padding(.trailing, 10)
                    , alignment: .bottom
                )
                .overlay(
                    yAxisView
                    , alignment: .topLeading
                )
                .overlay(
                    xAxisView
                    , alignment: .bottomTrailing
                )
                
            }
            .padding(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: getViewHeight())
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.black09_white)
            )
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
            )
            .onChange(of: chartData, perform: { value in
                viewModel.chartData = value
            })
        }
    }
    
    
    func getViewHeight() -> CGFloat {
//        let height = UIScreen.main.bounds.height * 0.35
        let height: CGFloat = 220
        return height
    }
    
    
    func getYAxisMarkHeight() -> CGFloat {
        let viewHeight = getViewHeight()
        let count = viewModel.yAxis.count
        let height = (viewHeight - 48) / CGFloat(count)
        
        return height
    }
        
}

#Preview {
    VStack {
        ChartView(viewModel: ChartViewModel(), chartData: .constant(nil))
    }
    .frame(maxHeight: .infinity)
    .background(.black)
    
}


// MARK: - Components

extension ChartView {
    private var yAxisView: some View {
        VStack(alignment: .trailing) {
            ForEach(viewModel.yAxis, id: \.self) { mark in
                HStack(spacing: 2) {
                    Text(String(mark))
                        .font(.custom(Constants.comicFont, size: 9))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    
                    Rectangle()
                        .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        .frame(width: 12, height: 1.5)
                }
                .padding(.trailing, 1)
                
                if let lastMark = viewModel.yAxis.last, lastMark != mark {
                    Spacer()
                }
            }
            
        }
        .id(viewModel.yAxis)
        .padding(.top, 10)
        .padding(.bottom, 38)
        .frame(width: 45, alignment: .trailing)
    }
    
    
    private var xAxisView: some View {
        HStack(alignment: .top) {
            ForEach(viewModel.xAxis, id: \.self) { mark in
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        .frame(width: 1.5, height: 12)
                    Text(mark)
                        .font(.custom(Constants.comicFont, size: 9))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    
                    
                }
                .padding(.trailing, 1)
                
                if let lastlabel = viewModel.xAxis.last, lastlabel != mark {
                    Spacer()
                }
            }
            
        }
            .padding(.trailing, 10)
            .padding(.leading, 45)
            .frame(height: 38, alignment: .top)
    }
    
}
