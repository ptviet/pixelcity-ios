// Flickr: PixelCity
// API Key: 0c7b4faaa39eb42776c5db58cb584476
// Secret: 621db5862ece92c1
import Foundation

let API_KEY = "0c7b4faaa39eb42776c5db58cb584476"

func flickrUrl(forApiKey key: String, withAnnotation annotation: DropablePin, andNumberOfPhotos number: Int) -> String {
  
  return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=km&per_page=\(number)&format=json&nojsoncallback=1"
}
