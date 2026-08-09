# Notive Privacy Policy

*Last updated: August 8, 2026*

## Our Privacy-First Commitment

Notive is built on the principle that your meeting data should remain private and under your control. This privacy policy explains how we handle data in our open-source meeting assistant.

## Data Processing Philosophy

### Local-First Processing
- **Meeting transcription**: Processed on your device with the local Whisper or Parakeet path.
- **Audio recordings**: Stored on your device unless you move or share them.
- **Meeting content**: Stored locally. Selected transcript content can be sent to a provider when you use an external AI feature.
- **AI summaries**: Generated locally with Built-in AI or local Ollama, or sent to the provider you configure when you request an external summary.
- **Ask Notive**: Retrieves evidence locally. External Ask requests require an in-session confirmation before the question and selected transcript evidence are sent.

### Your Data Ownership
- You own all meeting data, transcripts, and recordings
- Data is stored locally on your device
- No vendor lock-in - export your data anytime
- Complete control over data retention and deletion

## Usage Analytics

### What We Collect
Notive does not collect product analytics or send usage telemetry. The analytics interface in the application is a no-op compatibility layer.

### What We DON'T Collect
We never collect:
- ❌ Meeting content, transcripts, or recordings
- ❌ Personal information or identifiable data
- ❌ File names, meeting titles, or metadata
- ❌ Audio data or voice patterns
- ❌ Participant names or contact information
- ❌ LLM conversations or AI-generated content

## Third-Party Services

### LLM Providers (Optional)
If you choose to use external LLM providers:
- **Anthropic Claude**: Subject to Anthropic's privacy policy
- **Groq**: Subject to Groq's privacy policy
- **OpenAI and OpenRouter**: Subject to the selected provider's privacy policy
- **Custom OpenAI-compatible endpoints**: Subject to the endpoint operator's data practices
- **Built-in AI**: Processed on your device
- **Local Ollama**: Processed entirely on your device

## Your Privacy Rights

### Data Control
- **Access**: View all data stored locally on your device
- **Delete**: Delete saved meetings in the app. You can also remove the local app data with normal operating-system file controls.


## Data Security

### Local Security
- Local data uses the access controls of your operating system and user account. Notive does not add application-level encryption at rest.
- External AI features transmit only after the user selects or confirms the configured provider path
- Standard file system permissions protect your data

### Open Source Transparency
- Full source code available for security review
- Community-audited privacy implementations
- No hidden data collection or tracking

## Changes to This Policy

We will notify users of any material changes to this privacy policy through:
- Updates to this document in our GitHub repository
- Release notes for application updates
- In-app notifications for significant privacy changes

## Contact Us

For privacy-related questions or concerns:
- **GitHub Issues**: [Create an issue](https://github.com/Schramm2/ubundi-meet/issues)

## Open Source Commitment

As an open-source project under MIT license, you can:
- Review our complete privacy implementation
- Modify data handling to meet your requirements
- Deploy entirely on your own infrastructure
- Contribute to privacy improvements

---

*This privacy policy applies to Notive v0.5.0 and later versions. For enterprise deployments, additional privacy controls may be available.*
