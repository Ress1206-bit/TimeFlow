//
//  TabBarView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct TabBarView: View {
    
    @Binding var selectedTab: Int
    
    private let tabItems = [
        TabItem(icon: "house.fill", title: "Home", tag: 0),
        TabItem(icon: "target", title: "Goals", tag: 1),
        TabItem(icon: "doc.text.fill", title: "Assignments", tag: 2),
        TabItem(icon: "calendar.badge.clock", title: "Commitments", tag: 3),
        TabItem(icon: "chart.bar.fill", title: "Analytics", tag: 4),
    ]
    
    var body: some View {
        // Single container that extends to bottom
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(AppTheme.Colors.overlay.opacity(0.3))
            
            // Tab bar content
            HStack(spacing: 0) {
                ForEach(tabItems, id: \.tag) { item in
                    TabButton(
                        item: item,
                        selectedTab: $selectedTab
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .background(
            .ultraThinMaterial
        )
        .ignoresSafeArea(.all, edges: .bottom)
        .shadow(
            color: .black.opacity(0.1),
            radius: 10,
            x: 0,
            y: -2
        )
    }
}

struct TabButton: View {
    let item: TabItem
    @Binding var selectedTab: Int
    
    private var isSelected: Bool {
        selectedTab == item.tag
    }
    
    var body: some View {
        Button {
            // Only provide haptic feedback if the tab actually changes
            if selectedTab != item.tag {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                selectedTab = item.tag
            }
        } label: {
            // Icon
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(Rectangle()) // Ensures entire area is tappable
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Tab Item Model
struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}

#Preview {
    ZStack {
        AppTheme.Colors.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            TabBarView(selectedTab: .constant(0))
        }
    }
}