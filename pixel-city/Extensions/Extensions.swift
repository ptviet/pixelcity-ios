
import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

extension MapVC: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if annotation is MKUserLocation {
      return nil
    }
    
    let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "dropablePin")
    pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
    pinAnnotation.animatesDrop = true
    return pinAnnotation
  }
  
  func centerMapOnUserLocation() {
    guard let coordinate = locationManager.location?.coordinate else { return }
    let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
    mapView.setRegion(coordinateRegion, animated: true)
    
  }
  
  @objc func dropPin(sender: UITapGestureRecognizer) {
    
    reset()
    
    let touchPoint = sender.location(in: mapView)
    let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    let annotation = DropablePin(coordinate: touchCoordinate, identifier: "dropablePin")
    mapView.addAnnotation(annotation)
    let coordinateRegion = MKCoordinateRegion(center: touchCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
    mapView.setRegion(coordinateRegion, animated: true)
    
    retrieveUrls(forAnnotation: annotation) { (success) in
      if success {
        self.retrieveImages(completion: { (success) in
          if success {
            self.removeSpinner()
            self.removeProgressLabel()
            self.collectionView?.reloadData()
          }
        })
        
      }
    }
  }
  
  func reset() {
    cancelAllSessions()
    removePin()
    removeSpinner()
    removeProgressLabel()
    
    imageUrlArray.removeAll()
    imageArray.removeAll()
    collectionView?.reloadData()
    
    animateViewUp()
    
    addSwipe()
    addSpinner()
    addProgressLabel()
  }
  
  func removePin() {
    for annotation in mapView.annotations {
      mapView.removeAnnotation(annotation)
    }
  }
  
  func retrieveUrls(forAnnotation annotation: DropablePin, completion: @escaping (_ status: Bool) -> () ) {
    
    Alamofire.request(flickrUrl(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 16))
      .responseJSON { (response) in
        guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
        let photosDictionary = json["photos"] as! Dictionary<String, AnyObject>
        let photosDictionaryArray = photosDictionary["photo"] as! [Dictionary<String, AnyObject>]
        for photo in photosDictionaryArray {
          let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
          self.imageUrlArray.append(postUrl)
        }
        
        completion(true)
    }
  }
  
  func retrieveImages(completion: @escaping (_ status: Bool) -> ()) {
    
    for url in imageUrlArray {
      Alamofire.request(url).responseImage { (response) in
        guard let image = response.result.value else { return }
        self.imageArray.append(image)
        self.progressLabel?.text = "\(self.imageArray.count)/\(self.imageUrlArray.count) photos downloaded..."
        
        if self.imageArray.count == self.imageUrlArray.count {
          completion(true)
        }
        
      }
    }
  }
  
  func cancelAllSessions() {
    Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
      sessionDataTask.forEach({$0.cancel()})
      uploadData.forEach({$0.cancel()})
      downloadData.forEach({$0.cancel()})
    }
  }
  
}


extension MapVC: CLLocationManagerDelegate {
  
  func configureLocationServices() {
    if authStatus == .notDetermined {
      locationManager.requestAlwaysAuthorization()
    } else {
      return
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    centerMapOnUserLocation()
  }
  
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageArray.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell()}
    
    let imageFromIndex = imageArray[indexPath.row]
    let imageView = UIImageView(image: imageFromIndex)
    imageView.contentMode = UIView.ContentMode.scaleAspectFill
    imageView.layer.masksToBounds = true;
    cell.contentMode = UIView.ContentMode.scaleAspectFill
    cell.layer.masksToBounds = true;
    cell.addSubview(imageView)
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
    popVC.initData(forImage: imageArray[indexPath.row])
    present(popVC, animated: true, completion: nil)
  }
  
}

extension MapVC: UIViewControllerPreviewingDelegate {
  
  func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
    
    guard let indexPath = collectionView?.indexPathForItem(at: location),
      let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
    
    guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return nil }
    popVC.initData(forImage: imageArray[indexPath.row])
    
    previewingContext.sourceRect = cell.contentView.frame
    
    return popVC
  }
  
  func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    
    show(viewControllerToCommit, sender: self)
    
  }
  
  
}
