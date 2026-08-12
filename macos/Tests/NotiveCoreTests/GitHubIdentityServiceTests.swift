import Foundation
import Testing
@testable import NotiveCore

@Suite("GitHub identity verification")
struct GitHubIdentityServiceTests {
    @Test("A missing GitHub CLI is reported")
    func cliMissing() {
        let service = GitHubIdentityService { _ in
            .init(exitCode: 127, standardOutput: "", standardError: "env: gh: No such file")
        }
        #expect(service.verify() == .cliMissing)
    }

    @Test("An unauthenticated CLI asks for sign-in")
    func notAuthenticated() {
        let service = service(user: nil, organizations: nil)
        #expect(service.verify() == .notAuthenticated)
    }

    @Test("A company organization member is verified case-insensitively")
    func verifiedMember() {
        let service = service(user: "matt\tMatthew Schramm", organizations: "ubundi\nother-org")
        let status = service.verify()
        guard case let .verified(identity, organization) = status else {
            Issue.record("Expected a verified identity, got \(status)")
            return
        }
        #expect(identity.login == "matt")
        #expect(identity.name == "Matthew Schramm")
        #expect(organization == "ubundi")
    }

    @Test("The First Motive organization also verifies")
    func firstMotiveMember() {
        let service = service(user: "matt\t", organizations: "First-Motive")
        guard case let .verified(identity, organization) = service.verify() else {
            Issue.record("Expected a verified identity")
            return
        }
        #expect(identity.name == nil)
        #expect(organization == "First-Motive")
    }

    @Test("Membership outside the company organizations is rejected")
    func notMember() {
        let service = service(user: "guest\tGuest", organizations: "some-org\nanother")
        guard case let .notMember(identity) = service.verify() else {
            Issue.record("Expected a rejected membership")
            return
        }
        #expect(identity.organizations == ["some-org", "another"])
    }

    @Test("A failed organization lookup is treated as no membership")
    func organizationLookupFails() {
        let service = service(user: "matt\tMatthew", organizations: nil)
        guard case let .notMember(identity) = service.verify() else {
            Issue.record("Expected a rejected membership")
            return
        }
        #expect(identity.organizations.isEmpty)
    }

    private func service(user: String?, organizations: String?) -> GitHubIdentityService {
        GitHubIdentityService { arguments in
            if arguments == ["gh", "--version"] {
                return .init(exitCode: 0, standardOutput: "gh version 2.0.0", standardError: "")
            }
            if arguments.starts(with: ["gh", "api", "user", "--jq"]) {
                guard let user else {
                    return .init(exitCode: 1, standardOutput: "", standardError: "not logged in")
                }
                return .init(exitCode: 0, standardOutput: user + "\n", standardError: "")
            }
            if arguments.starts(with: ["gh", "api", "user/orgs"]) {
                guard let organizations else {
                    return .init(exitCode: 1, standardOutput: "", standardError: "scope missing")
                }
                return .init(exitCode: 0, standardOutput: organizations + "\n", standardError: "")
            }
            return .init(exitCode: 1, standardOutput: "", standardError: "unexpected command")
        }
    }
}
