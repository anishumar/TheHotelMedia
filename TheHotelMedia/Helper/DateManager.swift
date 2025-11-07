//
//  DateManager.swift
//  TheHotelMedia
//
//  Created by MAC on 10/10/24.
//

import Foundation
import SwiftUI



class DateManager {
    
    static func getPostedAgoTime(date: String, language: SelectedLanguage = .english) -> String {
        // Create a DateFormatter to parse the ISO 8601 format
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Parse the time string into a Date object
        if let pastDate = formatter.date(from: date) {
            let currentDate = Date() // Get the current time

            // Use Calendar to calculate the difference
            let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: pastDate, to: currentDate)

            if let days = components.day, let hours = components.hour, let minutes = components.minute, let seconds = components.second {
                
                if days != 0 {
                    return days == 1 ? "\(days) " + "day ago".localized(language) : "\(days) " + "days ago".localized(language)
                } else if hours != 0 {
                    return hours == 1 ? "\(hours) " + "hour ago".localized(language) : "\(hours) " + "hours ago".localized(language)
                } else if minutes != 0 {
                    return minutes == 1 ? "\(minutes) " + "min ago".localized(language) : "\(minutes) " + "min ago".localized(language)
                } else if seconds != 0 {
                    return seconds == 1 ? "\(seconds) " + "sec ago".localized(language) : "\(seconds) " + "sec ago".localized(language)
                } else {
                    return "Just now"
                }
            }
            return "Just now"
            
        } else {
            return "Just now"
        }
    }
    
    
    static func isoDateInto24HourFormat(isoDate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Step 2: Parse the string into a Date object
        if let date = isoFormatter.date(from: isoDate) {
            // Step 3: Create a new DateFormatter for the desired output format
            let outputFormatter = DateFormatter()
//            outputFormatter.dateFormat = "hh:mm a" // 12-hour format with AM/PM
             outputFormatter.dateFormat = "HH:mm" // 24-hour format

            let formattedTime = outputFormatter.string(from: date)
            return formattedTime
        } else {
            return "Just Now"
        }
    }
    
    static func dateIntoIsoFormat(date: Date) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Includes milliseconds
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Ensures the output is in UTC

        // Convert Date to ISO8601 string
        let isoDateString = isoFormatter.string(from: date)
        return isoDateString
    }
    
    
    static func checkDateForTodayOrYesterday(to isoDateString: String) -> String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Parse the ISO date string
        guard let date = formatter.date(from: isoDateString) else {
            return nil // Invalid ISO date string
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        
        return nil // Neither today nor yesterday
    }
    
    
    static func formatDate(from isoDateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: isoDateString) else {
            return "Unknown Date" // Invalid ISO date string
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM, yyyy" // Desired format
        
        return outputFormatter.string(from: date)
    }
    
    
    static func isFutureDate(isoDateString: String) -> Bool {
        let dateFormatter = ISO8601DateFormatter()
        
        // Parse the ISO date string
        guard let date = dateFormatter.date(from: isoDateString) else {
            print("Invalid date format")
            return false
        }
        
        // Get the current date
        let currentDate = Date()
        
        // Compare the parsed date with the current date
        return date >= currentDate
    }
    
    
    static func isFutureDate(dateString: String, timeString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone.current // Use local timezone

        // Combine date and time strings into one
        let combinedString = "\(dateString) \(timeString)"
        
        // Parse the combined string into a Date object
        guard let date = dateFormatter.date(from: combinedString) else {
            print("Invalid date or time format")
            return false
        }
        
        // Get the current date and add 30 minutes
        let currentDate = Date()
        let currentDatePlus30Minutes = currentDate.addingTimeInterval(30 * 60)
        
        // Compare the combined date with the adjusted current date
        return date > currentDatePlus30Minutes
    }
    
    
    static func formatStayDates(fromDate: Date, toDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMM"
        
        let fromDateString = dateFormatter.string(from: fromDate)
        let toDateString = dateFormatter.string(from: toDate)
        
        // Calculate the number of nights
        let calendar = Calendar.current
        let newTodate = calendar.date(byAdding: .minute, value: 1, to: toDate)
        let numberOfNights = calendar.dateComponents([.day], from: fromDate, to: newTodate ?? toDate).day ?? 0
        
        // Create the final formatted string
        let formattedString = "\(fromDateString) - \(toDateString) - \(numberOfNights)Night\(numberOfNights > 1 ? "s" : "")"
        
        return formattedString
    }
    
    
    static func formatDateTodMMM(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d, MMM"
        return formatter.string(from: date)
    }
    
    
    static func formatISODateToBookedOn(from isoDate: String) -> String? {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = inputFormatter.date(from: isoDate) else {
            return nil
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d MMM yyyy, h:mma"
        outputFormatter.locale = Locale(identifier: "en_US")
        outputFormatter.timeZone = TimeZone.current  // Convert to local timezone

        return outputFormatter.string(from: date)
    }
    
    
    static func formatISODateToTableBookedOn(_ isoDate: String) -> String? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: isoDate) ??
                         ISO8601DateFormatter().date(from: isoDate) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MMMM d, yyyy | h:mm a" // 👈 changed here

        return formatter.string(from: date)
    }
    
    
    static func formatISODateAsIs(_ isoDate: String) -> String? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: isoDate) ??
                         ISO8601DateFormatter().date(from: isoDate) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // 👈 No timezone change (keep original UTC)
        formatter.dateFormat = "MMMM d, yyyy | h:mm a"

        return formatter.string(from: date)
    }
    
    
    static func formatToFull(from dateString: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        inputFormatter.locale = Locale(identifier: "en_US")
        inputFormatter.timeZone = TimeZone.current  // Assumes local time

        guard let date = inputFormatter.date(from: dateString) else {
            return nil
        }

        let outputFormatter = ISO8601DateFormatter()
        outputFormatter.formatOptions = [.withInternetDateTime]
        outputFormatter.timeZone = TimeZone.current  // Convert to UTC by default

        return outputFormatter.string(from: date)
    }
    
    
    static func convertISOToDateAndMonth(from isoString: String) -> String? {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = inputFormatter.date(from: isoString) else {
            return nil
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d,MMM"  // Desired format "30,Nov"
        outputFormatter.locale = Locale(identifier: "en_US")

        return outputFormatter.string(from: date)
    }

    
    static func formatDateToyyyyMMdd(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    
    static func convertOnlyTimeTo12HourFormat(_ time24: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        guard let date = dateFormatter.date(from: time24) else {
            return nil
        }

        dateFormatter.dateFormat = "hh:mm a"
        return dateFormatter.string(from: date)
    }
    
    
    static func convertDateToddMMMyyyyFormat(date: Date) -> String {
        // Create DateFormatter
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        formatter.locale = Locale.current // Ensure it reflects the device's locale
        formatter.timeZone = TimeZone.current // Ensure it reflects the local time zone
        
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSxxx"
        formatter.dateFormat = "dd MMM, yyyy"
        return formatter.string(from: date)
    }
    
    
    static func mealType(from isoDateString: String) -> String? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: isoDateString) ??
                         ISO8601DateFormatter().date(from: isoDateString) else {
            return nil
        }

        // Create a calendar with UTC time zone to avoid converting to local
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let hour = utcCalendar.component(.hour, from: date)

        switch hour {
        case 8..<11:
            return "Breakfast"
        case 13..<15:
            return "Lunch"
        case 19..<23:
            return "Dinner"
        default:
            return nil
        }
    }
}
