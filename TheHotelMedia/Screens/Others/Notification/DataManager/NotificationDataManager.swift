//
//  NotificationDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 23/10/24.
//

import Foundation


class NotificationDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getNotifications(pageNo: Int) async throws -> GetNotificationResponse {
        print("🟡 [API] [GET NOTIFICATIONS] ========================================")
        print("🟡 [API] [GET NOTIFICATIONS] Preparing get notifications API call")
        print("🟡 [API] [GET NOTIFICATIONS] URL: \(URL.getNotifications.absoluteString)")
        print("🟡 [API] [GET NOTIFICATIONS] Method: GET")
        print("🟡 [API] [GET NOTIFICATIONS] PageNo: \(pageNo)")
        
        let resource = Resource<GetNotificationResponse>(url: .getNotifications, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)")]))
        
        print("🟡 [API] [GET NOTIFICATIONS] Making API request...")
        
        do {
            let result = try await baseNetworkManager.accessLoad(resource)
            
            print("🟡 [API] [GET NOTIFICATIONS] ✅ API Response received successfully")
            print("🟡 [API] [GET NOTIFICATIONS] Response Status: \(result.status)")
            print("🟡 [API] [GET NOTIFICATIONS] Response StatusCode: \(result.statusCode)")
            print("🟡 [API] [GET NOTIFICATIONS] Response Message: \(result.message)")
            print("🟡 [API] [GET NOTIFICATIONS] Notifications count: \(result.data?.count ?? 0)")
            print("🟡 [API] [GET NOTIFICATIONS] PageNo: \(result.pageNo ?? 0)")
            print("🟡 [API] [GET NOTIFICATIONS] TotalPages: \(result.totalPages ?? 0)")
            
            // Log each notification's details
            if let notifications = result.data {
                print("🟡 [API] [GET NOTIFICATIONS] Logging all notifications:")
                for (index, notification) in notifications.enumerated() {
                    print("🟡 [API] [GET NOTIFICATIONS]   Notification \(index + 1):")
                    print("🟡 [API] [GET NOTIFICATIONS]     ID: \(notification.id ?? "N/A")")
                    print("🟡 [API] [GET NOTIFICATIONS]     Type: '\(notification.type ?? "N/A")'")
                    print("🟡 [API] [GET NOTIFICATIONS]     Title: '\(notification.title ?? "N/A")'")
                    print("🟡 [API] [GET NOTIFICATIONS]     Description: '\(notification.description ?? "N/A")'")
                    print("🟡 [API] [GET NOTIFICATIONS]     UserID: \(notification.userID ?? "N/A")")
                    if let metadata = notification.metadata {
                        print("🟡 [API] [GET NOTIFICATIONS]     Metadata.postID: \(metadata.postID ?? "N/A")")
                        print("🟡 [API] [GET NOTIFICATIONS]     Metadata.type: '\(metadata.type ?? "N/A")'")
                        print("🟡 [API] [GET NOTIFICATIONS]     Metadata.userID: \(metadata.userID ?? "N/A")")
                    }
                    print("🟡 [API] [GET NOTIFICATIONS]     IsCollaborationInvite: \(notification.isCollaborationInvite)")
                    print("🟡 [API] [GET NOTIFICATIONS]     CollaborationStatus: \(notification.collaborationStatus)")
                }
            }
            
            print("🟡 [API] [GET NOTIFICATIONS] ========================================")
            
            return result
        } catch {
            print("🔴 [API] [GET NOTIFICATIONS] ❌ API Request failed!")
            print("🔴 [API] [GET NOTIFICATIONS] Error: \(error)")
            print("🔴 [API] [GET NOTIFICATIONS] Error Description: \(error.localizedDescription)")
            print("🔴 [API] [GET NOTIFICATIONS] ========================================")
            throw error
        }
    }
    
    
    func acceptFollowRequest(id: String) async throws -> AcceptFollowResponse {
        
        guard let url = URL(string: URL.acceptFollowRequest.absoluteString + id) else { throw NetworkError.badURL }
        
        let resource = Resource<AcceptFollowResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func rejectFollowRequest(id: String) async throws -> RejectFollowResponse {
        
        guard let url = URL(string: URL.rejectFollowRequest.absoluteString + id) else { throw NetworkError.badURL }
        
        let resource = Resource<RejectFollowResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func followBackUser(id: String) async throws -> FollowResponse {
        
        guard let url = URL(string: URL.followback.absoluteString + id) else { throw NetworkError.badURL }
        
        let resource = Resource<FollowResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getNotificationStatus() async throws -> NotificationStatusResponse {
        let resource = Resource<NotificationStatusResponse>(url: URL.notificationStatus, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func respondToCollaboration(postID: String, action: CollaborationResponseAction) async throws -> CollaborationRespondResponse {
        print("🟡 [API] [COLLAB RESPOND] ========================================")
        print("🟡 [API] [COLLAB RESPOND] Preparing collaboration respond API call")
        print("🟡 [API] [COLLAB RESPOND] URL: \(URL.collaborationRespond.absoluteString)")
        print("🟡 [API] [COLLAB RESPOND] Method: POST")
        
        let parameters: [String: Any] = [
            "postID": postID,
            "action": action.rawValue
        ]
        
        print("🟡 [API] [COLLAB RESPOND] Request Parameters:")
        print("🟡 [API] [COLLAB RESPOND]   postID: \(postID)")
        print("🟡 [API] [COLLAB RESPOND]   action: \(action.rawValue)")
        print("🟡 [API] [COLLAB RESPOND] Full parameters: \(parameters)")
        
        let resource = Resource<CollaborationRespondResponse>(url: .collaborationRespond, method: .post(parameters))
        
        print("🟡 [API] [COLLAB RESPOND] Making API request...")
        
        do {
            let result = try await baseNetworkManager.accessLoad(resource)
            
            print("🟡 [API] [COLLAB RESPOND] ✅ API Response received successfully")
            print("🟡 [API] [COLLAB RESPOND] Response Status: \(result.status)")
            print("🟡 [API] [COLLAB RESPOND] Response StatusCode: \(result.statusCode)")
            print("🟡 [API] [COLLAB RESPOND] Response Message: \(result.message)")
            print("🟡 [API] [COLLAB RESPOND] ========================================")
            
            return result
        } catch {
            print("🔴 [API] [COLLAB RESPOND] ❌ API Request failed!")
            print("🔴 [API] [COLLAB RESPOND] Error: \(error)")
            print("🔴 [API] [COLLAB RESPOND] Error Description: \(error.localizedDescription)")
            print("🔴 [API] [COLLAB RESPOND] ========================================")
            throw error
        }
    }
    
    
    func inviteCollaborator(postID: String, invitedUserID: String) async throws -> CollaborationInviteResponse {
        print("🟡 [API] [COLLAB INVITE] ========================================")
        print("🟡 [API] [COLLAB INVITE] Preparing collaboration invite API call")
        print("🟡 [API] [COLLAB INVITE] URL: \(URL.collaborationInvite.absoluteString)")
        print("🟡 [API] [COLLAB INVITE] Method: POST")
        
        let parameters: [String: Any] = [
            "postID": postID,
            "invitedUserID": invitedUserID
        ]
        
        print("🟡 [API] [COLLAB INVITE] Request Parameters:")
        print("🟡 [API] [COLLAB INVITE]   postID: \(postID)")
        print("🟡 [API] [COLLAB INVITE]   invitedUserID: \(invitedUserID)")
        print("🟡 [API] [COLLAB INVITE] Full parameters: \(parameters)")
        
        let resource = Resource<CollaborationInviteResponse>(url: .collaborationInvite, method: .post(parameters))
        
        print("🟡 [API] [COLLAB INVITE] Making API request...")
        
        do {
            let result = try await baseNetworkManager.accessLoad(resource)
            
            print("🟡 [API] [COLLAB INVITE] ✅ API Response received successfully")
            print("🟡 [API] [COLLAB INVITE] Response Status: \(result.status)")
            print("🟡 [API] [COLLAB INVITE] Response StatusCode: \(result.statusCode)")
            print("🟡 [API] [COLLAB INVITE] Response Message: \(result.message)")
            print("🟡 [API] [COLLAB INVITE] ========================================")
            
            return result
        } catch {
            print("🔴 [API] [COLLAB INVITE] ❌ API Request failed!")
            print("🔴 [API] [COLLAB INVITE] Error: \(error)")
            print("🔴 [API] [COLLAB INVITE] Error Description: \(error.localizedDescription)")
            print("🔴 [API] [COLLAB INVITE] ========================================")
            throw error
        }
    }
}
