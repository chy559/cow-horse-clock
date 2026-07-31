import Combine
import Foundation

enum AppRoute: Equatable {
    case dashboard
    case ledger
    case settings
    case calendar
    case focus
    case milestones
}

enum AppModelError: Error, Equatable {
    case invalidSettings([SettingsValidationError])
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var snapshot: EarningsSnapshot
    @Published private(set) var settings: WorkSettings
    @Published var route: AppRoute
    @Published private(set) var ledgerRevision = UUID()
    @Published private(set) var lastErrorMessage: String?

    let ledgerStore: LedgerStore
    private let settingsStore: SettingsStore
    private let launchAtLoginService: LaunchAtLoginControlling
    private let calendar: Calendar
    private let now: () -> Date
    private var ticker: AnyCancellable?

    init(
        settingsStore: SettingsStore = SettingsStore(),
        ledgerStore: LedgerStore? = nil,
        launchAtLoginService: LaunchAtLoginControlling = LaunchAtLoginService(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init,
        startsTimer: Bool = true
    ) {
        let loadedSettings = settingsStore.load()
        let resolvedLedgerStore =
            ledgerStore ?? LedgerStore(calendar: calendar)

        self.settingsStore = settingsStore
        self.ledgerStore = resolvedLedgerStore
        self.launchAtLoginService = launchAtLoginService
        self.calendar = calendar
        self.now = now
        self.settings = loadedSettings
        self.route =
            loadedSettings.trackingStartDate == nil ? .settings : .dashboard
        self.snapshot = .zero

        refresh(at: now())

        if startsTimer {
            ticker = Timer.publish(every: 0.25, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] date in
                    Task { @MainActor in
                        self?.refresh(at: date)
                    }
                }
        }
    }

    func refresh(at date: Date? = nil) {
        let currentDate = date ?? now()
        do {
            try ledgerStore.reconcile(settings: settings, through: currentDate)
            let startOfToday = calendar.startOfDay(for: currentDate)
            if settings.lastReconciledDate != startOfToday {
                settings.lastReconciledDate = startOfToday
                try settingsStore.save(settings)
            }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "账本暂时无法更新"
        }

        snapshot = EarningsEngine.snapshot(
            at: currentDate,
            settings: settings,
            isWorkday: ledgerStore.isWorkday(currentDate, settings: settings),
            calendar: calendar
        )
        ledgerRevision = UUID()
    }

    func completeSetup(_ draft: WorkSettings, at date: Date? = nil) throws {
        let currentDate = date ?? now()
        var configured = draft
        configured.trackingStartDate = calendar.startOfDay(for: currentDate)
        configured.lastReconciledDate = calendar.startOfDay(for: currentDate)
        try saveSettings(configured, at: currentDate)
        route = .dashboard
    }

    func saveSettings(_ draft: WorkSettings, at date: Date? = nil) throws {
        let errors = draft.validationErrors
        guard errors.isEmpty else {
            throw AppModelError.invalidSettings(errors)
        }

        let currentDate = date ?? now()
        try ledgerStore.reconcile(settings: settings, through: currentDate)

        var configured = draft
        if configured.trackingStartDate == nil {
            configured.trackingStartDate = settings.trackingStartDate
        }
        if configured.lastReconciledDate == nil {
            configured.lastReconciledDate = settings.lastReconciledDate
        }

        if configured.launchAtLogin != settings.launchAtLogin {
            try launchAtLoginService.setEnabled(configured.launchAtLogin)
        }

        try settingsStore.save(configured)
        settings = configured
        refresh(at: currentDate)
    }

    func setOverride(_ kind: CalendarOverrideKind?, on date: Date) throws {
        try ledgerStore.setOverride(kind, on: date)
        refresh()
    }

    func monthSummary(containing date: Date) -> MonthSummary {
        ledgerStore.monthSummary(containing: date)
    }

    var historicalTotalCents: Int64 {
        ledgerStore.historicalTotalCents()
    }
}
