//
//  ModalStackContainerView.swift
//  Modals
//
//  Created by Samuel McGarry on 8/8/23.
//

import SwiftUI

struct ModalStackContainerView<Content: View>: View, Equatable {
    static func == (lhs: ModalStackContainerView, rhs: ModalStackContainerView) -> Bool {
        true
    }
    
    var content: () -> Content
    
    @State var modalCount = 0
    @State var isBackgroundScalingEnabled = true
    @State var contentSaturation: CGFloat = 1
    @State var contentScaleEffect: CGFloat = 1
    @State var contentCornerRadius: CGFloat = 36
    @State var contentOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                ZStack {
                    Color.modalBackground
                        .saturation(contentSaturation)
                        .scaleEffect(contentScaleEffect, anchor: .center)
                        .offset(y: contentOffset)
                    Color.clear
                        .edgesIgnoringSafeArea(.all)
                }
                .edgesIgnoringSafeArea(.all)
                
                ZStack {
                    EquatableView(content: ModalStackRootView<Content>(content: content))
                }
                .saturation(contentSaturation)
                .scaleEffect(contentScaleEffect, anchor: .center)
                .offset(y: contentOffset)
            }
            .mask(
                ZStack {
                    RoundedRectangle(cornerRadius: contentCornerRadius, style: .continuous)
                    Color.clear
                        .edgesIgnoringSafeArea(.all)
                }
                .scaleEffect(contentScaleEffect, anchor: .center)
                .offset(y: contentOffset)
                .edgesIgnoringSafeArea(.all)
            )
        }
        .onReceive(ModalSystem.shared.$modals, perform: { output in
            modalsDidChange(output)
        })
        .onReceive(ModalSystem.shared.$dragProgress, perform: { output in
            dragProgressDidChange(output)
        })
    }

    func dragProgressDidChange(_ newValue: CGFloat) {
        guard isBackgroundScalingEnabled, modalCount == 1 else { return }
        
        var transaction = Transaction()
        transaction.isContinuous = true
        transaction.animation = .interpolatingSpring(stiffness: 222, damping: 28)
        
        withTransaction(transaction) {
            contentSaturation = newValue
            contentScaleEffect = 0.92 + (0.08 * newValue)
            contentCornerRadius = 36 + (UIScreen.main.displayCornerRadius - 36) * newValue
            contentOffset = 30 - (30 * newValue)
        }
    }
    
    func modalsDidChange(_ newValue: IdentifiedArrayOf<Modal>) {
        
        if newValue.isEmpty {
            isBackgroundScalingEnabled = true
        } else {
            for modal in newValue {
                if !modal.isBackgroundScalingEnabled {
                    isBackgroundScalingEnabled = false
                }
            }
        }
        
        if modalCount == 0 && newValue.count == 1 {
            contentCornerRadius = UIScreen.main.displayCornerRadius
        }
        
        modalCount = newValue.count
        
        guard isBackgroundScalingEnabled, newValue.count != 2 else { return }
        
        var transaction = Transaction()
        transaction.isContinuous = true
        transaction.animation = .interpolatingSpring(stiffness: 222, damping: 28)
        
        withTransaction(transaction) {
            contentSaturation = modalCount == 0 ? 1 : 0
            contentScaleEffect = modalCount == 0 ? 1 : 0.92
            contentCornerRadius = modalCount == 0 ? UIScreen.main.displayCornerRadius : 36
            contentOffset = modalCount == 0 ? 0 : 30
        }
        
        if modalCount == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard modalCount == 0 else { return }
                contentCornerRadius = 0
            }
        }
    }
}