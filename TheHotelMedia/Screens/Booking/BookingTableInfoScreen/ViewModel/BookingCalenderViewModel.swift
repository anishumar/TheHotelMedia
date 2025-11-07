//
//  BookingCalenderViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 26/03/25.
//

import Foundation
import Combine


class BookingCalenderViewModel: ObservableObject {
    
    
    var calendar = Calendar.current
    var cancellables = Set<AnyCancellable>()
    var calendarType: THMCalendarType = .full
    var currentDay: Int = 0
    var currentMonth: Int = 0
    var currentWeek: Int = 1
    var currentYear: Int = 0
    var selectedDate: DateSelection = DateSelection()
    @Published var day: String = ""
    @Published var month: Int = 3
    @Published var year: Int = 2020
    @Published var monthArray: [Day] = []
    @Published var numberOfWeeks: Int = 0
    @Published var selectedDay: Int? = nil
    @Published var selectedWeek: Int = 1
    @Published var selectedMonth: Int = 1
    @Published var startDate: String = ""
    @Published var endDate: String = ""
    @Published var monthType: MonthType = .current
    // this variable is for current week which is showing on the screen
    // every time user select different calendar type then comes back to week type then the current week would be the actual current ongoing week.
    @Published var currentDayPage: Int = 1
    @Published var scrollCount: Int = 0
    // this variable is for number of week pages i.e, if there are 4 weeks in the month then only one page, if 5 week then two pages.
    @Published var numberOfWeekPage: Int = 1
    // this variable is for current week page i.e, one or two related to the above variable.
    @Published var currentWeekPage: Int = 1
    // this variable is for current month page i.e, one(Jan to June) or two(July to Dec).
    @Published var currentMonthPage: Int = 1
    // this variable is for current selected calendar type on right dropdown.
    @Published var selectedCalendarType: CalendarType = .week
    @Published var leftDropDownOpen: Bool = false
    @Published var rightDropDownOpen: Bool = false
    
    
    // For book table screen dropdown
    @Published var bookTableMnYDropDownOpen: Bool = false
    @Published var selectedMonthList: Bool = true
    @Published var selectedYearList: Bool = false
    
    
    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    let allMonths = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    let allMonthsShortForm = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

    let allWeeks = ["Week 1", "Week 2", "Week 3", "Week 4", "Week 5"]
    let weekDaysShortForm = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    var currentDayCounter = 0
    var numberOfDays = 0
    
