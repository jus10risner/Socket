//
//  MailComposeViewController.swift
//  SocketCD
//
//  Created by Justin Risner on 4/9/24.
//

import MessageUI
import SwiftUI

class MailComposeViewController: UIViewController, MFMailComposeViewControllerDelegate {
    static let shared = MailComposeViewController()
    static let feedbackEmailAddress = "feedback@justinrisner.com"
    
    var canSendEmail: Bool {
        if MFMailComposeViewController.canSendMail() {
            return true
        } else {
            return false
        }
    }

    @discardableResult
    func sendEmail() -> Bool {
        guard canSendEmail else { return false }

        let appInfo = AppInfo()
        let device = UIDevice.current
        let diagnostics = """
        Diagnostic Info

        This attachment contains general app and device information to help us understand your feedback. It does not include your personal data.

        Version: \(appInfo.version)
        Build: \(appInfo.build)
        Operating System: \(device.systemName) \(device.systemVersion)
        Device Type: \(device.model)
        Region: \(Locale.current.region?.identifier ?? "Unknown")

        Region reflects the device's region setting, not its physical location.
        """
        
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients([Self.feedbackEmailAddress])
        mail.setMessageBody("", isHTML: false)
        mail.addAttachmentData(
            Data(diagnostics.utf8),
            mimeType: "text/plain",
            fileName: "DiagnosticInfo.txt"
        )
        
        // Finds the topmost view controller and presents from there, to avoid "...which was already presenting" error
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        guard var topVC = window?.rootViewController else { return false }
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        guard topVC.viewIfLoaded?.window != nil,
              !topVC.isBeingDismissed,
              !topVC.isBeingPresented else { return false }

        topVC.present(mail, animated: true)
        return mail.presentingViewController != nil
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
