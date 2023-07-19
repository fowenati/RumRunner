//
//  RumRunnerApp.swift
//  RumRunner
//
//  Created by Farris Owenati on 7/18/23.
//

import SwiftUI

@main
struct RumRunnerApp: App {
    @StateObject private var packageListViewModel = PackageListViewModel()

    var body: some Scene {
        WindowGroup {
            PackageListView()
                        .environmentObject(packageListViewModel)
        }
    }
}
