//
//  Timer_Module_WidgetLiveActivity.swift
//  Timer Module Widget
//
//  Created by Michael Fluharty on 5/30/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Timer_Module_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Timer_Module_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Timer_Module_WidgetAttributes.self) { context in
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

extension Timer_Module_WidgetAttributes {
    fileprivate static var preview: Timer_Module_WidgetAttributes {
        Timer_Module_WidgetAttributes(name: "World")
    }
}

extension Timer_Module_WidgetAttributes.ContentState {
    fileprivate static var smiley: Timer_Module_WidgetAttributes.ContentState {
        Timer_Module_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Timer_Module_WidgetAttributes.ContentState {
         Timer_Module_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Timer_Module_WidgetAttributes.preview) {
   Timer_Module_WidgetLiveActivity()
} contentStates: {
    Timer_Module_WidgetAttributes.ContentState.smiley
    Timer_Module_WidgetAttributes.ContentState.starEyes
}
