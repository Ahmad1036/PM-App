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
        📋 RECOMMENDED PROCESS SUMMARY
        ═══════════════════════════════════════
        
        Project Type: \(type.rawValue)
        Project Scale: \(scale.rawValue)
        Preferred Standard: \(standard.title)
        """
    }
    
    private static func generateApproach(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        let approach: String
        
        // Context-aware approach based on type, scale, and standard
        switch (type, scale, standard.fileName) {
        case (.software, .small, "PMBOK"):
            approach = "For this small-scale software project, we recommend an **Agile-aligned approach** following PMBOK's principles. Focus on iterative development with 1-2 week sprints, lightweight documentation, and frequent stakeholder feedback. The emphasis should be on rapid delivery of working software while maintaining quality through continuous integration and testing."
            
        case (.software, .small, "PRINCE2"):
            approach = "This small software project benefits from a **tailored PRINCE2 approach** with simplified stage boundaries. Use PRINCE2's themes (Business Case, Organization, Quality, Plans, Risk, Change, Progress) but streamline processes. Consider 2-3 management stages with weekly checkpoints, focusing on controlled start-up and delivery phases."
            
        case (.software, .small, "ISO21502"):
            approach = "Following **ISO 21502 guidance** for small projects, establish a streamlined governance structure with clear roles. Emphasize communication management and stakeholder engagement while keeping processes lightweight. Focus on establishing clear success criteria and maintaining alignment with organizational objectives."
            
        case (.software, .medium, "PMBOK"):
            approach = "A **hybrid approach** combining PMBOK knowledge areas with agile practices is ideal. Use PMBOK's integration, scope, and quality management alongside agile iterations. Plan for 4-6 releases with proper risk management and stakeholder communication. Balance documentation with agility."
            
        case (.software, .large, "PMBOK"):
            approach = "This large-scale software initiative requires **comprehensive PMBOK application** across all 10 knowledge areas. Implement formal program management with multiple work streams, rigorous change control, and extensive stakeholder management. Plan for phased releases with detailed risk mitigation and quality assurance at each stage."
            
        case (.construction, .small, "PRINCE2"):
            approach = "Small construction projects thrive under **PRINCE2's structured framework**. Use clear stage gates (Planning, Foundation, Build, Handover) with emphasis on quality control and supplier management. Weekly progress reviews ensure tight schedule adherence and cost control."
            
        case (.construction, .medium, "PRINCE2"):
            approach = "For medium-scale construction, implement **full PRINCE2 methodology** with defined management stages. Establish strong governance through Project Board oversight, detailed planning for each construction phase, and rigorous quality inspection points. Focus on managing specialist subcontractors and material procurement."
            
        case (.construction, .large, "PRINCE2"):
            approach = "Large construction projects demand **comprehensive PRINCE2 governance** with multiple authorization points. Structure into distinct stages (Design, Procurement, Foundation, Structure, Finishing, Commissioning) with formal gate reviews. Implement robust risk management for safety, regulatory compliance, and supply chain complexities."
            
        case (.construction, _, "PMBOK"):
            approach = "Construction projects align well with **PMBOK's traditional waterfall approach**. Emphasize scope definition, detailed scheduling (CPM/PERT), cost estimation and control, quality assurance through inspections, and procurement management for materials and subcontractors. Strong integration management is critical for coordinating multiple specialties."
            
        case (.research, .small, "ISO21502"):
            approach = "Small research projects benefit from **ISO 21502's flexible framework** with emphasis on stakeholder engagement and knowledge management. Structure work in iterative cycles (literature review, methodology, data collection, analysis) with regular peer reviews. Focus on maintaining research integrity and documentation standards."
            
        case (.research, .medium, "ISO21502"):
            approach = "Medium-scale research requires **ISO 21502's comprehensive governance** with strong emphasis on data management and quality assurance. Establish clear research phases with validation gates, ethical review checkpoints, and collaborative team structures. Focus on reproducibility and knowledge transfer."
            
        case (.research, .large, "ISO21502"):
            approach = "Large research initiatives need **full ISO 21502 implementation** with multi-stakeholder governance. Structure as a program with multiple research streams, formal steering committee oversight, and regular publication milestones. Emphasize risk management for research validity, data security, and intellectual property."
            
        case (.infrastructure, .large, _):
            approach = "Large infrastructure projects require **rigorous planning and execution** regardless of standard. Focus on multi-year phased delivery, extensive stakeholder management (government, public, contractors), regulatory compliance, environmental impact management, and public safety. Strong program management with clear governance is essential."
            
        case (.marketing, .small, "PMBOK"):
            approach = "Small marketing campaigns work well with **PMBOK's iterative approach** adapted for creative projects. Focus on scope management (campaign objectives), time management (launch dates), and stakeholder management (creative team, clients, media partners). Keep processes lightweight but maintain quality control for brand consistency."
            
        default:
            approach = "This project will follow **\(standard.title) principles** adapted to the \(scale.rawValue.lowercased()) \(type.rawValue.lowercased()) context. The approach balances formality with flexibility, ensuring proper governance while enabling efficient delivery."
        }
        
        return """
        🎯 RECOMMENDED APPROACH
        ───────────────────────────────────────
        \(approach)
        """
    }
    
    private static func generatePhases(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        let phases: [String]
        
        switch (type, standard.fileName) {
        case (.software, "PRINCE2"):
            phases = [
                "1️⃣ Starting Up: Define project brief, appoint team, initial risk assessment",
                "2️⃣ Initiating: Create Project Initiation Document (PID), establish baselines",
                "3️⃣ Delivery Stages: Sprint planning, development iterations, testing cycles",
                "4️⃣ Closing: User acceptance, deployment, lessons learned, project closure"
            ]
            
        case (.software, _):
            phases = [
                "1️⃣ Initiation: Requirements gathering, feasibility study, team formation",
                "2️⃣ Planning: Architecture design, sprint planning, resource allocation",
                "3️⃣ Execution: Iterative development, continuous integration, code reviews",
                "4️⃣ Monitoring & Control: Daily standups, sprint reviews, quality assurance",
                "5️⃣ Closure: UAT, deployment, documentation, post-launch support"
            ]
            
        case (.construction, "PRINCE2"):
            phases = [
                "1️⃣ Pre-Project: Feasibility, site assessment, preliminary design",
                "2️⃣ Initiation: Detailed design, permitting, contractor selection",
                "3️⃣ Foundation Stage: Site preparation, foundation work, inspections",
                "4️⃣ Structure Stage: Main construction, quality checkpoints, safety audits",
                "5️⃣ Finishing Stage: Interior work, systems installation, final inspections",
                "6️⃣ Handover: Commissioning, documentation, defect liability period"
            ]
            
        case (.construction, _):
            phases = [
                "1️⃣ Concept: Define requirements, site selection, feasibility analysis",
                "2️⃣ Design: Architectural/engineering design, permitting, approvals",
                "3️⃣ Procurement: Contractor bidding, material sourcing, contract negotiation",
                "4️⃣ Construction: Foundation, structure, MEP systems, finishes",
                "5️⃣ Commissioning: Testing, inspections, certification, handover"
            ]
            
        case (.research, _):
            phases = [
                "1️⃣ Proposal: Research question, literature review, methodology design",
                "2️⃣ Planning: Protocol development, ethical approval, resource allocation",
                "3️⃣ Data Collection: Experiments/surveys, data gathering, quality checks",
                "4️⃣ Analysis: Data processing, statistical analysis, validation",
                "5️⃣ Dissemination: Paper writing, peer review, publication, presentation"
            ]
            
        case (.infrastructure, _):
            phases = [
                "1️⃣ Planning: Needs assessment, environmental impact, stakeholder engagement",
                "2️⃣ Design: Detailed engineering, regulatory approvals, funding secured",
                "3️⃣ Procurement: Major contracts, equipment sourcing, partnerships",
                "4️⃣ Construction: Phased delivery, safety management, public communication",
                "5️⃣ Commissioning: Testing, training, phased handover, warranty period"
            ]
            
        case (.marketing, _):
            phases = [
                "1️⃣ Strategy: Campaign objectives, audience research, creative brief",
                "2️⃣ Creative Development: Concept creation, design, content production",
                "3️⃣ Pre-Launch: Media planning, channel setup, test campaigns",
                "4️⃣ Execution: Campaign launch, multi-channel activation, monitoring",
                "5️⃣ Optimization: Performance analysis, A/B testing, adjustments",
                "6️⃣ Evaluation: ROI analysis, reporting, insights documentation"
            ]
        }
        
        return """
        📊 PROJECT PHASES
        ───────────────────────────────────────
        \(phases.joined(separator: "\n"))
        """
    }
    
    private static func generateKeyActivities(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        var activities: [String] = []
        
        // Scale-specific activities
        switch scale {
        case .small:
            activities = [
                "🔹 Weekly team sync meetings (30 min)",
                "🔹 Bi-weekly stakeholder updates",
                "🔹 Lightweight documentation (only essential)",
                "🔹 Rapid decision-making processes"
            ]
        case .medium:
            activities = [
                "🔹 Weekly steering committee meetings",
                "🔹 Bi-weekly detailed progress reports",
                "🔹 Monthly risk review sessions",
                "🔹 Formal change control process"
            ]
        case .large:
            activities = [
                "🔹 Weekly program management office (PMO) coordination",
                "🔹 Bi-weekly executive steering committee",
                "🔹 Monthly comprehensive status reporting",
                "🔹 Formal gate reviews at phase transitions",
                "🔹 Dedicated risk management and quality assurance teams"
            ]
        }
        
        // Type-specific activities
        switch type {
        case .software:
            activities += [
                "🔹 Daily standups (15 min)",
                "🔹 Sprint planning & retrospectives",
                "🔹 Code reviews and pair programming",
                "🔹 Automated testing and CI/CD pipelines"
            ]
        case .construction:
            activities += [
                "🔹 Daily site safety briefings",
                "🔹 Weekly subcontractor coordination",
                "🔹 Regular quality inspections",
                "🔹 Material delivery scheduling"
            ]
        case .research:
            activities += [
                "🔹 Regular peer review sessions",
                "🔹 Data validation and verification",
                "🔹 Literature updates and methodology reviews",
                "🔹 Conference presentations and publications"
            ]
        case .infrastructure:
            activities += [
                "🔹 Public consultation sessions",
                "🔹 Regulatory compliance reporting",
                "🔹 Environmental monitoring",
                "🔹 Multi-agency coordination meetings"
            ]
        case .marketing:
            activities += [
                "🔹 Creative review sessions",
                "🔹 Campaign performance monitoring",
                "🔹 Social media engagement tracking",
                "🔹 A/B testing and optimization"
            ]
        }
        
        return """
        ⚙️ KEY ACTIVITIES
        ───────────────────────────────────────
        \(activities.joined(separator: "\n"))
        """
    }
    
    private static func generateDeliverables(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        let deliverables: [String]
        
        switch type {
        case .software:
            deliverables = [
                "📦 Working software with source code repository",
                "📦 Technical documentation (API docs, architecture diagrams)",
                "📦 User documentation and training materials",
                "📦 Test results and quality assurance reports",
                "📦 Deployment guide and release notes",
                "📦 Project closure report and lessons learned"
            ]
        case .construction:
            deliverables = [
                "📦 Completed facility/structure meeting specifications",
                "📦 As-built drawings and documentation",
                "📦 Quality inspection certificates",
                "📦 Operations and maintenance manuals",
                "📦 Warranty documentation",
                "📦 Final project report and lessons learned"
            ]
        case .research:
            deliverables = [
                "📦 Research data sets (with metadata)",
                "📦 Published papers in peer-reviewed journals",
                "📦 Technical reports and white papers",
                "📦 Presentation materials (conference posters/slides)",
                "📦 Research protocol and methodology documentation",
                "📦 Knowledge transfer materials"
            ]
        case .infrastructure:
            deliverables = [
                "📦 Operational infrastructure asset",
                "📦 Comprehensive engineering documentation",
                "📦 Environmental compliance reports",
                "📦 Training programs for operators",
                "📦 Public communication materials",
                "📦 Asset management plan"
            ]
        case .marketing:
            deliverables = [
                "📦 Campaign creative assets (videos, graphics, copy)",
                "📦 Multi-channel campaign execution",
                "📦 Performance analytics dashboard",
                "📦 Campaign ROI report",
                "📦 Customer insights and learnings",
                "📦 Brand assets library"
            ]
        }
        
        return """
        📁 KEY DELIVERABLES
        ───────────────────────────────────────
        \(deliverables.joined(separator: "\n"))
        """
    }
    
    private static func generateRecommendations(type: ProjectType, scale: ProjectScale, standard: Standard) -> String {
        var recommendations: [String] = []
        
        // Scale-based recommendations
        switch scale {
        case .small:
            recommendations.append("💡 Keep processes lean - avoid over-engineering")
            recommendations.append("💡 Empower team for quick decisions")
            recommendations.append("💡 Focus on delivering working results over documentation")
        case .medium:
            recommendations.append("💡 Balance formality with agility")
            recommendations.append("💡 Implement proper governance without bureaucracy")
            recommendations.append("💡 Plan for scalability and future growth")
        case .large:
            recommendations.append("💡 Establish strong PMO for coordination")
            recommendations.append("💡 Invest in stakeholder management and communication")
            recommendations.append("💡 Plan for complexity and interdependencies")
        }
        
        // Type-based recommendations
        switch type {
        case .software:
            recommendations.append("💡 Embrace DevOps practices for efficiency")
            recommendations.append("💡 Prioritize user feedback and iterative improvement")
        case .construction:
            recommendations.append("💡 Safety is paramount - never compromise")
            recommendations.append("💡 Maintain buffer for weather and supply delays")
        case .research:
            recommendations.append("💡 Document everything - reproducibility is key")
            recommendations.append("💡 Build in time for peer review and revisions")
        case .infrastructure:
            recommendations.append("💡 Engage public and stakeholders early and often")
            recommendations.append("💡 Plan for long-term operations from day one")
        case .marketing:
            recommendations.append("💡 Stay agile - be ready to pivot based on data")
            recommendations.append("💡 Test early and often before full launch")
        }
        
        // Standard-based recommendations
        switch standard.fileName {
        case "PMBOK":
            recommendations.append("💡 Review PMBOK's 10 knowledge areas for comprehensive coverage")
            recommendations.append("💡 Tailor processes to your project's specific needs")
        case "PRINCE2":
            recommendations.append("💡 Use PRINCE2's 7 themes as health check throughout")
            recommendations.append("💡 Ensure continued business justification at each stage")
        case "ISO21502":
            recommendations.append("💡 Align project objectives with organizational strategy")
            recommendations.append("💡 Foster stakeholder engagement at all levels")
        default:
            break
        }
        
        return """
        💡 RECOMMENDATIONS
        ───────────────────────────────────────
        \(recommendations.joined(separator: "\n"))
        
        ⚠️ Note: This is a tailored recommendation based on \(standard.title).
        For detailed guidance, consult the full \(standard.title) documentation.
        """
    }
}
