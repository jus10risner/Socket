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


## Features

- Log maintenance services, and receive alerts each time they are due
- Document repairs, with the option to keep it simple or add notes and/or photos
- Log fill-ups, and see fuel economy trends over time
- Add additional information about each vehicle, for easy reference
- Export maintenance and repair records in PDF or CSV format, and fill-up records in CSV format
- iCloud sync


## Details

- Built almost entirely using SwiftUI
  - `UIViewControllerRepresentable` was used to make the following UIKit-only features (as of iOS 15.0) available in SwiftUI:
    - `UIActivityViewController` for sharing photos and exporting records
    - `UIImagePickerController` for using the camera capture feature
    - `PHPickerViewController` for using the photo picker
- Core Data used for persistence
  - `NSPersistentCloudKitContainer` used to both persist data locally and sync to iCloud


## Challenges

###  - Title Transitions

iOS 16 doesn’t seem to be able to negotiate the transition from a large navigation title to an inline navigation title, when both parent and child views are lists (with the parent view’s list items being navigation links). When using `NavigationView`, the child view maintains a large, empty space above the content, as though the navigation title were still large, even when it is manually set to be inline. When using `NavigationStack`, the parent view’s list jumps as the title transitions to inline, then the title remains inline when navigating back to the parent view (see clip below).

To resolve these issues, I first created a view modifier called `AppropriateNavigationType` that applies `NavigationView` on devices running iOS 15, and `NavigationStack` on devices running iOS16+. This prevents the large blank space from appearing at the top of the detail view in iOS 16. I then placed a `ZStack`, with a background element, around each navigation link on the parent views. This results in the parent views’ navigation titles smoothly transitioning to inline and back to large, when navigation to and from child views.



### - Dismissing The Keyboard

In iOS 15 and 16, attaching a *Done* button to the keyboard toolbar was an easy and reliable way to dismiss the keyboard. Beginning with iOS 17, the keyboard toolbar would only intermittently appear, making the *Done* button unreliable, and thus inappropriate to use. Instead, I added `UIScrollView.appearance().keyboardDismissMode = .interactive` to the root view of the app, to be applied when the app launches. This allows users to swipe to dismiss the keyboard, which is how many of Apple’s apps work, so I had no reservations in replacing the keyboard toolbar button with this feature.

I quickly learned that iOS 16 did not seem to be following the instructions I had laid out for keyboard dismissal, though iOS 15 and 17 worked as expected. I again created a custom view modifier, with this one applying `.scrollDismissesKeyboard(.interactively)` to iOS 16+ (it was introduced alongside iOS 16, and isn’t available for previous versions). With this, the swipe to dismiss feature works throughout the app, on each supported version of iOS. 
