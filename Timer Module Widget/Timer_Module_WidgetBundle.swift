//
//  Timer_Module_WidgetBundle.swift
//  Timer Module Widget
//
//  Created by Michael Fluharty on 5/30/26.
//

import WidgetKit
import SwiftUI

@main
struct Timer_Module_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Timer_Module_Widget()
        Timer_Module_WidgetControl()
        Timer_Module_WidgetLiveActivity()
    }
}
