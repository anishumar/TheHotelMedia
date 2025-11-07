//
//  InsightCalendarView.swift
//  HotelMedia
//
//  Created by MAC on 21/08/24.
//

import SwiftUI

enum CalendarType: String {
    case week
    case month
    case year
}

enum Month: String {
    case january
    case february
    case march
    case april
    case may
    case june
    case july
    case august
    case september
    case october
    case november
    case december
    
    var intValue: Int {
        switch self {
        case .january:
            1
        case .february:
            2
        case .march:
            3
        case .april:
            4
        case .may:
            5
        case .june:
            6
        case .july:
            7
        case .august:
            8
        case .september:
            9
        case .october:
            10
        case .november:
            11
        case .december:
            12
        
        }
    }
}

enum Week: String {
    case week1 = "Week 1"
    case week2 = "Week 2"
    case week3 = "Week 3"
    case week4 = "Week 4"
    case week5 = "Week 5"
    case week6 = "Week 6"
    
    var intValue: Int {
        switch self {
        case .week1:
            return 1
        case .week2:
            return 2
        case .week3:
            return 3
        case .week4:
            return 4
        case .week5:
            return 5
        case .week6:
            return 6
        }
    }
}

struct InsightCalendarView: View {
    
    let dayGridRows: [GridItem] = [
        GridItem(.flexible(), spacing: 11)
    ]
    
    let weekGridRow: [GridItem] = [
        GridItem(.flexible())
    ]
    
    let monthGridRow: [GridItem] = [
        GridItem(.flexible())
    ]
    let width = UIScreen.main.bounds.width
    
    @ObservedObject var viewModel: InsightCalendarViewModel
//    @Binding var startDate: String
//    @Binding var endDate: String
    @Binding var calendarType: CalendarType
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        
        VStack {
            if viewModel.calendarType == .full {
                HStack {
                    topLeadingButton
                    topTrailingButton
                    
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if viewModel.calendarType == .days {
                HStack(alignment: .bottom) {
                    Text("Date")
                        .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                    Spacer()
                    
                    HStack {
                        Group {
                            Text(viewModel.allMonthsShortForm[viewModel.month - 1].capitalized)
                                .withComicFont(12, color: themeManager.currentTheme.label)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.currentTheme.label)
                                .rotationEffect(Angle(degrees: viewModel.bookTableMnYDropDownOpen && viewModel.selectedMonthList ? 180 : 0))
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                if viewModel.bookTableMnYDropDownOpen {
                                    if viewModel.selectedMonthList {
                                        viewModel.bookTableMnYDropDownOpen = false
                                    } else {
                                        viewModel.bookTableMnYDropDownOpen = false
                                        viewModel.selectedYearList = false
                                        viewModel.selectedMonthList = true
                                        viewModel.bookTableMnYDropDownOpen = true
                                    }
                                } else {
                                    viewModel.selectedYearList = false
                                    viewModel.selectedMonthList = true
                                    viewModel.bookTableMnYDropDownOpen = true
                                }
                            }
                        }
                        
                        Rectangle()
                            .fill(themeManager.currentTheme.white06_darkGray06)
                            .frame(width: 1, height: 12)
                        
                        Group {
                            Text("\(viewModel.year)".replacingOccurrences(of: ",", with: ""))
                                .withComicFont(12, color: themeManager.currentTheme.label)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.currentTheme.label)
                                .rotationEffect(Angle(degrees: viewModel.bookTableMnYDropDownOpen && viewModel.selectedYearList ? 180 : 0))
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                if viewModel.bookTableMnYDropDownOpen {
                                    if viewModel.selectedYearList {
                                        viewModel.bookTableMnYDropDownOpen = false
                                    } else {
                                        viewModel.bookTableMnYDropDownOpen = false
                                        viewModel.selectedMonthList = false
                                        viewModel.selectedYearList = true
                                        viewModel.bookTableMnYDropDownOpen = true
                                    }
                                } else {
                                    viewModel.selectedMonthList = false
                                    viewModel.selectedYearList = true
                                    viewModel.bookTableMnYDropDownOpen = true
                                }
                            }
                        }
                        
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(themeManager.currentTheme.darkGray05_white)
                            Capsule()
                                .stroke(lineWidth: 1)
                                .fill(themeManager.currentTheme.mediumGray_mediumGray03)
                        }
                    )
                }
                
            }
            
            calendarView
                .overlay(
                    calendarTypeDropDownView
                    , alignment: .topTrailing
                )
                .overlay(
                    rightOptionDropDown
                    , alignment: .topLeading
                )
                .overlay(
                    rightOptionDropDown2
                    , alignment: .topTrailing
                )
                .zIndex(1.0)
                .onReceive(viewModel.$selectedCalendarType) { value in
                    calendarType = value
                    if value == .week {
                        viewModel.configureSelectedDate()
                    } else if value == .month {
                        viewModel.configureSelectedWeekRange()
                    } else if value == .year {
                        viewModel.configureSelectedMonth()
                    }
                }
