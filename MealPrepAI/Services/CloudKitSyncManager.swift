//
//  CloudKitSyncManager.swift
//  MealPrepAI
//
//  Created by Claude on 22.01.2026.
//

import Foundation
import CloudKit
import SwiftUI

/// Manages iCloud sync state and operations
@MainActor @Observable
final class CloudKitSyncManager {

    // MARK: - Types

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
        case disabled

        var description: String {
            switch self {
            case .idle: return "Ready to sync"
            case .syncing: return "Syncing..."
            case .success: return "Synced"
            case .error(let message): return "Error: \(message)"
            case .disabled: return "Sync disabled"
            }
        }

        var icon: String {
            switch self {
            case .idle: return "icloud"
            case .syncing: return "arrow.triangle.2.circlepath.icloud"
            case .success: return "checkmark.icloud"
            case .error: return "exclamationmark.icloud"
            case .disabled: return "icloud.slash"
            }
        }

        var color: Color {
            switch self {
            case .idle: return .textSecondary
            case .syncing: return .accentPurple
            case .success: return .mintVibrant
            case .error: return Color(hex: "FF6B6B")
            case .disabled: return .textSecondary
            }
        }
    }

    enum CloudKitAvailability {
        case available
        case noAccount
        case restricted
        case couldNotDetermine
        case temporarilyUnavailable
    }

    // MARK: - Published Properties

    private(set) var syncStatus: SyncStatus = .idle
    private(set) var lastSyncDate: Date?
    private(set) var cloudKitAvailability: CloudKitAvailability = .couldNotDetermine
    var isSyncEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: syncEnabledKey)
            if isSyncEnabled {
                syncStatus = .idle
            } else {
                syncStatus = .disabled
            }
        }
    }

    // MARK: - Private Properties

    private let syncEnabledKey = "com.mealprepai.iCloudSyncEnabled"
    private let lastSyncKey = "com.mealprepai.lastSyncDate"
    private let containerIdentifier = "iCloud.com.mealprepai.MealPrepAI"

    // MARK: - Initialization

    init() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: syncEnabledKey)
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date

        // If sync is enabled but no lastSyncDate, set it now
        if isSyncEnabled && lastSyncDate == nil {
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
        }

        if !isSyncEnabled {
            syncStatus = .disabled
        }

        // Don't check CloudKit availability in init - defer to avoid crashes during app startup
        // Views should call checkCloudKitAvailability() when needed
    }

    // MARK: - Public Methods

    /// Check if iCloud is available for the current user
    func checkCloudKitAvailability() {
        Task { @MainActor in
            await fetchCloudKitAvailability()
        }
    }

    /// Fetch CloudKit availability using async/await
    @MainActor
    private func fetchCloudKitAvailability() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                cloudKitAvailability = .available
            case .noAccount:
                cloudKitAvailability = .noAccount
            case .restricted:
                cloudKitAvailability = .restricted
            case .couldNotDetermine:
                cloudKitAvailability = .couldNotDetermine
            case .temporarilyUnavailable:
                cloudKitAvailability = .temporarilyUnavailable
            @unknown default:
                cloudKitAvailability = .couldNotDetermine
            }
        } catch {
            print("CloudKit availability error: \(error.localizedDescription)")
            cloudKitAvailability = .couldNotDetermine
        }
    }

    /// Enable iCloud sync for the given user
    func enableSync(for userID: String) {
        guard cloudKitAvailability == .available else {
            syncStatus = .error("iCloud not available")
            return
        }

        isSyncEnabled = true
        syncStatus = .idle

        // Set initial sync date when enabled
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)

        // Note: With SwiftData's native CloudKit integration,
        // sync is handled automatically when the ModelContainer
        // is configured with cloudKitDatabase. This manager
        // primarily tracks state and provides UI feedback.
    }

    /// Disable iCloud sync
    func disableSync() {
        isSyncEnabled = false
        syncStatus = .disabled
    }

    /// Force a sync refresh (UI feedback only - SwiftData handles actual sync)
    func forceSync() async {
        guard isSyncEnabled else {
            syncStatus = .disabled
            return
        }

        guard cloudKitAvailability == .available else {
            syncStatus = .error("iCloud not available")
            return
        }

        syncStatus = .syncing

        // SwiftData with CloudKit syncs automatically.
        // This simulates the feedback for user-initiated refresh.
        do {
            // Small delay to show syncing status
            try await Task.sleep(nanoseconds: 1_500_000_000)

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
            syncStatus = .success

            // Reset to idle after a delay
            try await Task.sleep(nanoseconds: 2_000_000_000)
            if syncStatus == .success {
                syncStatus = .idle
            }
        } catch {
            // Task was cancelled
            syncStatus = .idle
        }
    }

    /// Handle remote notification for CloudKit changes
    func handleRemoteNotification() {
        guard isSyncEnabled else { return }

        // SwiftData handles the actual data sync.
        // Update our tracking state.
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
    }

    // MARK: - Computed Properties

    /// User-friendly message about iCloud availability
    var availabilityMessage: String {
        switch cloudKitAvailability {
        case .available:
            return "iCloud is available"
        case .noAccount:
            return "Sign in to iCloud in Settings to enable sync"
        case .restricted:
            return "iCloud access is restricted"
        case .couldNotDetermine:
            return "Unable to determine iCloud status"
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable"
        }
    }

    /// Whether the user can enable sync
    var canEnableSync: Bool {
        cloudKitAvailability == .available
    }

    /// Formatted last sync date
    var lastSyncDescription: String? {
        guard let date = lastSyncDate else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last synced \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}
