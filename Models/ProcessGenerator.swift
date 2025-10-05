//
//  ProcessGenerator.swift
//  PM-App
//
//  Created by usear on 10/4/25.
//

import Foundation


struct ProcessGenerator {
    enum ProjectType: String, CaseIterable {
        case software = "Software Development"
        case construction = "Construction"
        case research = "Research Project"
    }

    enum ProjectScale: String, CaseIterable {
        case small = "Small (1-3 months)"
        case medium = "Medium (3-9 months)"
        case large = "Large (9+ months)"
    }
    
    static func generate(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {

        return """
        Recommended Process Summary
        -----------------------------
        
        Project Type: \(type.rawValue)
        Project Scale: \(scale.rawValue)
        Preferred Standard: \(standard.title)

        Recommended Steps (based on \(standard.title)):
        1. Initiation: Define project goals, scope, and stakeholders.
        2. Planning: Develop a detailed project plan, including schedule, budget, and resources.
        3. Execution: Carry out the plan, managing tasks and team collaboration.
        4. Monitoring & Controlling: Track progress against the plan and manage changes.
        5. Closure: Formalize project completion and document lessons learned.
        
        Note: This is a simplified process. For a real-world \(type.rawValue) project, consult the \(standard.title) documentation for detailed guidance.
        """
    }
}