    init(calendarType: THMCalendarType = .full) {
        self.calendarType = calendarType
        (currentDay, currentMonth, currentYear) = getCurrentDate()
        month = currentMonth
        year = currentYear
        selectedDate = DateSelection(day: currentDay, month: currentMonth, year: currentYear)
        setAsSelected()
        addSubscribers()
        setAsCurrentYearAndMonth()
        getDayOfWeek(year: currentYear, month: currentMonth, day: 1)
        getCurrentWeek()
        setSelectedWeekAsCurrentWeek()
    }
    
    
    private func addSubscribers() {
        $day
            .sink { [weak self] day in
                guard let self else { return }
                if calendarType == .days {
                    createMonthArrayFull(day: day, month: month, year: year)
                } else {
                    createMonthArray(day: day, month: month, year: year)
                }
            }
            .store(in: &cancellables)
        
//        $month
//            .combineLatest($year)
//            .receive(on: RunLoop.main)
//            .sink { [weak self] (month, year) in
//                guard let self else { return }
//                getDayOfWeek(year: year, month: month, day: 1)
//            }
//            .store(in: &cancellables)
        
        $month
            .receive(on: RunLoop.main)
            .sink { [weak self] month in
                guard let self else { return }
                getDayOfWeek(year: currentYear, month: month, day: 1)
            }
            .store(in: &cancellables)
        
        $numberOfWeeks
            .sink { [weak self] weeks in
                guard let self else { return }
                if weeks <= 4 {
                    self.numberOfWeekPage = 1
                } else {
                    self.numberOfWeekPage = 2
                }
            }
            .store(in: &cancellables)
        
        $selectedCalendarType
            .sink { [weak self] type in
                guard let self else { return }
                if type == .week {
                    setSelectedDateAsCurrentDate()
                    setSelectedWeekAsCurrentWeek()
                    setAsSelected()
                    setAsCurrentYearAndMonth()
                    getDayOfWeek(year: currentYear, month: currentMonth, day: 1)
                    
                    
                } else if type == .month {
                    setSelectedDateAsCurrentDate()
                    setSelectedWeekAsCurrentWeek()
                    setCurrentWeekPage()
                    setAsSelected()
                    setAsCurrentYearAndMonth()
                    getDayOfWeek(year: currentYear, month: currentMonth, day: 1)
                    
                } else if type == .year {
                    setSelectedDateAsCurrentDate()
                    setCurrentMonthPage()
                }
            }
            .store(in: &cancellables)
    }
    
    
    private func getDateString(day: Int, month: Int, year: Int) -> String {
        var dateComponents = DateComponents()
        dateComponents.day = day
        dateComponents.month = month
        dateComponents.year = year
        dateComponents.hour = 0
        dateComponents.minute = 00
        dateComponents.second = 00

        // Create a DateFormatter to format the Date to the desired string
         // +00:00 GMT
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSxxx" // Ensures milliseconds and timezone offset
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Get the current calendar and create a Date object from the components
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        if let date = calendar.date(from: dateComponents) {
            
            // Get the formatted date string
            let dateString = formatter.string(from: date)
                return dateString  // Output: 2024-09-09T07:23:13.000+00:00
        } else {
//
//            let date = Date()
//            let dateString = formatter.string(from: date)
//            return dateString // Output: "2024-09-09T07:23:13.000+00:00"
            return "No date"
        }
        
    }
    
    
    private func configureSingleDateString(day: Int, month: Int, year: Int) {
        startDate = getDateString(day: day, month: month, year: year)
    }
    
    
    func configureSelectedWeekRange() {
    let week = selectedWeek
    var startDay = 0
    var endDay = 0
    
    if week == 1 {
        startDay = monthArray[0].date
        endDay = monthArray[6].date
        
    } else if week == 2 {
        startDay = monthArray[7].date
        endDay = monthArray[13].date
        
    } else if week == 3 {
        startDay = monthArray[14].date
        endDay = monthArray[20].date
        
    } else if week == 4 {
        startDay = monthArray[21].date
        endDay = monthArray[27].date
        
    } else if week == 5 {
        startDay = monthArray[28].date
        endDay = monthArray[34].date
        
    }
    
    configureRangeDateString(
        startDay: startDay,
        startMonth: selectedMonth,
        startYear: year,
        endDay: endDay,
        endMonth: selectedMonth,
        endYear: year
    )
}
    
    
    func configureSelectedDate() {
        guard let selectedDay else { return }
        if selectedWeek > 2 && selectedDay < 10 && selectedMonth == 12 {
            configureSingleDateString(day: selectedDay, month: 1, year: year + 1)
            
        } else if selectedWeek > 2 && selectedDay < 10 {
            configureSingleDateString(day: selectedDay, month: selectedMonth + 1, year: year)
            
        } else {
            configureSingleDateString(day: selectedDay, month: selectedMonth , year: year)
        }
        
        
    }
    
    
    func configureSelectedMonth() {
        configureSingleDateString(day: 1, month: selectedMonth, year: year)
    }
    
    
    private func configureRangeDateString(startDay: Int, startMonth: Int, startYear: Int, endDay: Int, endMonth: Int, endYear: Int) {
        if selectedWeek > 2 && endDay < 10 && endMonth == 12 {
            endDate = getDateString(day: endDay, month: 1, year: endYear + 1)
            
        } else if selectedWeek > 2 && endDay < 10 {
            endDate = getDateString(day: endDay, month: endMonth + 1, year: endYear)
            
        } else {
            endDate = getDateString(day: endDay, month: endMonth, year: endYear)
        }
        
        startDate = getDateString(day: startDay, month: startMonth, year: startYear)
    }
    
    
    private func setAsSelected() {
        selectedDay = currentDay
        selectedMonth = currentMonth
    }
    
    
    func setAsCurrentYearAndMonth() {
        month = currentMonth
        year = currentYear
    }
    
    
    func setCurrentMonthPage() {
        if currentMonth <= 6 {
            currentMonthPage = 1
        } else {
            currentMonthPage = 2
        }
    }
    
    
    func setCurrentWeekPage() {
        if currentWeek <= 4 {
            currentWeekPage = 1
        } else {
            currentWeekPage = 2
        }
        
    }
    
    
    func setSelectedDateAsCurrentDate() {
        selectedDate.day = currentDay
        selectedDate.month = currentMonth
        selectedDate.year = currentYear
    }
    
    
    private func getCurrentWeek() {
        if let index = monthArray.firstIndex(where: { $0.date == currentDay && $0.monthType == .current }) {
            let week = Float(index + 1) / Float(7)
            
            if week <= 1 {
                currentWeek = 1

            } else if week <= 2 {
                currentWeek = 2

            } else if week <= 3 {
                currentWeek = 3
                
            } else if week <= 4 {
                currentWeek = 4
                
            } else if week <= 5 {
                currentWeek = 5
                
            } else if week <= 6 {
                currentWeek = 6
            }
        }
    }
    
    
    func calculateSelectedWeek(indexOfDay: Int) {
        if indexOfDay <= 6 {
            selectedWeek = 1
        } else if indexOfDay <= 13 {
            selectedWeek = 2
        } else if indexOfDay <= 20 {
            selectedWeek = 3
        } else if indexOfDay <= 27 {
            selectedWeek = 4
        } else if indexOfDay <= 34 {
            selectedWeek = 5
        }
    }
    
    
    private func setSelectedWeekAsCurrentWeek() {
        selectedWeek = currentWeek
        currentDayPage = currentWeek
    }
    
    
    private func getCurrentDate() -> (Int, Int, Int){
        let currentDate = Date()

        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        let day = calendar.component(.day, from: currentDate)
        
        return (day, month, year)
    }
    
    
    private func getDayOfWeek(year: Int, month: Int, day: Int) {
        let dateComponents = DateComponents(year: year, month: month, day: day)
        
        if let date = calendar.date(from: dateComponents) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE" // "EEEE" gives the full name of the day
            self.day = dateFormatter.string(from: date)
        } else {
            print("Invalid Date")
        }
        
        
    }
    

    func daysInMonth(month: Int, year: Int) -> Int? {
        guard (1...12).contains(month) else { return nil } // Validate month range
        
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month)
        
        return calendar.range(of: .day, in: .month, for: calendar.date(from: dateComponents)!)?.count
    }

    
    
    private func createMonthArray(day: String, month: Int, year: Int) {
        var array: [Day] = []
     
        if let index = weekdays.firstIndex(of: day) {
            currentDayCounter = index
        }
        
        
        var date = Date()
        date = calendar.date(from: DateComponents(year: year, month: month))!
        
        
        if let range = calendar.range(of: .day, in: .month, for: date) {
            let numberOfDaysInMonth = range.count
            numberOfDays = numberOfDaysInMonth
        } else {
            print("Could not determine the number of days in the current month.")
        }
        
        for i in 0..<numberOfDays {
            array.append(Day(day: weekDaysShortForm[currentDayCounter], date: i + 1))
            if currentDayCounter == 6 {
                currentDayCounter = 0
            } else {
                currentDayCounter += 1
            }
        }
        
        if let indexOfSunday = array.firstIndex(where: {$0.day == "SUN"}) { // index of first Sunday in month array.
            array.remove(atOffsets: IndexSet(0..<indexOfSunday))
        }
        
        if let indexOfLastDay = weekDaysShortForm.firstIndex(where: {$0 == array.last?.day}) {
            let counter = 6 - indexOfLastDay // Number of day in next month to reach saturday.
            var indexOfNextDay = indexOfLastDay + 1 // Next day after the last day in previous month.
            
            
            for i in 0..<counter {
                array.append(Day(day: weekDaysShortForm[indexOfNextDay], date: i + 1, monthType: .next))
                indexOfNextDay += 1
            }
        }
        let count = array.count
        numberOfWeeks = Int(count/7)
        monthArray = array
        
    }
    
    private func createMonthArrayFull(day: String, month: Int, year: Int) {
        var array: [Day] = []
     
        if let index = weekdays.firstIndex(of: day) {
            currentDayCounter = index
        }
        
        
        var date = Date()
        date = calendar.date(from: DateComponents(year: year, month: month))!
        
        
        if let range = calendar.range(of: .day, in: .month, for: date) {
            let numberOfDaysInMonth = range.count
            numberOfDays = numberOfDaysInMonth
        } else {
            print("Could not determine the number of days in the current month.")
        }
        
        for i in 0..<numberOfDays {
            array.append(Day(day: weekDaysShortForm[currentDayCounter], date: i + 1))
            if currentDayCounter == 6 {
                currentDayCounter = 0
            } else {
                currentDayCounter += 1
            }
        }
        
//        if let indexOfSunday = array.firstIndex(where: {$0.day == "SUN"}) { // index of first Sunday in month array.
//            array.remove(atOffsets: IndexSet(0..<indexOfSunday))
//        }
        if let indexOfFirstDay = weekDaysShortForm.firstIndex(where: {$0 == array.first?.day}) {
            if let daysInPreviousMonth = daysInMonth(month: month == 1 ? 12 : month - 1, year: month == 1 ? year - 1 : year) {
                for i in 0..<indexOfFirstDay {
                    array.insert(Day(day: weekDaysShortForm[i], date: daysInPreviousMonth - (indexOfFirstDay - (i + 1)), monthType: .previous, isHidden: false), at: i)
                }
            }
        }
        
        if let indexOfLastDay = weekDaysShortForm.firstIndex(where: {$0 == array.last?.day}) {
            let counter = 6 - indexOfLastDay // Number of day in next month to reach saturday.
            var indexOfNextDay = indexOfLastDay + 1 // Next day after the last day in previous month.
            
            
            for i in 0..<counter {
                array.append(Day(day: weekDaysShortForm[indexOfNextDay], date: i + 1, monthType: .next, isHidden: false))
                indexOfNextDay += 1
            }
        }
        let count = array.count
        numberOfWeeks = Int(count/7)
        monthArray = array
        
    }
}