//                .onReceive(viewModel.$startDate) { value in
//                    startDate = value
//                }
//                .onReceive(viewModel.$endDate) { value in
//                    endDate = value
//                }
            
            
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    InsightCalendarView(viewModel: InsightCalendarViewModel(), calendarType: .constant(.week))
}


// MARK: - Functions

extension InsightCalendarView {
    private func getWidthForDayButton() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let remainingWidth = screenWidth - 24 - 16 - 66
        let width = remainingWidth/7
        
        return width
    }
    
    
    private func getSpacingForDayGrid() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let remainingWidth = screenWidth - 24 - 16 - (39.5 * 7)
        let spacing = remainingWidth/6
        
        return spacing
    }
    
    
    private func getSpacingForMonthGrid() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let remainingWidth = screenWidth - 24 - 16 - (39.5 * 6)
        let spacing = remainingWidth/5
        
        return spacing
    }
    
    private func getSpacingForWeekGrid() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let remainingWidth = screenWidth - 24 - 16 - (82 * 4)
        let spacing = remainingWidth/3
        
        return spacing
    }
    
    private func getWidthForWeekButton() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let remainingWidth = screenWidth - 24 - 16 - 18
        let width = remainingWidth/4
        
        return width
    }
    
    
    private func getWidthForMonthButton() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let remainingWidth = screenWidth - 24 - 16 - 100
        let width = remainingWidth/6
        
        return width
    }
    
}


// MARK: - Components

