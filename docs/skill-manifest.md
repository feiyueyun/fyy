# Skill Manifest

Skill Manifest is an open standard for defining what an AI digital employee can do. It describes a skill's capabilities, inputs, outputs, pricing, and permissions in a structured `skill.json` file.

## Overview

Every AI employee skill in FYY is described by a Skill Manifest. Think of it as a job description for an AI employee — it tells the platform (and other agents) exactly what this skill does, what it needs, and what it delivers.

```json
{
  "name": "listing-generator",
  "version": "1.0.0",
  "description": "Generates optimized multilingual product listings for e-commerce platforms",
  "type": "mcp",
  "author": "FYY Team",
  "license": "MIT",
  "category": "ecommerce",
  "tags": ["listing", "translation", "seo", "ecommerce"],
  "inputs": {
    "product_description": { "type": "string", "required": true },
    "source_language": { "type": "string", "default": "en" },
    "target_languages": { "type": "array", "items": "string", "required": true },
    "platform": { "type": "string", "enum": ["amazon", "shopify", "ebay"] }
  },
  "outputs": {
    "listings": {
      "type": "array",
      "description": "Optimized product listings, one per target language"
    }
  },
  "pricing": {
    "model": "per_output",
    "unit": "listing",
    "amount": 0.50,
    "currency": "USD"
  },
  "grants": {
    "required": ["network.outbound"],
    "optional": ["storage.read"]
  }
}
```

## Key Fields

### Identity

| Field | Type | Required | Description |
|-------|------|----------|------------|
| `name` | string | Yes | Unique skill identifier (kebab-case) |
| `version` | string | Yes | Semantic version (e.g., "1.0.0") |
| `description` | string | Yes | Human-readable description of what the skill does |
| `author` | string | Yes | Skill author or organization |
| `license` | string | No | License identifier (e.g., "MIT", "proprietary") |

### Classification

| Field | Type | Required | Description |
|-------|------|----------|------------|
| `category` | string | No | Primary category (e.g., "ecommerce", "finance", "customer-service") |
| `tags` | string[] | No | Searchable tags for skill discovery |
| `type` | string | Yes | Skill type: `mcp`, `grpc`, `claw` |

### Inputs and Outputs

Define what the skill needs and what it delivers:

```json
{
  "inputs": {
    "field_name": {
      "type": "string | number | boolean | array | object",
      "required": true,
      "default": "optional default value",
      "description": "What this input is for"
    }
  },
  "outputs": {
    "field_name": {
      "type": "string | number | array | object",
      "description": "What this output contains"
    }
  }
}
```

### Pricing

Define how the skill is priced:

```json
{
  "pricing": {
    "model": "per_output",
    "unit": "report",
    "amount": 2.00,
    "currency": "USD",
    "free_tier": {
      "calls_per_day": 10
    }
  }
}
```

| Pricing Model | Description |
|--------------|------------|
| `per_call` | Fixed price per invocation |
| `per_output` | Price per delivered result |

### Grants (Permissions)

Declare what permissions the skill needs:

```json
{
  "grants": {
    "required": ["network.outbound", "storage.read"],
    "optional": ["storage.write"]
  }
}
```

The FYY Grants system enforces these permissions at runtime. Users approve required grants during installation and can opt into optional grants.

## Recommended Categories

| Category | Description | Example Skills |
|----------|------------|---------------|
| `ecommerce` | E-commerce operations | Listing generator, pricing optimizer |
| `finance` | Financial analysis and reporting | Report generator, bookkeeping |
| `customer-service` | Customer communication | Email responder, chat support |
| `compliance` | Regulatory and compliance | Compliance checker, audit tool |
| `research` | Market and data research | Market analyst, competitor tracker |
| `translation` | Language translation | Document translator, localization |
| `logistics` | Shipping and logistics | Shipping coordinator, tracking |
| `content` | Content creation | Blog writer, social media manager |

## Agent Skills Compatibility

FYY supports importing skills defined in the [Agent Skills](https://github.com/anthropics/agent-skills) format (SKILL.md). Use the CLI to convert:

```bash
# Import a SKILL.md file into FYY's skill.json format
fyy skill import --from=agent-skills ./path/to/SKILL.md
```

The importer maps SKILL.md frontmatter to skill.json fields and converts Markdown instructions to the description field.

## Example: Customer Service Skill

```json
{
  "name": "customer-service-responder",
  "version": "1.0.0",
  "description": "Drafts professional customer service email responses in multiple languages",
  "type": "mcp",
  "author": "FYY Team",
  "license": "MIT",
  "category": "customer-service",
  "tags": ["email", "support", "multilingual", "ecommerce"],
  "inputs": {
    "customer_email": { "type": "string", "required": true },
    "language": { "type": "string", "default": "en" },
    "tone": { "type": "string", "enum": ["professional", "friendly", "formal"], "default": "professional" },
    "context": { "type": "object", "description": "Order details, product info, etc." }
  },
  "outputs": {
    "response": { "type": "string", "description": "Draft email response" },
    "sentiment": { "type": "string", "description": "Detected customer sentiment" },
    "suggested_actions": { "type": "array", "description": "Recommended follow-up actions" }
  },
  "pricing": {
    "model": "per_call",
    "amount": 0.10,
    "currency": "USD",
    "free_tier": { "calls_per_day": 50 }
  },
  "grants": {
    "required": ["network.outbound"],
    "optional": []
  }
}
```
