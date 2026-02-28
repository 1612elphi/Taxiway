import Testing
import Foundation
@testable import TaxiwayCore

@Suite("DefaultRegistry")
struct DefaultRegistryTests {

    @Test("Default registry contains all 43 check types")
    func registryContainsAllCheckTypes() {
        let registry = CheckRegistry.default
        #expect(registry.registeredTypeIDs.count >= 43)
    }

    @Test("Default registry contains every expected typeID")
    func registryContainsExpectedTypeIDs() {
        let registry = CheckRegistry.default
        let ids = registry.registeredTypeIDs

        // File
        #expect(ids.contains("file.size.max"))
        #expect(ids.contains("file.size.min"))
        #expect(ids.contains("file.encryption"))
        #expect(ids.contains("file.interactive_elements"))
        #expect(ids.contains("file.metadata.matches"))
        #expect(ids.contains("file.metadata.present"))

        // Colour
        #expect(ids.contains("colour.space_used"))
        #expect(ids.contains("colour.registration"))
        #expect(ids.contains("colour.spot_count"))
        #expect(ids.contains("colour.spot_used"))

        // Fonts
        #expect(ids.contains("fonts.not_embedded"))
        #expect(ids.contains("fonts.size"))
        #expect(ids.contains("fonts.type"))

        // Images
        #expect(ids.contains("images.alpha"))
        #expect(ids.contains("images.blend_mode"))
        #expect(ids.contains("images.c2pa"))
        #expect(ids.contains("images.genai"))
        #expect(ids.contains("images.icc_missing"))
        #expect(ids.contains("images.colour_mode"))
        #expect(ids.contains("images.scaled"))
        #expect(ids.contains("images.scaled_non_proportional"))
        #expect(ids.contains("images.type"))
        #expect(ids.contains("images.resolution_above"))
        #expect(ids.contains("images.resolution_below"))
        #expect(ids.contains("images.resolution_range"))

        // Lines
        #expect(ids.contains("lines.stroke_below"))
        #expect(ids.contains("lines.zero_width"))

        // Marks
        #expect(ids.contains("marks.bleed_greater_than"))
        #expect(ids.contains("marks.bleed_less_than"))
        #expect(ids.contains("marks.bleed_non_uniform"))
        #expect(ids.contains("marks.bleed_nonzero"))
        #expect(ids.contains("marks.bleed_zero"))
        #expect(ids.contains("marks.trim_box_set"))

        // Pages
        #expect(ids.contains("pages.mixed_sizes"))
        #expect(ids.contains("pages.count"))
        #expect(ids.contains("pages.rotation"))
        #expect(ids.contains("pages.size"))

        // PDF
        #expect(ids.contains("pdf.annotations"))
        #expect(ids.contains("pdf.layers"))
        #expect(ids.contains("pdf.linearized"))
        #expect(ids.contains("pdf.conformance"))
        #expect(ids.contains("pdf.version"))
        #expect(ids.contains("pdf.tagged"))
    }

    @Test("Every PDF/X-1a entry can be instantiated from default registry")
    func pdfX1aEntriesInstantiable() throws {
        let registry = CheckRegistry.default
        for entry in PreflightProfile.pdfX1a.checks {
            let check = try registry.instantiate(from: entry)
            #expect(check.id != UUID())
        }
    }

    @Test("Every PDF/X-4 entry can be instantiated from default registry")
    func pdfX4EntriesInstantiable() throws {
        let registry = CheckRegistry.default
        for entry in PreflightProfile.pdfX4.checks {
            let check = try registry.instantiate(from: entry)
            #expect(check.id != UUID())
        }
    }

    @Test("Every Screen/Digital entry can be instantiated from default registry")
    func screenDigitalEntriesInstantiable() throws {
        let registry = CheckRegistry.default
        for entry in PreflightProfile.screenDigital.checks {
            let check = try registry.instantiate(from: entry)
            #expect(check.id != UUID())
        }
    }

    @Test("Every Loose entry can be instantiated from default registry")
    func looseEntriesInstantiable() throws {
        let registry = CheckRegistry.default
        for entry in PreflightProfile.loose.checks {
            let check = try registry.instantiate(from: entry)
            #expect(check.id != UUID())
        }
    }

    @Test("All built-in profile entries can be instantiated from default registry")
    func allBuiltInEntriesInstantiable() throws {
        let registry = CheckRegistry.default
        for profile in PreflightProfile.allBuiltIn {
            for entry in profile.checks {
                #expect(throws: Never.self) {
                    _ = try registry.instantiate(from: entry)
                }
            }
        }
    }
}
