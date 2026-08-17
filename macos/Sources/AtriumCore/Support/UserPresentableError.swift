import Foundation

/// An error whose `errorDescription` is written for the person using Atrium.
///
/// The banner can show this text beside the action that failed, and
/// `diagnosticCode` gives the log a stable label that holds no user content.
public protocol UserPresentableError: LocalizedError {
    var diagnosticCode: String { get }
}

extension Error {
    /// The sentence Atrium may show beside a failed action, when there is one.
    var presentableReason: String? {
        guard let presentable = self as? any UserPresentableError else { return nil }
        return presentable.errorDescription
    }

    /// A short label for the log that holds no user content.
    var diagnosticCode: String {
        if let presentable = self as? any UserPresentableError {
            return presentable.diagnosticCode
        }
        let error = self as NSError
        return "\(error.domain)#\(error.code)"
    }
}
