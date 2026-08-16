import Testing
@testable import AtriumCore

@Suite("GitHub command execution")
struct GitHubCommandExecutorTests {
    @Test("Commands return captured output")
    func capturesOutput() async {
        let result = await GitHubCommandExecutor.execute(["printf", "hello"])

        #expect(result.succeeded)
        #expect(result.standardOutput == "hello")
    }

    @Test("Cancellation terminates the running command")
    func cancellation() async {
        let task = Task {
            await GitHubCommandExecutor.execute(["sh", "-c", "sleep 5"])
        }
        await Task.yield()
        task.cancel()

        let result = await task.value
        #expect(!result.succeeded)
    }
}
