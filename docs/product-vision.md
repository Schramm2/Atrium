# Product vision

Notive is the private company intelligence workspace for Ubundi and First Motive. It connects conversations, company knowledge, people, and AI agents in one internal application.

Each person has a private workspace on their Mac. The person chooses which meetings, notes, and other work become part of the shared Company Hub. People and agents can then work from the same approved company context.

> Capture work locally. Share context with intent. Give people and agents the same trusted company memory.

This document describes the product direction. It does not approve a shared-service architecture or change the local-first boundaries in [System architecture](architecture.md).

## Product promise

Notive gives the company one trusted place to:

- capture conversations and decisions;
- build shared working memory;
- understand what people and agents work on;
- direct company agents and review their output;
- find knowledge across private and shared scopes; and
- see important company activity and its source.

Notive is more than a meeting assistant, intranet, chat tool, or agent dashboard. It is the operating workspace where company conversations become useful memory and that memory supports work by people and agents.

The long-term product category is a **company intelligence workspace**. A **company intelligence operating system** describes the larger ambition, but it must not imply that Notive replaces every specialist company system.

## Two explicit scopes

Notive has two scopes. The interface and service boundaries must keep them clear.

### My Workspace

My Workspace is private and local. It includes meeting capture, transcription, notes, summaries, Dictation, Ask, and local search. This data stays on the person's Mac unless the owner takes an explicit share action.

### Company Hub

Company Hub contains only company-visible information. It includes items that owners chose to share, approved company knowledge, company agents, people, agent threads, search results, and activity.

Nothing crosses from My Workspace to Company Hub by default. Sharing is a per-item choice. The owner must be able to see the sharing state and withdraw a shared item.

## The company intelligence loop

The central product loop is:

```text
Conversation -> knowledge -> company memory -> agent work -> visible outcomes
```

1. Meetings capture what people discussed and decided.
2. A person reviews the local record and chooses what to share.
3. Shared Context makes the approved material part of the company's working memory.
4. People and agents use that memory to answer questions and perform work.
5. Agent runs, shared outputs, decisions, and other important changes appear in Activity.
6. Search helps a person find private and shared knowledge without exposing private material to other users.

This loop must preserve provenance. A shared fact, answer, or agent output should remain connected to its source where possible.

## Product areas

### Company

Company is the current company view. It shows what Ubundi and First Motive shared, decided, and ran. It combines important measures, recent shared work, agent state, and open activity without becoming a general analytics dashboard.

### Agents

Agents are a visible part of the company workforce. Each agent has a name, role, purpose, status, runs, company-visible threads, and reviewable output. An agent must not appear to have access or authority that it does not have.

### Shared Context

Shared Context is the company's working memory. It contains approved meetings, notes, briefs, and agent output. Every item shows its source, owner or contributor, and sharing time.

### People

People shows the human and agent organisation. It helps the team understand roles, company membership, current focus, and availability. Agents remain clearly marked so the interface does not present them as people.

### Search

Search is one retrieval experience across the user's local workspace and the shared company scope. Results must show their source and scope. A local result can be shown to its owner without making that result visible to the company.

### Activity

Activity is a company-visible history of important actions and outputs. It shows who or what acted, what happened, when it happened, and relevant source detail. It supports awareness and review; it is not employee surveillance.

## People and agents use the same context with different authority

People and agents can use the same shared company memory, but they do not have the same identity or authority.

- A person acts through their own user account.
- An agent acting for a person must not retrieve more information than that person can access.
- A company agent with independent duties needs its own explicit identity, access policy, and audit history.
- A shared service credential must never bypass user or agent access rules.
- Agent output must identify the agent and the source context used to produce it.

## Future Grounding connection

Notive is expected to connect to **Grounding**, the company knowledge system in the `grounding_ai` repository. The current local working copy is at:

```text
/Users/matthew-schramm-ubundi/Workspace.nosync/Personal/grounding_ai
```

Grounding ingests company sources such as Slack, Google Drive, GitHub, Gmail, web pages, local documents, and meeting notes. It retrieves cited knowledge under per-user access control. In the combined product direction:

- Notive is the native personal and company operating workspace.
- Grounding is the installation-owned company knowledge and retrieval system.
- Notive connects to Grounding through the Model Context Protocol (MCP) when Grounding's MCP service is implemented and approved.
- Each Notive user connects with their own Grounding user account.
- Every MCP request carries an authenticated Grounding principal. Grounding remains responsible for access checks, citations, and query audit.
- Notive and its agents show only records that Grounding permits that principal to retrieve.
- Notive stores any local account secret or token in Keychain and does not write it to the Notive database, logs, or shared context.

The Grounding MCP service does not exist yet. Grounding tracks it as a deferred, approval-gated phase that depends on its access-control and audit requirements. Notive must not simulate the connection with broad API credentials or weaken either product's trust boundary.

Before implementation, an accepted architecture decision must define:

- the sign-in and account-linking flow;
- MCP transport and session authentication;
- how a Notive user maps to a Grounding principal;
- whether company agents use a user principal or a separate agent principal;
- token storage, renewal, revocation, and sign-out;
- query and agent-run audit behavior;
- citation and source rendering in Notive;
- offline, unavailable, and partial-result behavior; and
- the separate write path for sharing or withdrawing meeting content.

The MCP retrieval connection must not silently turn every local meeting into company knowledge. Publishing a meeting from Notive to the Company Hub or Grounding remains a separate, explicit owner action.

## Product principles

### Local by default

Capture and private thinking stay on the Mac. A connected company service does not change the default scope.

### Share with intent

The owner chooses what enters the shared company scope. The product shows the choice before and after sharing.

### Access follows identity

Every shared read and write has an accountable person or agent identity. Access rules apply at retrieval time and fail closed.

### Sources stay visible

Search answers, shared knowledge, and agent output keep citations or source links where possible. Notive must help a person verify why an answer exists.

### Agents are observable

The team can see an agent's role, current state, runs, company-visible conversation, and output. Automation must not become invisible company activity.

### Activity is for coordination

Activity helps the team understand work and changes. It must not become passive monitoring of private work or personal behaviour.

## Current implementation state

The native My Workspace features are implemented and use local data.

The Company Hub interface and its service contract are implemented. The default service is disconnected, so its reads are empty and its writes fail safely. No Company Hub screen currently sends local data to a shared service.

Grounding already has company-source ingestion, cited retrieval, user identity, and per-user access controls in its proof of concept. Its MCP service and the Notive integration are not implemented.

The expected delivery order is:

1. Keep the local and shared scope boundary explicit in the product.
2. Define and approve the shared Company Hub architecture.
3. Connect shared items, people, agents, search, and activity through `CompanyHubProviding`.
4. Complete and approve Grounding's MCP service and identity mapping.
5. Connect Notive to Grounding with each user's account and enforce cited, audited retrieval.
6. Add agent workflows only after their identities, access, review, and audit rules are clear.

## Success

Notive succeeds when:

- important conversations strengthen company memory;
- people can find trusted knowledge without asking who remembers it;
- agents work from approved context and produce reviewable output;
- the team can understand what the company knows, what it is doing, and why; and
- private work remains private until its owner chooses otherwise.
