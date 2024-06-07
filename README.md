<div align="center">
  <img src='https://jus10risner.github.io/docs/assets/socket-app-icon.png' height='100'>
  <h1>Socket: Car Care Tracker</h1>
  <p>Easily log and manage vehicle care, with this simple, user-friendly app that looks and feels right at home on iPhone.</p>

  <img src='https://jus10risner.github.io/docs/assets/socket-site-image1.png' height='500'> <img src='https://jus10risner.github.io/docs/assets/socket-site-image2.png' height='500'> <img src='https://jus10risner.github.io/docs/assets/socket-site-image3.png' height='500'>

  <a href="https://apps.apple.com/app/id6502462009">
    <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/white/en-us?size=250x83&amp;releaseDate=1276560000&h=7e7b68fad19738b5649a1bfb78ff46e9"
          alt="Download on the App Store"/>
  </a>
</div>

## Frameworks Used

### SwiftUI

Socket was built almost entirely using SwiftUI. 

UIKit was used only for features that were not yet avaialable natively in SwiftUI, as of iOS 15.0; these included UIActivityViewController, UIImagePickerController, and PHPickerViewController. These features were made available for use in SwiftUI, using the UIViewControllerRepresentable protocol.
 
### Core Data

Core Data was chosen for persistence, primarily because it can handle large amounts of data efficiently. 

The app was initially built with 

### CloudKit
