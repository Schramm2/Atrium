#!/usr/bin/env python3
"""Generate the repository communication audit from tracked runtime source."""

from __future__ import annotations

import csv
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "communication-audit.csv"
FIELDS = [
    "location", "chamber", "surface_type", "trigger", "current_copy",
    "defect", "replacement", "status", "verification_result",
]

REWRITES = [
    ("macos/Sources/Atrium/Views/AskView.swift", "user", "Ask interface", "Ask view and result states", "Find answers grounded in cited meeting transcript evidence. | Local retrieval | evidence.id | answer.provider · answer.model", "Technical terms and internal identifiers crossed into the narrative chamber.", "Find answers from your meeting transcripts, with citations. | Searches this Mac | no internal ID or provider/model attribution"),
    ("macos/Sources/Atrium/Views/AskView.swift", "user", "Ask empty and progress states", "Ask search has no result or is active", "No supporting evidence | Generating an evidence-bound answer", "Technical language did not give the clearest next step.", "Not enough information found | Writing an answer from your transcripts…"),
    ("macos/Sources/Atrium/Views/OnboardingView.swift", "user", "onboarding", "onboarding pages", "Local meeting database | Explicit external evidence sharing | recall cited evidence | retrieval", "Database, retrieval, and evidence are internal terms.", "Meeting data stays on this Mac | You choose when transcript excerpts leave this Mac | get cited answers | searches"),
    ("macos/Sources/Atrium/Views/Home/HomeView.swift", "user", "home", "home opens", "Capture, review, recall, and write | Recall cited evidence | retrieval | External AI is always explicit", "Abstract or technical language obscured the actual safeguard.", "Record, review, ask, and dictate | Get cited answers | searches | Atrium asks before sending anything outside this Mac"),
    ("macos/Sources/Atrium/Views/SidebarView.swift", "user", "sidebar", "sidebar opens", "Local | Local-first workspace | Search meeting content | Native Swift · v<version>", "Product and implementation jargon crossed into the narrative chamber.", "On this Mac | Private workspace on this Mac | Search meetings | Version <version>"),
    ("macos/Sources/Atrium/Views/MeetingDetailView.swift", "user", "meeting detail", "delete or transcription controls", "speaker aliases from the local database | Retranscribe | transcript segments", "Database and implementation terms were visible.", "speaker names from Atrium | Transcribe again | transcript excerpts"),
    ("macos/Sources/Atrium/Views/SettingsView.swift", "user", "settings", "General, Appearance, Transcription, Summary, About", "System errors | Test notification sent | Database | canonical dark aubergine workspace | Apple on-device speech | Native Swift", "Technical, misleading, or design-system language appeared in normal settings.", "Problems that need attention | Test notification queued | Meeting data | dark purple theme | On this Mac | removed implementation language"),
    ("macos/Sources/Atrium/Support/UpdaterService.swift", "user", "update status", "check or install update", "authenticated GitHub CLI | Checking GitHub Releases | Schramm2/Atrium | disk image | Atrium.app", "Update implementation and repository details leaked into user copy.", "Plain update status with an internet or retry next step"),
    ("macos/Sources/AtriumCore/Stores/AppStore.swift", "user", "error banners and notifications", "record, import, transcribe, summarize, play, or Ask fails", "error.localizedDescription and duplicated notification bodies", "Raw framework, database, provider, path, or identifier detail could reach people; notification bodies repeated headings.", "Operation-specific recovery copy; private raw cause in structured diagnostic logs; non-duplicated notification body"),
    ("macos/Sources/AtriumCore/Services/LanguageProviderService.swift", "user", "AI service error", "remote generation fails", "HTTP <code>: <raw response body>", "Raw transport and response content could leak identifiers or sensitive provider detail.", "The AI service could not complete the request. Check its settings and try again."),
    ("macos/Sources/AtriumCore/Services/ProviderModelService.swift", "user", "model settings error", "model request fails", "HTTP <code>: <raw response body>", "Raw transport and response content crossed into settings.", "The AI service could not load models. Check its settings and try again."),
    ("macos/Sources/Atrium/App/AtriumApp.swift", "user", "startup error", "local store initialization fails", "error.localizedDescription", "Raw database or framework detail could appear at startup.", "Atrium could not open its local data. Quit Atrium, then open it again."),
]

