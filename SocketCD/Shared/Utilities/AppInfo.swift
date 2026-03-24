//
//  AppInfo.swift
//  SocketCD
//
//  Created by Justin Risner on 3/22/24.
//

import Foundation

// Source: https://stackoverflow.com/questions/24501288/getting-version-and-build-information-with-swift
struct AppInfo {

   /// Returns the official app name, defined in project data.
   var appName : String {
       return readFromInfoPlist(withKey: "CFBundleName") ?? "(unknown app name)"
   }

   /// Return the official app display name, eventually defined in 'infoplist'.
   var displayName : String {
       return readFromInfoPlist(withKey: "CFBundleDisplayName") ?? "(unknown app display name)"
   }

   /// Returns the official version, defined in  project data.
   var version : String {
       return readFromInfoPlist(withKey: "CFBundleShortVersionString") ?? "(unknown app version)"
   }

   /// Returns the official 'build', defined in  project data.
   var build : String {
       return readFromInfoPlist(withKey: "CFBundleVersion") ?? "(unknown build number)"
   }

   /// Returns the minimum OS version defined in  project data.
   var minimumOSVersion : String {
    return readFromInfoPlist(withKey: "MinimumOSVersion") ?? "(unknown minimum OSVersion)"
   }

   /// Returns the copyright notice eventually defined in project data.
   var copyrightNotice : String {
       return readFromInfoPlist(withKey: "NSHumanReadableCopyright") ?? "(unknown copyright notice)"
   }

   /// Returns the official bundle identifier defined in  project data.
   var bundleIdentifier : String {
       return readFromInfoPlist(withKey: "CFBundleIdentifier") ?? "(unknown bundle identifier)"
   }

   var developer : String { return "Justin Risner" }

   // MARK: - Private stuff

   // Holds a reference to the Info.plist of the app as Dictionary
   private let infoPlistDictionary = Bundle.main.infoDictionary

   /// Retrieves and returns associated values (of Type String) from info.Plist of the app.
   private func readFromInfoPlist(withKey key: String) -> String? {
       return infoPlistDictionary?[key] as? String
   }
}
