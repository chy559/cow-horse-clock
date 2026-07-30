import Foundation

let hoverLiftStyleTests: [TestCase] = [
    TestCase(name: "standard hover lift uses approved metrics") {
        try expectEqual(HoverLiftStyle.standard.lift, 5, "lift")
        try expectEqual(HoverLiftStyle.standard.scale, 1.015, "scale")
        try expectEqual(HoverLiftStyle.standard.shadowOffset, 5, "shadow")
    },
    TestCase(name: "compact hover lift uses dense layout metrics") {
        try expectEqual(HoverLiftStyle.compact.lift, 3, "lift")
        try expectEqual(HoverLiftStyle.compact.scale, 1.01, "scale")
        try expectEqual(HoverLiftStyle.compact.shadowOffset, 3, "shadow")
    }
]