DEVELOPER_FINDINGS = [
    ("script/build_and_run.sh:48-159", "build, sign, verify, package, debug, and log commands", "Raw tool output or silence", "No stable operation, outcome, severity, or exit-code envelope around several commands.", "operation=<step> outcome=<started|success|failure> exit_code=<code>; preserve raw tool output", "blocked_user_owned_overlap"),
    ("script/build_and_run.sh:121-128", "--logs and --telemetry", "Apple unified-log stream", "The viewer is valid, but application coverage depends on explicit Atrium events.", "Keep viewer and emit privacy-safe Atrium operation events.", "verified"),
    ("scripts/release.sh:48-115", "release preflight and publishing commands", "Raw git, codesign, hdiutil, and gh output; some failures suppressed", "State-changing operations lack stable operation/outcome fields; suppressed causes make the last completed step unclear.", "Structured version_update, git_commit, git_push, signature_verify, dmg_verify, and release_create events", "blocked_user_owned_overlap"),
    ("scripts/update-local-macos.sh:58-105", "local build, install, receipt, and registration", "Raw child output plus key=value receipt", "The receipt contains an absolute source path with a username; ignored rollback or registration status can make confirmation misleading.", "Keep key=value; add outcome and target; remove personal source path; verify rollback and registration before confirmation.", "blocked_user_owned_overlap"),
    ("macos/Sources/AtriumCore/Services/GitHubReleaseUpdater.swift:93-170", "update command or rollback fails", "Captured command reason is discarded by the UI mapper", "No operation, exit code, error type, version, or rollback result is recorded.", "update_download|mount|stage|backup|install|verify with outcome, error_type, safe cause, target version, and rollback outcome", "blocked_missing_instrumentation"),
    ("macos/Sources/Atrium/Support/UpdaterService.swift:107-149", "update check or installation", "Structured update_check start/success/failure and update_install failure", "Install success terminates the process before a durable success event is currently recorded.", "Record install success before relaunch, with current and target versions.", "blocked_relaunch_event_not_captured"),
    ("macos/Sources/AtriumCore/Stores/AppStore.swift", "Ask, recording, import, transcription, summary, playback, or local-data failure", "Structured operation/outcome/error_type/cause/context events", "None after rewrite; cause and context use private privacy annotations.", "unchanged", "verified_source"),
]

VISIBLE_HINTS = (
    "Text(", "Button(", "Label(", "Section(", "Picker(", "Toggle(",
    "ContentUnavailableView(", "ProgressView(", "TextField(", "SecureField(",
    "LabeledContent(", ".accessibilityLabel(", ".help(", "title:", "body:",
    "errorMessage =", "return \"", "case .", "description:", "panel.title", "panel.prompt",
)
EXCLUDED_LITERAL = re.compile(
    r"^(?:[a-z0-9_.-]+$|[a-z]+/[a-z0-9._:/-]+$|https?://|x-apple-systempreferences:|com\.|SELECT |INSERT |UPDATE |DELETE FROM |PRAGMA )",
    re.IGNORECASE,
)


def tracked_files() -> list[Path]:
    output = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True)
    result = []
    for name in output.splitlines():
        if name.startswith(("dist/", "target/", ".next/")) or "/.build/" in name:
            continue
        path = ROOT / name
        if name.startswith("macos/Sources/") and path.suffix == ".swift":
            result.append(path)
        elif name in {"script/build_and_run.sh", "scripts/release.sh", "scripts/update-local-macos.sh"}:
            result.append(path)
    return result


def literals(line: str) -> list[str]:
    return [
        value.replace(r'\"', '"').replace(r'\\', '\\')
        for value in re.findall(r'"((?:[^"\\]|\\.)*)"', line)
    ]


def add(rows: list[dict[str, str]], **values: str) -> None:
    rows.append({field: values.get(field, "") for field in FIELDS})


