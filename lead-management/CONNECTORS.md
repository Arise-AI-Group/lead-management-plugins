# Connectors

## How tool references work

Plugin files use `~~category` as a placeholder for whatever tool the user connects in that category. For example, `~~CRM` might mean HubSpot, Notion, Salesforce, or any other CRM with an MCP server.

This plugin is **tool-agnostic** — it describes workflows in terms of categories (CRM, chat, email, etc.) rather than specific products. The `.mcp.json` pre-configures specific MCP servers, but any MCP server in that category works.

## Connectors for this plugin

| Category | Placeholder | Included servers | Other options |
|----------|-------------|-----------------|---------------|
| Calendar | `~~calendar` | Microsoft 365 | Google Calendar |
| Chat | `~~chat` | Slack | Microsoft Teams |
| CRM | `~~CRM` | HubSpot, Notion | Salesforce, Pipedrive, Close, Copper |
| Email | `~~email` | Microsoft 365 | Gmail, SendGrid |
| Conversation intelligence | `~~conversation intelligence` | Fireflies | Gong, Otter.ai, Chorus |
| E-signature | `~~e-signature` | — | DocuSign, PandaDoc, HelloSign |
| Payments | `~~payments` | — | Stripe, Square, QuickBooks |

> **Note:** E-signature and Payments servers are listed as alternatives because public MCP endpoints may not yet be available. Add them to `.mcp.json` as they become available.
