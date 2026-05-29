//
//  recoverAccount.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 6/23/25.
//

import SwiftUI
import RiveRuntime
import MessageUI

struct MailView: UIViewControllerRepresentable {

    var to: String
    var subject: String
    var body: String
    var preferredFrom: String?

    @Environment(\.presentationMode) var presentation

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        init(_ parent: MailView) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            parent.presentation.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()

        vc.setToRecipients([to])
        if let from = preferredFrom {
            if #available(iOS 11.0, *) {
                vc.setPreferredSendingEmailAddress(from)
            }
        }

        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

struct recoverAccountS: View {
    @State private var email = ""
    @State private var showMail = false
    @State private var showAlert = false

    private let supportEmail = "danielmauriciovpinilla@hotmail.com"


    var body: some View {
        ZStack {
            AppBackgroundView()
            Circle().frame(width: 300).foregroundStyle(Color.blue.opacity(0.3)).blur(radius: 10).offset(x: -100, y: -150).animation(.bouncy, value: 10)
            Circle().frame(width: 300).foregroundStyle(Color.purple.opacity(0.3)).blur(radius: 10).offset(x: 150, y: 250)
            RoundedRectangle(cornerRadius: 30, style: .continuous).frame(width: 500, height: 500).foregroundStyle(LinearGradient(colors: [Color.purple, .mint], startPoint: .top, endPoint: .bottom)).offset(x: 300, y: -200).blur(radius: 30).rotationEffect(.degrees(170))
            RiveViewModel(fileName: "shapes").view().ignoresSafeArea().blur(radius: 30)
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).frame(width: 350, height: 250)
                VStack(spacing: 20) {
                    Text("Recover Account").font(.title2).bold()
                    TextField("Your email", text: $email).padding().frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10)
                    Button(action: {
                        if MFMailComposeViewController.canSendMail() {
                            showMail = true
                        } else { showAlert = true }
                    }) {
                        Text("Send Recovery Email").padding().frame(width: 300, height: 50).background(Color.blue).foregroundColor(.white).cornerRadius(10)
                    }
                }
            }
        }
        .sheet(isPresented: $showMail) {

            MailView(to: supportEmail,
                     subject: "Account Recovery",
                     body: "Recovery request from: \(email)",
                     preferredFrom: email)

        }
        .alert("Mail services are not available", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

#Preview {
    recoverAccount()
}