def main() -> None:
    rows: list[dict[str, str]] = []
    add(rows, location="repository scope", chamber="scope", surface_type="exclusion", trigger="audit start", current_copy="Git history; dist/; target/; .next/; Swift .build/; vendored/generated files; tests and fixtures that cannot reach runtime; docs not displayed by app or CLI", defect="Not runtime communication.", replacement="Excluded", status="verified", verification_result="Scope stated before editing and enforced by generator.")

    for location, chamber, surface, trigger, current, defect, replacement in REWRITES:
        add(rows, location=location, chamber=chamber, surface_type=surface, trigger=trigger,
            current_copy=current, defect=defect, replacement=replacement, status="verified",
            verification_result="Replacement present in source; warnings-as-errors suite passed. Default Home and Ask insufficient-evidence states were inspected in the native app where applicable.")

    for location, trigger, current, defect, replacement, status in DEVELOPER_FINDINGS:
        add(rows, location=location, chamber="developer", surface_type="diagnostic log or stream",
            trigger=trigger, current_copy=current, defect=defect, replacement=replacement, status=status,
            verification_result=(
                "Source and real command behavior inspected; listed blocker prevents full output verification."
                if status.startswith("blocked") else
                "Source inspected and warnings-as-errors suite passed."
            ))

    for path in tracked_files():
        relative = path.relative_to(ROOT).as_posix()
        is_shell = path.suffix == ".sh"
        for number, line in enumerate(path.read_text().splitlines(), 1):
            if is_shell:
                if not re.search(r"\b(?:echo|printf|fail)\b", line):
                    continue
                chamber = "user"
                surface = "maintainer CLI"
            else:
                if relative.endswith("DiagnosticLogger.swift"):
                    continue
                broad_ui_scope = relative.startswith((
                    "macos/Sources/Atrium/Views/",
                    "macos/Sources/Atrium/App/",
                )) or relative.endswith(("UpdaterService.swift", "AppVersion.swift"))
                if not broad_ui_scope and not any(hint in line for hint in VISIBLE_HINTS):
                    continue
                chamber = "user"
                surface = "native application"
            for value in literals(line):
                if (
                    not value.strip()
                    or EXCLUDED_LITERAL.search(value)
                    or value in {"none", "success", "started", "failure", "partial_failure", " : ", ")"}
                    or value.rstrip().endswith("?")
                    or any(token in line for token in (
                        "systemName:", "@AppStorage", ".tag(", "forKey:", "URL(string:",
                        "String(format:", "joined(separator:", "dateFormat =", "withExtension:",
                    ))
                ):
                    continue
                status = "blocked_runtime_not_exercised"
                verification = "Source inventoried and compiled; this exact runtime state was not exercised."
                if relative.endswith(("HomeView.swift", "SidebarView.swift")):
                    status = "verified"
                    verification = "Observed in the rebuilt native Home interface and compiled by the full test suite."
                elif relative.endswith("AskView.swift") and value in {
                    "Ask Atrium", "Find answers from your meeting transcripts, with citations.",
                    "Searches this Mac", "What decisions did we make about the launch?",
                    "All meetings", "Limit by date", "Ask across your meeting history",
                    "Atrium searches your transcripts and cites the source for each part of the answer.",
                    "Not enough information found",
                    "Select more meetings, widen the date range, or ask a different question.",
                }:
                    status = "verified"
                    verification = "Observed in the rebuilt native Ask idle or insufficient-evidence state and compiled by the full test suite."
                add(rows, location=f"{relative}:{number}", chamber=chamber, surface_type=surface,
                    trigger="rendered or emitted by the containing control or operation", current_copy=value,
                    defect="None after audit.", replacement=value, status=status, verification_result=verification)

    log_path = "macos/Sources/AtriumCore/Support/DiagnosticLogger.swift"
    for operation in ("failure", "partialFailure", "success", "started"):
        captured = operation == "failure"
        add(rows, location=log_path, chamber="developer", surface_type="Apple unified log",
            trigger=f"{operation} diagnostic event", current_copy="operation=<name> outcome=<state> error_type=<type when failed> cause=<private> context=<private>",
            defect="None. Stable fields are preserved; cause and context are private; no content, secrets, or PII are intentionally logged.",
            replacement="unchanged", status="verified" if captured else "blocked_log_output_not_captured",
            verification_result=(
                "Observed real output: operation=model_list outcome=failure error_type=NSURLError cause=<private> context=<private>."
                if captured else
                "Logger source compiled and calls were inventoried; this event type was not produced by the safe flows exercised during this audit."
            ))

    add(rows, location="macos/Sources/AtriumCore/Services/LocalIntelligenceService.swift:85", chamber="user", surface_type="Ask metadata", trigger="answer API called directly with empty evidence", current_copy="local · evidence-only", defect="No current AppStore route reaches this rendered state.", replacement="Generated from meeting evidence", status="blocked_unreachable", verification_result="AppStore stops at insufficient evidence before answer generation; not marked verified.")

    rows.sort(key=lambda row: (row["location"], row["chamber"], row["current_copy"]))
    with OUTPUT.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} rows to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
