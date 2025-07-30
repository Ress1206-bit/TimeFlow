//
//  TimeFlowWidgetLiveActivity.swift
//  TimeFlowWidget
//
//  Created by Adam Ress on 7/29/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TimeFlowWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TimeFlowWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeFlowWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TimeFlowWidgetAttributes {
    fileprivate static var preview: TimeFlowWidgetAttributes {
        TimeFlowWidgetAttributes(name: "World")
    }
}

extension TimeFlowWidgetAttributes.ContentState {
    fileprivate static var smiley: TimeFlowWidgetAttributes.ContentState {
        TimeFlowWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TimeFlowWidgetAttributes.ContentState {
         TimeFlowWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TimeFlowWidgetAttributes.preview) {
   TimeFlowWidgetLiveActivity()
} contentStates: {
    TimeFlowWidgetAttributes.ContentState.smiley
    TimeFlowWidgetAttributes.ContentState.starEyes
}
