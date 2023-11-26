//
//  HARPApp.swift
//  HARP
//
//  Created by user247259 on 11/11/23.
//

import SwiftUI

@main
struct HARPApp: App {
    @ObservedObject var api = API()
    var body: some Scene {
        WindowGroup {
            MainView()
                //.environmentObject(Input())
                .environmentObject(api)
                .environmentObject(DataModel())
        }
    }
}
