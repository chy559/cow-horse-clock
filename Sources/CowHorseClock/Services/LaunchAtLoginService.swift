import Foundation
import ServiceManagement

protocol LaunchAtLoginControlling {
    func setEnabled(_ enabled: Bool) throws
}

struct LaunchAtLoginService: LaunchAtLoginControlling {
    func setEnabled(_ enabled: Bool) throws {
        let service = SMAppService.mainApp

        if enabled {
            if service.status != .enabled {
                try service.register()
            }
        } else if service.status == .enabled || service.status == .requiresApproval {
            try service.unregister()
        }
    }
}
