<div align="center">
  <img src='https://github.com/jus10risner/jus10risner.github.io/blob/main/docs/assets/socket-app-icon.png?raw=true' height='100'>
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

<br>
Seeing an opportunity to build the app I was looking for, I started learning the Swift programming language and iOS development fundamentals. With this knowledge, I was able to create an app with the features I expected, while leveraging my UX design experience to make it simple and easy to use.


## Features

- Log maintenance services, and (optionally) receive alerts each time a service is due
- Document repairs, with the option to keep it simple or add notes and/or photos
- Log fill-ups, and see fuel economy trends over time
- Add additional information about each vehicle, for easy reference
- Export maintenance and repair records in PDF or CSV format
- Export fill-up records in CSV format
- iCloud sync, for peace of mind


## Details

- Built almost entirely using SwiftUI
  - `UIViewControllerRepresentable` was used to make the following UIKit-only features (as of iOS 15.0) available in SwiftUI:
    - `UIActivityViewController` for sharing photos and exporting records
    - `UIImagePickerController` for using the camera capture feature
    - `PHPickerViewController` for using the photo picker
- Core Data used for persistence
  - `NSPersistentCloudKitContainer` used to both persist data locally and sync to iCloud


## Challenges

<details>
  <summary><b>Navigation Title Transitions</b></summary>
  </br>

iOS 16 doesn’t seem to be able to negotiate the transition from a large navigation title to an inline navigation title, when both parent and child views are lists (with the parent view’s list items being navigation links). When using `NavigationView`, the child view maintains a large, empty space above the content, as though the navigation title were still large, even when it is manually set to be inline. When using `NavigationStack`, the parent view’s list jumps as the title transitions to inline, then the title remains inline when navigating back to the parent view (see clip below).

To resolve these issues, I first created a view modifier called `AppropriateNavigationType` that applies `NavigationView` on devices running iOS 15, and `NavigationStack` on devices running iOS16+. This prevents the large blank space from appearing at the top of the detail view in iOS 16. I then placed a `ZStack`, with a background element, around each navigation link on the parent views. This results in the parent views’ navigation titles smoothly transitioning to inline and back to large, when navigation to and from child views.

<img src='https://github.com/jus10risner/Socket/assets/79346093/726e3096-c32b-4914-b219-33b8b75725af' height='500'>

</details>

<details>
  <summary><b>Dismissing The Keyboard</b></summary>
  </br>

In iOS 15 and 16, attaching a *Done* button to the keyboard toolbar was an easy and reliable way to dismiss the keyboard. Beginning with iOS 17, the keyboard toolbar would only intermittently appear, making the *Done* button unreliable, and thus inappropriate to use. Instead, I added `UIScrollView.appearance().keyboardDismissMode = .interactive` to the root view of the app, to be applied when the app launches. This allows users to swipe to dismiss the keyboard, which is how many of Apple’s apps work, so I had no reservations in replacing the keyboard toolbar button with this feature.

I quickly learned that iOS 16 did not seem to be following the instructions I had laid out for keyboard dismissal, though iOS 15 and 17 worked as expected. I again created a custom view modifier, with this one applying `.scrollDismissesKeyboard(.interactively)` to iOS 16+ (it was introduced alongside iOS 16, and isn’t available for previous versions). With this, the swipe to dismiss feature works throughout the app, on each supported version of iOS. 
  
</details>
