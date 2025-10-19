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
        case infrastructure = "Infrastructure"
        case marketing = "Marketing Campaign"
    }

    enum ProjectScale: String, CaseIterable {
        case small = "Small (1-3 months)"
        case medium = "Medium (3-9 months)"
        case large = "Large (9+ months)"
    }
    
    static func generate(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        let header = generateHeader(type: type, scale: scale, standard: standard)
        let approach = generateApproach(type: type, scale: scale, standard: standard)
        let phases = generatePhases(type: type, scale: scale, standard: standard)
        let keyActivities = generateKeyActivities(type: type, scale: scale, standard: standard)
        let deliverables = generateDeliverables(type: type, scale: scale, standard: standard)
        let recommendations = generateRecommendations(type: type, scale: scale, standard: standard)
        
        return """
        \(header)
        
        \(approach)
        
        \(phases)
        
        \(keyActivities)
        
        \(deliverables)
        
        \(recommendations)
        """
    }
    
    // MARK: - Template Generators
    
    private static func generateHeader(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        return """
        RECOMMENDED PROCESS SUMMARY
        
        Project Type: \(type.rawValue)
        Project Scale: \(scale.rawValue)
        Preferred Standard: \(standard.title)
        """
    }
    
    private static func generateApproach(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        let approach: String
        
        switch (type, scale, standard.fileName) {
        case (.software, .small, "PMBOK"):
            approach = "For this small-scale software project, an Agile-aligned approach following PMBOK's principles is recommended. Focus on iterative development with 1-2 week sprints, lightweight documentation, and frequent stakeholder feedback. The emphasis should be on rapid delivery of working software."
        case (.software, .small, "PRINCE2"):
            approach = "This small software project benefits from a tailored PRINCE2 approach with simplified stage boundaries. Use PRINCE2's themes (Business Case, Organization, Quality, etc.) but streamline processes. Consider 2-3 management stages with weekly checkpoints."
        case (.software, .small, "ISO21502"):
            approach = "Following ISO 21502 guidance for small projects, establish a streamlined governance structure with clear roles. Emphasize communication management and stakeholder engagement while keeping processes lightweight."
        case (.construction, .medium, "PRINCE2"):
            approach = "For medium-scale construction, implement full PRINCE2 methodology with defined management stages. Establish strong governance through Project Board oversight, detailed planning for each phase, and rigorous quality inspection points."
        case (.construction, _, "PMBOK"):
            approach = "Construction projects align well with PMBOK's traditional waterfall approach. Emphasize scope definition, detailed scheduling (CPM/PERT), cost estimation, quality assurance through inspections, and procurement management."
        case (.research, .small, "ISO21502"):
            approach = "Small research projects benefit from ISO 21502's flexible framework with emphasis on stakeholder engagement and knowledge management. Structure work in iterative cycles (literature review, data collection, analysis) with regular peer reviews."
        default:
            approach = "This project should follow \(standard.title) principles adapted to the \(scale.rawValue.lowered()) \(type.rawValue.lowered()) context. The approach should balance formality with flexibility, ensuring proper governance while enabling efficient delivery."
        }
        
        return """
        RECOMMENDED APPROACH
        A high-level strategy for managing this project.
        
        \(approach)
        """
    }
    
    private static func generatePhases(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        let phases: [String]
        
        switch (type, standard.fileName) {
        case (.software, "PRINCE2"):
            phases = [
                "Starting Up: Define project brief, appoint team, initial risk assessment.",
                "Initiating: Create Project Initiation Document (PID), establish baselines.",
                "Delivery Stages: Sprint planning, development iterations, testing cycles.",
                "Closing: User acceptance, deployment, lessons learned, project closure."
            ]
        case (.software, _):
            phases = [
                "Initiation: Requirements gathering, feasibility study, team formation.",
                "Planning: Architecture design, sprint planning, resource allocation.",
                "Execution: Iterative development, continuous integration, code reviews.",
                "Monitoring & Control: Daily standups, sprint reviews, quality assurance.",
                "Closure: UAT, deployment, documentation, post-launch support."
            ]
        case (.construction, _):
            phases = [
                "Concept: Define requirements, site selection, feasibility analysis.",
                "Design: Architectural/engineering design, permitting, approvals.",
                "Procurement: Contractor bidding, material sourcing, contract negotiation.",
                "Construction: Foundation, structure, MEP systems, finishes.",
                "Commissioning: Testing, inspections, certification, handover."
            ]
        case (.research, _):
            phases = [
                "Proposal: Research question, literature review, methodology design.",
                "Planning: Protocol development, ethical approval, resource allocation.",
                "Data Collection: Experiments/surveys, data gathering, quality checks.",
                "Analysis: Data processing, statistical analysis, validation.",
                "Dissemination: Paper writing, peer review, publication, presentation."
            ]
        default:
             phases = ["Initiation", "Planning", "Execution", "Monitoring & Control", "Closure"]
        }
        
        let phaseList = phases.enumerated().map { (index, phase) -> String in
            "\(index + 1). \(phase)"
        }.joined(separator: "\n")
        
        return """
        PROJECT PHASES
        A tailored set of stages for your project.
        
        \(phaseList)
        """
    }
    
    private static func generateKeyActivities(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        var activities: [String] = []
        
        switch scale {
        case .small:
            activities = ["Weekly team sync meetings.", "Bi-weekly stakeholder updates.", "Lightweight documentation."]
        case .medium:
            activities = ["Weekly steering committee meetings.", "Bi-weekly detailed progress reports.", "Formal change control process."]
        case .large:
            activities = ["Weekly PMO coordination.", "Bi-weekly executive steering committee.", "Formal gate reviews at phase transitions."]
        }
        
        switch type {
        case .software:
            activities += ["Daily standups.", "Sprint planning & retrospectives.", "Automated testing and CI/CD pipelines."]
        case .construction:
            activities += ["Daily site safety briefings.", "Weekly subcontractor coordination.", "Regular quality inspections."]
        case .research:
            activities += ["Regular peer review sessions.", "Data validation and verification.", "Conference presentations and publications."]
        default:
            break
        }
        
        let activityList = activities.map { "• \($0)" }.joined(separator: "\n")
        
        return """
        KEY ACTIVITIES
        Recommended actions to ensure project success.
        
        \(activityList)
        """
    }
    
    private static func generateDeliverables(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        let deliverables: [String]
        
        switch type {
        case .software:
            deliverables = ["Working software with source code.", "Technical and user documentation.", "Test results and QA reports."]
        case .construction:
            deliverables = ["Completed facility meeting specifications.", "As-built drawings.", "Operations and maintenance manuals."]
        case .research:
            deliverables = ["Research data sets with metadata.", "Published papers in peer-reviewed journals.", "Technical reports."]
        default:
            deliverables = ["Final Project Report.", "Key stakeholder presentations.", "Lessons Learned document."]
        }
        
        let deliverableList = deliverables.map { "• \($0)" }.joined(separator: "\n")
        
        return """
        KEY DELIVERABLES
        The primary outputs of the project.
        
        \(deliverableList)
        """
    }
    
    private static func generateRecommendations(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        var recommendations: [String] = []
        
        switch scale {
        case .small:
            recommendations.append("Keep processes lean and avoid over-engineering.")
        case .medium:
            recommendations.append("Balance formality with agility to maintain momentum.")
        case .large:
            recommendations.append("Establish a strong Project Management Office (PMO) for coordination.")
        }
        
        switch standard.fileName {
        case "PRINCE2":
            recommendations.append("Ensure continued business justification at each stage gate.")
        default:
            recommendations.append("Align project objectives closely with organizational strategy.")
        }
        
        let recommendationList = recommendations.map { "• \($0)" }.joined(separator: "\n")
        
        return """
        RECOMMENDATIONS
        Key considerations for this project.
        
        \(recommendationList)
        
        Note: This is a tailored recommendation based on \(standard.title). For detailed guidance, consult the full documentation.
        """
    }
}

private extension String {
    func lowered() -> String {
        self.lowercased()
    }
}
