//
//  Standard.swift
//  PM-App
//
//  Created by usear on 10/4/25.
//

import Foundation


struct Standard {
    let title: String
    let fileName: String
}

struct StandardsData {
    static let allStandards: [Standard] = [
        Standard(title: "PMBOK 7th Edition", fileName: "PMBOK"),
        Standard(title: "PRINCE2", fileName: "PRINCE2"),
        Standard(title: "ISO 21502", fileName: "ISO21502")
    ]
}
