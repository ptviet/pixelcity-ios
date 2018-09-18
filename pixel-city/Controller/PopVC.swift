
import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {
  
  @IBOutlet weak var popImageView: UIImageView!
  
  var image: UIImage?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    popImageView.image = image
    addDoubleTap()
    
  }
  
  func initData(forImage image: UIImage) {
    self.image = image
  }
  
  func addDoubleTap() {
    
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
    doubleTap.numberOfTapsRequired = 2
    doubleTap.delegate = self
    view.addGestureRecognizer(doubleTap)
    
  }
  
  @objc func onDoubleTap() {
    dismiss(animated: true, completion: nil)
  }
  
}
