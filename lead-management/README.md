# Lead Management Plugin

Capture leads, prep for discovery calls, follow up automatically, manage proposals, track contracts, and nurture prospects through the pipeline. Built for small businesses that need effective lead management without the overhead.

## Installation

```bash
claude plugins add lead-management-plugin/lead-management
```

## Quick Start

Once installed, the plugin works immediately. Start with any of these:

1. **Capture a lead:** `/lead-management:capture-lead` — then describe who you met
2. **Prep for a call:** `/lead-management:prep-call` — tell me the company and meeting time
3. **Draft a follow-up:** `/lead-management:draft-followup` — paste your call notes
4. **Review your pipeline:** `/lead-management:pipeline-review` — get a full snapshot

Or just start talking about your leads and deals — skills activate automatically when relevant.

## Skills

| Skill | What It Does | Activates When |
|-------|-------------|----------------|
| **lead-capture** | Multi-source lead capture with AI scoring (Hot/Warm/Cold) | New lead, contact, form submission, event capture |
| **discovery-prep** | Pre-meeting research, email sequence, questionnaire, meeting brief | Upcoming call, meeting prep, discovery |
| **post-call-followup** | Transcript analysis, follow-up email drafting, team routing | Call notes, transcript, follow-up |
| **proposal-assembly** | Template-based proposal generation with review routing | Proposal, quote, SOW, pricing |
| **nurture-sequences** | Stage-based drip campaigns (Day 3/7/14/30/60+) with exit conditions | Nurture, drip, cold leads, re-engagement |
| **contract-management** | E-signature sending, event tracking, unopened contract alerts | Contract, signing, DocuSign, envelope |
| **invoice-tracking** | Invoice generation, payment reminders (Day 7/14/30), revenue tracking | Invoice, payment, billing, revenue |
| **content-engine** | Meeting transcript to LinkedIn, tweet, newsletter, video script | Content, repurpose, LinkedIn, social media |

## Commands

| Command | Purpose |
|---------|---------|
| `/lead-management:capture-lead` | Quick-capture a lead with AI scoring and routing |
| `/lead-management:pipeline-review` | Pipeline health, stalled deals, conversion metrics, action items |
| `/lead-management:prep-call` | Meeting brief, company research, agenda, discovery questions |
| `/lead-management:draft-followup` | Post-call follow-up email and internal team summary |
| `/lead-management:send-proposal` | Assemble proposal from discovery data, route for review |
| `/lead-management:nurture-status` | Nurture pipeline overview, due actions, re-engagement signals |

## Connectors

Connect your tools for the full experience, or use standalone with web search and manual input.

| Category | Placeholder | Pre-configured | Other Options |
|----------|-------------|---------------|---------------|
| CRM | `~~CRM` | HubSpot, Notion | Salesforce, Pipedrive, Close |
| Chat | `~~chat` | Slack | Microsoft Teams |
| Email | `~~email` | Microsoft 365 | Gmail, SendGrid |
| Calendar | `~~calendar` | Microsoft 365 | Google Calendar |
| Transcription | `~~conversation intelligence` | Fireflies | Gong, Otter.ai |
| E-signature | `~~e-signature` | — | DocuSign, PandaDoc |
| Payments | `~~payments` | — | Stripe, Square |

Edit `.mcp.json` to swap connectors for your tool stack. See [CONNECTORS.md](./CONNECTORS.md) for details.

## Configuration

Create `lead-management/.claude/settings.local.json` to personalize:

```json
{
  "company_name": "Your Company",
  "team_members": ["Name 1", "Name 2"],
  "services": ["Service A", "Service B"],
  "pricing_tiers": ["Starter: $X", "Growth: $Y", "Enterprise: $Z"],
  "brand_voice": "Professional but approachable",
  "default_payment_terms": "Net 30",
  "proposal_validity": "30 days",
  "nurture_cadence": "standard",
  "channels": {
    "leads": "#leads",
    "proposals": "#proposals",
    "revenue": "#revenue"
  }
}
```

The plugin will prompt for this information interactively if not pre-configured.

## Pipeline Stages

The plugin tracks leads through a standard pipeline:

```
New Lead → Contacted → Discovery Scheduled → Discovery Complete
    → Proposal Sent → Contract Sent → Contract Signed → Paid
```

Each skill and command maps to one or more stages, ensuring no lead falls through the cracks.

## License

Apache-2.0
