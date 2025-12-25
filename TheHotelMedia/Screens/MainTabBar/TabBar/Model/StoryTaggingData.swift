import Foundation

struct StoryTaggingData {
    var mentions: [String] = []
    var placeName: String? = nil
    var lat: Double? = nil
    var lng: Double? = nil
    var locationPositionX: Double? = nil
    var locationPositionY: Double? = nil
    var userTagged: String? = nil
    var userTaggedId: String? = nil
    var userTaggedPositionX: Double? = nil
    var userTaggedPositionY: Double? = nil
    
    var location: Location? {
        if let placeName = placeName, let lat = lat, let lng = lng {
            return Location(lat: lat, lng: lng, placeName: placeName)
        }
        return nil
    }
}
