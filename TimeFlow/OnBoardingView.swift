//
//  OnBoardingView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/25/25.


import SwiftUI

struct OnBoardingView: View {
    
    @Environment(ContentModel.self) var contentModel
    
    var body: some View {
        Button {
            contentModel.onBoardingComplete()
        } label: {
            Text("Complete On Boarding")
        }

    }
}

#Preview {
    OnBoardingView()
        .environment(ContentModel())
}

