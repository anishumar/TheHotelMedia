//
//  TransactionDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 22/10/24.
//

import Foundation


class TransactionDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getTransactions(pageNumber: Int) async throws -> GetTransactionsResponse {
        let resource = Resource<GetTransactionsResponse>(url: .getTransactions, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNumber)")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
