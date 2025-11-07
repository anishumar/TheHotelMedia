//
//  TransactionsView.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct TransactionsView: View {
    
    @StateObject var viewModel: TransactionsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.transactions) { transaction in
                    transactionView(transaction: transaction)
                        .onAppear {
                            if let lastTransaction = viewModel.transactions.last {
                                if lastTransaction.id == transaction.id {
                                    viewModel.pageNumber += 1
                                    viewModel.getTransactions()
                                }
                            }
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 50)
            
        }
        .clipped()
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay {
            VStack {
                if viewModel.transactions.isEmpty && !viewModel.showLoadingIndicator {
                    EmptyScreenView(image: "BillIcon3", title: "no_transactions_done_yet".localized(localizationManager.language))
                }
            }
            .frame(width: UIScreen.main.bounds.width)
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .overlay(
            CustomHeaderView(title: "transactions".localized(localizationManager.language).capitalized) {
                viewModel.dismissScreen()
            }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .background(themeManager.currentTheme.backgroundColor)
            , alignment: .top
        )
    }
}

// MARK: - Preview

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        TransactionsView(viewModel: TransactionsViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Functions
extension TransactionsView {
    func formattedDate(from isoDateString: String) -> (formattedDate: String, formattedTime: String)? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: isoDateString) else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let formattedDate = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "h:mm a"
        let formattedTime = dateFormatter.string(from: date)
        
        return (formattedDate, formattedTime)
    }
}


// MARK: - Components
extension TransactionsView {
    private func transactionView(transaction: SubscriptionTransaction) -> some View {
        HStack {
            WebImage(url: URL(string: transaction.subscriptionPlanRef?.image ?? ""))
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .padding(.leading, 11)
            
            VStack(alignment: .leading) {
                Text(transaction.subscriptionPlanRef?.name ?? "")
                    .font(.custom(Constants.comicFont, size: 16))
                    .foregroundColor(.white)
                
                Text("transactionID".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 12))
                    .foregroundColor(.white)
                
                Text(transaction.orderID ?? "")
                    .font(.custom(Constants.comicFont, size: 12))
                    .foregroundColor(themeManager.currentTheme.hmIndigo05_darkGray08)
            }
            .padding(.leading, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing) {
                if let formattedDate = formattedDate(from: transaction.updatedAt ?? (transaction.createdAt ?? "")) {
                    Text("₹\(String(format: "%.2f", transaction.grandTotal ?? 0))")
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(themeManager.currentTheme.hmIndigo_white)
                    
                    Text(formattedDate.formattedDate)
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundColor(.white)
                    
                    Text(formattedDate.formattedTime)
                        .font(.custom(Constants.comicFont, size: 12))
                        .foregroundColor(themeManager.currentTheme.hmIndigo05_darkGray08)
                }
            }
            .padding(.trailing, 12)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.currentTheme.darkGray05_hmIndigo)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(lineWidth: 1)
                        .fill(themeManager.currentTheme.mediumGray_hmIndigo)
                )
        )
    }

}
