<div align="center">
  <img width="100" height="100" alt="socket-app-icon" src="https://github.com/user-attachments/assets/e50521f8-36bd-4323-8952-4cade2ce111f" />

  <h1>Socket: Car Care Tracker</h1>
  <p>Easily log and manage vehicle care, with this simple, user-friendly app that looks and feels right at home on iPhone.</p>
  
<img width="750" height="500" alt="web-image-rounded-corners" src="https://github.com/user-attachments/assets/f12cbd84-fb95-45e1-b710-60e1ea35c1c5" />
  <br>
  <br>

  <a href="https://apps.apple.com/app/id6502462009">
    <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/white/en-us?size=250x83&amp;releaseDate=1276560000&h=7e7b68fad19738b5649a1bfb78ff46e9"
          alt="Download on the App Store"/>
  </a>
</div>

## 
A few years ago, I opened the App Store app on my iPhone and searched for a vehicle maintenance tracker. I was looking for something simple and user-friendly, with all the features one would expect from this type of app: maintenance reminders, repair and fill-up logging, and the ability to export vehicle records. My search results were full of apps that seemed to focus primarily on either UI design or feature set, but few did both well, and none seemed to prioritize the user experience.

Seeing an opportunity to build the app I was looking for, I started learning the Swift programming language and iOS development fundamentals. With this knowledge, I was able to create an app with the features I expected, while leveraging my UX design experience to make it simple and easy to use.


## Features

- Log maintenance services, and (optionally) receive alerts each time a service is due
- Document repairs, with the option to keep it simple or add notes and/or photos
- Log fill-ups, and see fuel economy trends over time
- Add additional information about each vehicle, for easy reference
- Export records in PDF and/or CSV format
- iCloud sync, for peace of mind


## Details

- Built almost entirely using SwiftUI
  - `UIViewControllerRepresentable` was used to make the following UIKit-only features (as of iOS 15.0) available in SwiftUI:
    - `UIActivityViewController` for sharing photos and exporting records
    - `UIImagePickerController` for using the camera capture feature
- Core Data used for persistence
  - `NSPersistentCloudKitContainer` used to both persist data locally and sync to iCloud
