# Project Documentation Plan - HISP Mobile Tracker

The goal is to provide a comprehensive and up-to-date documentation suite for the **HISP Mobile Tracker** project. While existing documentation is excellent, it lacks coverage for recent features (`audit_log`, `onboarding`) and a non-technical User Guide.

## User Review Required

> [!IMPORTANT]
> This plan involves updating core documentation files and creating a new User Guide. Please verify if the proposed structure for the User Guide meets your expectations.

## Proposed Changes

### Documentation Updates

#### [MODIFY] [10-features.md](file:///home/biruk/hisp_mobile_trucker/docs/10-features.md)
- Add documentation for the `audit_log` feature (`lib/features/audit_log`), explaining the `showCellHistorySheet` functionality and its dual-source (local/server) audit capability.
- Add documentation for the `onboarding` feature (`lib/features/onboarding`), explaining the one-time walkthrough flow.

#### [MODIFY] [ARCHITECTURE_ANALYSIS.md](file:///home/biruk/hisp_mobile_trucker/ARCHITECTURE_ANALYSIS.md)
- Update the folder walkthrough to include `audit_log` and `onboarding`.
- Mention `AuditLogStore` and `OnboardingService` in the core infrastructure analysis.

#### [NEW] [17-user-guide.md](file:///home/biruk/hisp_mobile_trucker/docs/17-user-guide.md)
- Create a non-technical guide for end-users.
- Sections:
    - **Welcome**: Onboarding and first steps.
    - **Getting Started**: Server URL configuration and Login.
    - **Data Collection**: The "Capture" workflow (Org Unit → Dataset → Section → Period).
    - **Offline-First**: How drafts and completion work.
    - **Syncing**: Manual vs Automatic sync.
    - **Dashboards**: Viewing visualizations.
    - **History**: How to check change history (Audit Log) for data cells.

#### [MODIFY] [README.md](file:///home/biruk/hisp_mobile_trucker/README.md)
- Add "Audit Logs" and "Onboarding" to the feature list.
- Add a link to the new **User Guide**.

### Synthesis

#### [NEW] [PROJECT_OVERVIEW.artifact.md](file:///home/biruk/hisp_mobile_trucker/.artifacts/e201a0c2-b1a6-4bef-8355-b0d78dab7d40/PROJECT_OVERVIEW.artifact.md)
- Create a summarized "Executive Summary" artifact that synthesizes the most important technical and functional aspects of the project.

## Verification Plan

### Manual Verification
- Review all updated and new markdown files for accuracy, broken links, and formatting.
- Ensure all mentioned features are correctly described based on the current codebase.
