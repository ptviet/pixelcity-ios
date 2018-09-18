
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
    
    // flowlayout
    let screenWidth = UIScreen.main.bounds.width
    flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    flowLayout.itemSize = CGSize(width: screenWidth/5, height: screenWidth/5)
    flowLayout.minimumInteritemSpacing = 1
    flowLayout.minimumLineSpacing = 1
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
    
    collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
    collectionView?.delegate = self
    collectionView?.dataSource = self
    collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    
    registerForPreviewing(with: self, sourceView: collectionView!)
    
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