extension InsightCalendarView {
    private var topLeadingButton: some View {
        HStack(spacing: 4) {
            if viewModel.selectedCalendarType == .week {
                Text("Week \(viewModel.currentDayPage)")
                    
            } else if viewModel.selectedCalendarType == .month {
                Text(viewModel.allMonths[viewModel.month - 1])
                    
            } else if viewModel.selectedCalendarType == .year {
                Text(String(viewModel.year))
                   
            }
            
            Image(systemName: "chevron.down")
                .fontWeight(.bold)
                
        }
        .font(.custom(Constants.comicFont, size: 12))
        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        .frame(height: 30)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                Capsule()
                    .fill(themeManager.currentTheme.darkGray06_white06)
                Capsule()
                    .stroke(lineWidth: 1.2)
                    .fill(.hmDarkerGray.opacity(0.8))
            }
        )
        .onTapGesture {
            haptics(.light)
            viewModel.leftDropDownOpen.toggle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var topTrailingButton: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.darkGray06_white06)
            Circle()
                .stroke(lineWidth: 1.2)
                .fill(.hmDarkerGray)
            Image("ArrowIcon")
                .resizable()
                .renderingMode(.template)
                .font(.system(size: 18))
                .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                .scaledToFit()
                .frame(width: 16, height: 16)
        }
        .frame(width: 32, height: 32)
        .onTapGesture {
            haptics(.light)
            viewModel.rightDropDownOpen.toggle()
        }
    }
    
    
    private func daysGridView(week: Int) -> some View {
        
        LazyHGrid(rows: dayGridRows, alignment: .center, spacing: getSpacingForDayGrid()) {
            
            if week == 1 {
                ForEach(viewModel.monthArray[0...6]) { day in
                    dayButton(day: day)
                }
            } else if week == 2 {
                ForEach(viewModel.monthArray[7...13]) { day in
                    dayButton(day: day)
                }
            } else if week == 3 {
                ForEach(viewModel.monthArray[14...20]) { day in
                    dayButton(day: day)
                }
            } else if week == 4 {
                ForEach(viewModel.monthArray[21...27]) { day in
                    dayButton(day: day)
                }
            } else if week == 5 {
                ForEach(viewModel.monthArray[28...34]) { day in
                    dayButton(day: day)
                }
            } else if week == 6 {
                ForEach(viewModel.monthArray[35...41]) { day in
                    dayButton(day: day)
                }
            }
            
        }
        .frame(maxWidth: .infinity)
    }
    
    
    private func weekGridView(page: Int) -> some View {
        LazyHGrid(rows: weekGridRow, spacing: getSpacingForWeekGrid()) {
            if page == 1{
                ForEach(1..<5) { week in
                    weekButton(week: week)
                }
            } else if page == 2 {
                weekButton(week: 5)
            }
        }
        .frame(width: UIScreen.main.bounds.width - 32 - 12, alignment: .leading)
    }
    
    
    private func monthGridView(page: Int) -> some View {
        LazyHGrid(rows: monthGridRow, spacing: getSpacingForMonthGrid()) {
            if page == 1 {
                monthButton(month: .january)
                monthButton(month: .february)
                monthButton(month: .march)
                monthButton(month: .april)
                monthButton(month: .may)
                monthButton(month: .june)
            } else if page == 2 {
                monthButton(month: .july)
                monthButton(month: .august)
                monthButton(month: .september)
                monthButton(month: .october)
                monthButton(month: .november)
                monthButton(month: .december)
            }
        }
    }
    
    
    private func dayButton(day: Day) -> some View {
        VStack {
            Text(day.day)
            Circle()
                .stroke(lineWidth: 1)
                .frame(width: 23)
                .overlay(content: {
                    VStack {
                        if viewModel.selectedDay == day.date && viewModel.monthType == day.monthType {
                            Circle()
                                .fill(.white)
                        }
                    }
                })
                .overlay(
                    Text("\(day.date)")
                        .foregroundColor(viewModel.selectedDay == day.date && viewModel.monthType == day.monthType ? .hmIndigo : themeManager.currentTheme.white06_darkGray06)
                )
        }
        .font(.custom(Constants.comicFont, size: 10.25))
//        .foregroundColor(.white.opacity(viewModel.selectedDay == day.date ? 1.0 : 0.5))
        .foregroundColor(viewModel.selectedDay == day.date && viewModel.monthType == day.monthType ? .white : themeManager.currentTheme.white06_darkGray06)
        .padding(.vertical, 8)
        .frame(width: 39.5)
        .background(
            Capsule()
                .stroke(lineWidth: 1.2)
                .fill(.hmDarkerGray.opacity(0.3))
        )
        .background(
            Capsule()
                .fill(viewModel.selectedDay == day.date && viewModel.monthType == day.monthType ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.darkGray06_white06)
        )
        .onTapGesture {
            haptics(.light)
            viewModel.selectedDay = day.date
            viewModel.monthType = day.monthType
            if let index = viewModel.monthArray.firstIndex(where: { $0.id == day.id}) {
                viewModel.calculateSelectedWeek(indexOfDay: index)
            }
            viewModel.configureSelectedDate()
        }
//        .opacity(day.isNextMonthDay ? 0.0 : 1.0)
    }
    
    
    private func monthButton(month: Month) -> some View {
        VStack {
            Text(viewModel.allMonthsShortForm[month.intValue - 1])
            Circle()
                .stroke(lineWidth: 1)
                .frame(width: 23)
                .overlay(
                    ZStack {
                        if viewModel.selectedMonth == month.intValue &&
                            viewModel.selectedDate.year == viewModel.year {
                            Circle()
                                .fill(.white)
                                .frame(width: 23)
                        }
                        
                        if month.intValue < 10 {
                            Text("\(0)\(month.intValue)")
                        } else {
                            Text("\(month.intValue)")
                        }
                    }
                    .foregroundColor( viewModel.selectedMonth == month.intValue &&
                                          viewModel.selectedDate.year == viewModel.year ? .hmIndigo : themeManager.currentTheme.white06_darkGray06)
                )
        }
        .font(.custom(Constants.comicFont, size: 10.25))
        .foregroundColor(viewModel.selectedMonth == month.intValue &&
                         viewModel.selectedDate.year == viewModel.year ? .white : themeManager.currentTheme.white06_darkGray06)
        .padding(.vertical, 8)
        .frame(width: 39.5)
        .background(
            Capsule()
                .stroke(lineWidth: 1.2)
                .fill(.hmDarkerGray.opacity(0.3))
        )
        .background(
            Capsule()
                .fill( viewModel.selectedMonth == month.intValue &&
                       viewModel.selectedDate.year == viewModel.year ?
                       themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.darkGray06_white06)
        )
        .onTapGesture {
            haptics(.light)
            viewModel.selectedMonth = month.intValue
            viewModel.selectedDate.year = viewModel.year
            viewModel.configureSelectedMonth()
        }
    }
    
    
    private func weekButton(week: Int) -> some View {
        VStack {
            Text("Week \(week)")
                .font(.custom(Constants.comicFont, size: 10.25))
                .foregroundColor(viewModel.selectedWeek == week &&
                                 viewModel.selectedDate.month == viewModel.month
                                 ? .white : themeManager.currentTheme.white06_darkGray06)
            
            HStack(spacing: 3) {
                if week == 1 {
                    Text("\(0)\(viewModel.monthArray[0].date)")
                } else if week == 2 {
                    if viewModel.monthArray[7].date < 10 {
                        Text("\(0)\(viewModel.monthArray[7].date)")
                    } else {
                        Text("\(viewModel.monthArray[7].date)")
                    }
                } else if week == 3 {
                    Text("\(viewModel.monthArray[14].date)")
                } else if week == 4 {
                    Text("\(viewModel.monthArray[21].date)")
                } else if week == 5 {
                    Text("\(viewModel.monthArray[28].date)")
                }
                
                Text("-")
                
                if week == 1 {
                    if viewModel.monthArray[6].date < 10 {
                        Text("\(0)\(viewModel.monthArray[6].date)")
                    } else {
                        Text("\(viewModel.monthArray[6].date)")
                    }
                } else if week == 2 {
                    Text("\(viewModel.monthArray[13].date)")
                } else if week == 3 {
                    Text("\(viewModel.monthArray[20].date)")
                } else if week == 4{
                    if viewModel.monthArray[27].date < 10 {
                        Text("\(0)\(viewModel.monthArray[27].date)")
                    } else {
                        Text("\(viewModel.monthArray[27].date)")
                    }
                } else if week == 5{
                    if viewModel.monthArray[34].date < 10 {
                        Text("\(0)\(viewModel.monthArray[34].date)")
                    } else {
                        Text("\(viewModel.monthArray[34].date)")
                    }
                }
            }
            .font(.custom(Constants.comicFont, size: 10.25))
            .foregroundColor(viewModel.selectedWeek == week &&
                             viewModel.selectedDate.month == viewModel.month
                             ? .hmIndigo : themeManager.currentTheme.white06_darkGray06)
            .padding(.horizontal, 8)
            .frame(height: 23)
            .background(
                ZStack {
                    Capsule()
                        .stroke(lineWidth: 1)
                        .foregroundColor(.hmDarkerGray)
                    
                    if viewModel.selectedWeek == week &&
                        viewModel.selectedDate.month == viewModel.month {
                        Capsule()
                            .fill(.white)
                    }
                }
            )
            .onTapGesture {
                haptics(.light)
                viewModel.selectedWeek = week
                viewModel.selectedMonth = viewModel.month
                viewModel.selectedDate.month = viewModel.month
                viewModel.configureSelectedWeekRange()
            }
        }
        .padding(.vertical, 8)
        .frame(width: 82)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(viewModel.selectedWeek == week &&
                          viewModel.selectedDate.month == viewModel.month
                          ? themeManager.currentTheme.hmIndigo_hmIndigo05 : themeManager.currentTheme.darkGray06_white06)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1.2)
                    .fill(.hmDarkerGray.opacity(0.3))
            }
            
        )
    }
    
    
    private var calendarView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.currentTheme.darkGray06_darkGray008)
            
            if viewModel.selectedCalendarType == .week {
                if viewModel.numberOfWeeks == 4 {
                    TabView(selection: $viewModel.currentDayPage) {
                        ForEach(0..<4) { week in
                            daysGridView(week: week + 1)
                                .tag(week + 1)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                } else if viewModel.numberOfWeeks == 5 {
                    TabView(selection: $viewModel.currentDayPage) {
                        ForEach(0..<5) { week in
                            daysGridView(week: week + 1)
                                .tag(week + 1)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                } else if viewModel.numberOfWeeks == 6 {
                    TabView(selection: $viewModel.currentDayPage) {
                        ForEach(0..<6) { week in
                            daysGridView(week: week + 1)
                                .tag(week + 1)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                
            }
            
            
            if viewModel.selectedCalendarType == .month {
                if viewModel.numberOfWeekPage == 1 {
                    weekGridView(page: 1)
                } else {
                    TabView(selection: $viewModel.currentWeekPage) {
                        weekGridView(page: 1)
                            .tag(1)
                        weekGridView(page: 2)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            
            if viewModel.selectedCalendarType == .year {
                TabView(selection: $viewModel.currentMonthPage) {
                    monthGridView(page: 1)
                        .tag(1)
                    monthGridView(page: 2)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            
            
        }
        .frame(height: 76)
        .background(
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                
        )
    }
    
    
    private func calendarTypeButton(type: CalendarType) -> some View {
        Capsule()
            .fill(viewModel.selectedCalendarType == type ? themeManager.currentTheme.hmIndigo05_white : themeManager.currentTheme.darkGray06_white06)
            .frame(width: 66, height: 26)
            .overlay(
                Text(type.rawValue.capitalized)
                    .font(.custom(Constants.comicFont, size: 10.25))
                    .foregroundColor(themeManager.currentTheme.label)
            )
            .overlay(
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(viewModel.selectedCalendarType == type ? .hmIndigo.opacity(0.5) : .white.opacity(0.3))
            )
            .onTapGesture {
                haptics(.light)
                viewModel.selectedCalendarType = type
                viewModel.rightDropDownOpen.toggle()
            }
    }
    
    
    private func monthTypeButton(type: Month) -> some View {
        Capsule()
            .fill(viewModel.month == type.intValue ? themeManager.currentTheme.hmIndigo05_white : themeManager.currentTheme.darkGray06_white06)
            .frame(width: 76, height: 26)
            .overlay(
                Text(type.rawValue.capitalized)
                    .font(.custom(Constants.comicFont, size: 10.25))
                    .foregroundColor(themeManager.currentTheme.label)
            )
            .overlay(
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(viewModel.month == type.intValue ? .hmIndigo.opacity(0.5) : .white.opacity(0.3))
            )
            .onTapGesture {
                haptics(.light)
                viewModel.month = type.intValue
                
                if viewModel.calendarType == .full {
                    viewModel.leftDropDownOpen.toggle()
                }
            }
    }
    
    
    private func yearTypeButton(year: Int) -> some View {
        Capsule()
            .fill(viewModel.year == year ? themeManager.currentTheme.hmIndigo05_white : themeManager.currentTheme.darkGray06_white06)
            .frame(width: 76, height: 26)
            .overlay(
                Text(String(year))
                    .font(.custom(Constants.comicFont, size: 10.25))
                    .foregroundColor(themeManager.currentTheme.label)
            )
            .overlay(
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(viewModel.year == year ? .hmIndigo.opacity(0.5) : .white.opacity(0.3))
            )
            .onTapGesture {
                haptics(.light)
                viewModel.year = year
                if viewModel.calendarType == .full {
                    viewModel.leftDropDownOpen.toggle()
                }
            }
    }
    
    
    private func weekTypeButton(type: Week) -> some View {
        Capsule()
            .fill(viewModel.currentDayPage == type.intValue ? themeManager.currentTheme.hmIndigo05_white : themeManager.currentTheme.darkGray06_white06)
            .frame(width: 76, height: 26)
            .overlay(
                Text(type.rawValue.capitalized)
                    .font(.custom(Constants.comicFont, size: 10.25))
                    .foregroundColor(themeManager.currentTheme.label)
            )
            .overlay(
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(viewModel.currentDayPage == type.intValue ? .hmIndigo.opacity(0.5) : .white.opacity(0.3))
            )
            .onTapGesture {
                haptics(.light)
                viewModel.currentDayPage = type.intValue
                viewModel.leftDropDownOpen.toggle()
            }
    }
    
    
    private var calendarTypeDropDownView: some View {
        ZStack {
            VStack(spacing: 6) {
                calendarTypeButton(type: .week)
                calendarTypeButton(type: .month)
                calendarTypeButton(type: .year)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray_hmIndigo09)
//                    .fill(.ultraThinMaterial)
//                    .preferredColorScheme(.dark)
            )
            
        }
        .scaleEffect(y: viewModel.rightDropDownOpen ? 1 : 0)
    }
    
    
    private var rightOptionDropDown: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                if viewModel.selectedCalendarType == .week {
                    weekTypeSection
                }
                
                if viewModel.selectedCalendarType == .month {
                    monthTypeSection
                }
                
                if viewModel.selectedCalendarType == .year {
                    yearTypeSection
                }
                
            }
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray_hmIndigo09)
//                    .fill(.ultraThinMaterial)
//                    .preferredColorScheme(.dark)
            )
            
        }
        .scaleEffect(y: viewModel.leftDropDownOpen ? 1 : 0)
    }
    
    
    private var rightOptionDropDown2: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                if viewModel.selectedMonthList {
                    monthTypeSection
                } else if viewModel.selectedYearList {
                    yearTypeSection
                }
                
            }
            .frame(height: viewModel.bookTableMnYDropDownOpen ? 110 : 0, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray_hmIndigo09)
//                    .fill(.ultraThinMaterial)
//                    .preferredColorScheme(.dark)
            )
            
        }
//        .scaleEffect(y: viewModel.bookTableMnYDropDownOpen ? 1 : 0, anchor: .top)
    }
    
    
    private var monthTypeSection: some View {
        VStack(spacing: 6) {
            monthTypeButton(type: .january)
            monthTypeButton(type: .february)
            monthTypeButton(type: .march)
            monthTypeButton(type: .april)
            monthTypeButton(type: .may)
            monthTypeButton(type: .june)
            monthTypeButton(type: .july)
            monthTypeButton(type: .august)
            monthTypeButton(type: .september)
            monthTypeButton(type: .october)
            monthTypeButton(type: .november)
            monthTypeButton(type: .december)
        }
        .padding(10)
    }
    
    
    private var weekTypeSection: some View {
        VStack(spacing: 6) {
            weekTypeButton(type: .week1)
            weekTypeButton(type: .week2)
            weekTypeButton(type: .week3)
            weekTypeButton(type: .week4)
            if viewModel.numberOfWeeks == 5 {
                weekTypeButton(type: .week5)
            }
            if viewModel.numberOfWeeks == 6 {
                weekTypeButton(type: .week6)
            }
        }
        .padding(10)
    }
    
    
    private var yearTypeSection: some View {
        VStack(spacing: 6) {
            yearTypeButton(year: 2026)
            yearTypeButton(year: 2025)
            yearTypeButton(year: 2024)
            yearTypeButton(year: 2023)
            yearTypeButton(year: 2022)
            yearTypeButton(year: 2021)
            yearTypeButton(year: 2020)
        }
        .padding(10)
    }
    
}
