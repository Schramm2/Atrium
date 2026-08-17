import Foundation
import OSLog

public enum DiagnosticLogger {
    private static let logger = Logger(
        subsystem: "com.ubundi.meet",
        category: "diagnostics"
    )

    public static func failure(
        operation: String,
        error: Error,
        context: String = "none"
    ) {
        let errorType = String(reflecting: type(of: error))
        let code = error.diagnosticCode
        let cause = error.localizedDescription
        logger.error(
            "operation=\(operation, privacy: .public) outcome=failure error_type=\(errorType, privacy: .public) code=\(code, privacy: .public) cause=\(cause, privacy: .private) context=\(context, privacy: .private)"
        )
    }

    public static func partialFailure(
        operation: String,
        error: Error,
        context: String = "none"
    ) {
        let errorType = String(reflecting: type(of: error))
        let code = error.diagnosticCode
        let cause = error.localizedDescription
        logger.warning(
            "operation=\(operation, privacy: .public) outcome=partial_failure error_type=\(errorType, privacy: .public) code=\(code, privacy: .public) cause=\(cause, privacy: .private) context=\(context, privacy: .private)"
        )
    }

    public static func success(operation: String, context: String = "none") {
        logger.info(
            "operation=\(operation, privacy: .public) outcome=success context=\(context, privacy: .private)"
        )
    }

    public static func started(operation: String, context: String = "none") {
        logger.info(
            "operation=\(operation, privacy: .public) outcome=started context=\(context, privacy: .private)"
        )
    }

    /// Records how far a long operation has come, so an interrupted run can be
    /// read from the log without private data.
    public static func progress(operation: String, measure: String) {
        logger.info(
            "operation=\(operation, privacy: .public) outcome=progress measure=\(measure, privacy: .public)"
        )
    }
}
