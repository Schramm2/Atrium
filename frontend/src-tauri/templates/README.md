# Meeting Summary Templates

This directory contains JSON definitions for meeting-summary generation.

## Template sources

The app loads a template in this order: a custom template, a bundled resource, then an embedded fallback. The embedded fallback includes `daily_standup.json` and `standard_meeting.json`. This directory also contains bundled examples for project sync, retrospective, sales and marketing client calls, and a psychiatric session.

## Custom templates

Users can add a custom JSON template to:

```text
~/Library/Application Support/Ubundi Meet/templates/
```

The legacy directory name keeps existing templates available after the Notive rename. A custom template overrides a bundled or embedded template with the same filename.

## Structure

Each template uses this JSON structure:

```json
{
  "name": "Template Name",
  "description": "Brief description of the template's purpose",
  "sections": [
    {
      "title": "Section Title",
      "instruction": "Instructions for the model",
      "format": "paragraph|list|string",
      "item_format": "Optional Markdown formatting hint"
    }
  ]
}
```

`name`, `description`, and `sections` are required. Each section requires `title`, `instruction`, and `format`; `item_format` and `example_item_format` are optional.

The Rust loader in `src/summary/templates/loader.rs` validates a template before it is used.
