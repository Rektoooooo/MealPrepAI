//
//  CloudKitSyncManager.swift
//  MealPrepAI
//
//  Created by Claude on 22.01.2026.
//

import Foundation
import CloudKit
import CoreData
import SwiftUI

/// Manages iCloud sync state by listening to real CloudKit sync events
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
            case .disabled: return "iCloud unavailable"
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

    // MARK: - Properties

    private(set) var syncStatus: SyncStatus = .idle
    private(set) var lastSyncDate: Date?
    private(set) var cloudKitAvailability: CloudKitAvailability = .couldNotDetermine

    // MARK: - Private Properties

    private let lastSyncKey = "com.mealprepai.lastSyncDate"
    private let containerIdentifier = "iCloud.com.mealprepai.MealPrepAI"
    private var eventObserver: NSObjectProtocol?

    // MARK: - Initialization

    init() {
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
        startMonitoring()
    }

    // Note: No deinit — callers must invoke stopMonitoring() before releasing
    // this object. deinit is nonisolated and cannot safely access @MainActor
    // state; using MainActor.assumeIsolated in deinit crashes when dealloc
    // happens on a background thread.

    // MARK: - Sync Event Monitoring

    private func startMonitoring() {
        eventObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSPersistentCloudKitContainer.eventChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleSyncEvent(notification)
            }
        }
    }

    /// Call this explicitly before releasing the object to clean up the
    /// notification observer. Safe to call from any isolation context.
    func stopMonitoring() {
        if let observer = eventObserver {
            NotificationCenter.default.removeObserver(observer)
            eventObserver = nil
        }
    }

    private func handleSyncEvent(_ notification: Notification) {
        // NSPersistentCloudKitContainer.Event is available via the userInfo
        guard let event = notification.userInfo?["event"] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        if event.endDate == nil {
            // Event started
            syncStatus = .syncing
        } else if event.succeeded {
            // Event finished successfully
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
            syncStatus = .success
        } else if let error = event.error {
            syncStatus = .error(error.localizedDescription)
        }
    }

    // MARK: - Public Methods

    /// Check if iCloud is available for the current user
    func checkCloudKitAvailability() {
        Task { @MainActor in
            await fetchCloudKitAvailability()
            if cloudKitAvailability != .available {
                syncStatus = .disabled
            } else if syncStatus == .disabled {
                syncStatus = .idle
            }
        }
    }

    /// Handle remote notification for CloudKit changes
    func handleRemoteNotification() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
    }

    // MARK: - Private Methods

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
            #if DEBUG
            print("CloudKit availability error: \(error.localizedDescription)")
            #endif
            cloudKitAvailability = .couldNotDetermine
        }
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

    /// Formatted last sync date
    var lastSyncDescription: String? {
        guard let date = lastSyncDate else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last synced \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    // MARK: - Delete CloudKit Zone

    /// Delete the SwiftData CloudKit zone to remove all synced data
    func deleteCloudKitZone() async {
        let container = CKContainer(identifier: containerIdentifier)
        let privateDatabase = container.privateCloudDatabase

        let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)

        #if DEBUG
        print("[CloudKit] Deleting CloudKit zone: \(zoneID.zoneName)...")
        #endif

        do {
            try await privateDatabase.deleteRecordZone(withID: zoneID)
            #if DEBUG
            print("[CloudKit] Successfully deleted CloudKit zone")
            #endif
        } catch {
            if let ckError = error as? CKError {
                switch ckError.code {
                case .zoneNotFound:
                    #if DEBUG
                    print("[CloudKit] Zone not found (already deleted or never created)")
                    #endif
                case .userDeletedZone:
                    #if DEBUG
                    print("[CloudKit] Zone was already deleted by user")
                    #endif
                default:
                    #if DEBUG
                    print("[CloudKit] Error deleting zone: \(ckError.localizedDescription)")
                    #endif
                }
            } else {
                #if DEBUG
                print("[CloudKit] Error deleting zone: \(error.localizedDescription)")
                #endif
            }
        }
    }
}
