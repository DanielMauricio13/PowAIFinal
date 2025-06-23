//
//  recoverAccount.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 6/23/25.
//

import SwiftUI
import RiveRuntime
struct recoverAccount: View {
    var body: some View {
        ZStack{
            LinearGradient(colors: [Color.cyan.opacity(0.7),Color.purple.opacity(0.7)],startPoint: .topLeading,endPoint: .bottomTrailing).ignoresSafeArea()
//
//                    Circle().scale(1.7).foregroundColor(.white.opacity(0.4))
//                    Circle().scale(1.35).foregroundColor(.red)
//                    Circle().scale(1).foregroundColor(.black)
//                    Circle().scale(1).foregroundColor(.white.opacity(0.4))
//                    Circle().scale(1).foregroundColor(.black.opacity(0.7))
            Circle().frame(width: 300).foregroundStyle(Color.blue.opacity(0.3)).blur(radius: 10).offset(x: -100, y: -150).animation(.bouncy, value: 10)
            Circle().frame(width: 300).foregroundStyle(Color.purple.opacity(0.3)).blur(radius: 10).offset(x: 150, y: 250)
            RoundedRectangle(cornerRadius: 30,style: .continuous).frame(width: 500,height: 500).foregroundStyle(LinearGradient(colors: [Color.purple, .mint], startPoint: .top, endPoint: .bottom)).offset(x:300,y: -200).blur(radius: 30).rotationEffect(.degrees(170))
            RiveViewModel(fileName: "shapes").view().ignoresSafeArea().blur(radius: 30)
            RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).frame(width: 350, height:350)
        }
    }
}

#Preview {
    recoverAccount()
}
