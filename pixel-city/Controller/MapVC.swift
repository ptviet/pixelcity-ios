
import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var pullUpView: UIView!
  @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
  
  var locationManager = CLLocationManager()
  let authStatus = CLLocationManager.authorizationStatus()
  
  let regionRadius: Double = 1000
  
  var spinner: UIActivityIndicatorView?
  var progressLabel: UILabel?
  
  var screenSize = UIScreen.main.bounds
  
  var flowLayout = UICollectionViewFlowLayout()
  var collectionView: UICollectionView?
  
  var imageUrlArray = [String]()
  var imageArray = [UIImage]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self
    locationManager.delegate = self
    configureLocationServices()
    addDoubleTap()
    
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
    collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
    collectionView?.delegate = self
    collectionView?.dataSource = self
    collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    
    pullUpView.addSubview(collectionView!)
    
  }
  
  func addDoubleTap() {
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
    doubleTap.numberOfTapsRequired = 2
    doubleTap.delegate = self
    mapView.addGestureRecognizer(doubleTap)
  }
  
  func addSwipe() {
    let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
    swipe.direction = .down
    pullUpView.addGestureRecognizer(swipe)
  }
  
  @objc func animateViewDown() {
    cancelAllSessions()
    pullUpViewHeightConstraint.constant = 0
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }
  
  func animateViewUp() {
    pullUpViewHeightConstraint.constant = 300
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
    
  }
  
  func addSpinner() {
    spinner = UIActivityIndicatorView()
    spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
    spinner?.style = .whiteLarge
    spinner?.color = #colorLiteral(red: 0.3631127477, green: 0.4045833051, blue: 0.8775706887, alpha: 1)
    spinner?.startAnimating()
    collectionView?.addSubview(spinner!)
  }
  
  func removeSpinner() {
    if spinner != nil {
      spinner?.removeFromSuperview()
    }
  }
  
  func addProgressLabel() {
    progressLabel = UILabel()
    progressLabel?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
    progressLabel?.font = UIFont(name: "Avenir-Light", size: 18)
    progressLabel?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
    progressLabel?.textAlignment = .center
    progressLabel?.text = "Retrieving photos..."
    collectionView?.addSubview(progressLabel!)
    
  }
  
  func removeProgressLabel() {
    if progressLabel != nil {
      progressLabel?.removeFromSuperview()
    }
  }
  
  @IBAction func onCenterMapBtnPressed(_ sender: Any) {
    if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
      centerMapOnUserLocation()
    }
  }
  
}

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
    
    Alamofire.request(flickrUrl(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 20))
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
    cell.addSubview(imageView)
    
    return cell
  }
  
  
}
