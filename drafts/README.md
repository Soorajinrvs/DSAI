# Drafts — Local Email and Message Templates

The `drafts/` folder contains email and message drafts ready to review and send.

## How This Works

1. **DSAI writes a complete draft** with To, Subject, and Body.
2. **You review it** in VS Code and make changes if needed.
3. **When ready:** Copy the draft text and send it yourself (or ask an online assistant to send it).
4. **DSAI never sends automatically** — this is your chance to review before any message leaves your computer.

## Draft File Format

**Filename:** `YYYY-MM-DD-short-description.md` (e.g., `2026-11-07-email-to-landlord.md`)

**Contents:**

```markdown
To: recipient@example.com
Subject: Subject line here

---

Dear [Name],

Body text goes here. Keep it clear and professional.

Best regards,
[Your Name]
```

## Creating a New Draft

Run the helper script:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\new-draft.ps1
```

This creates a new dated file in `drafts/` and opens it for editing.

## Sending a Draft

1. **Open the draft file in VS Code.**
2. **Review the To, Subject, and Body.**
3. **Make any changes** (tone, details, spelling).
4. **Copy the text** (or manually type it into your email client).
5. **Send it yourself** via Gmail, Outlook, or your email app.

**Pro tip:** Leave drafts in this folder as a record of what you sent. You can review them anytime or share them with others.

## Rules for Drafts

- **Never sends automatically:** Drafts are always manual approval before sending.
- **All local:** Drafts never touch the internet or any email server.
- **Always reviewable:** You can edit drafts before sending.
- **Keeps a record:** Drafts stay in this folder for your reference.

## Examples

### Draft 1: Polite Decline
```markdown
To: boss@company.com
Subject: Re: Meeting on Friday

---

Hi [Boss],

Thanks for the invitation to the Friday meeting. Unfortunately, I have a prior commitment and will not be able to attend.

I'd be happy to catch up Monday instead, or you can fill me in via email.

Thanks!
[Your Name]
```

### Draft 2: Thank You Note
```markdown
To: friend@example.com
Subject: Thanks for the gift!

---

Hi [Friend],

I wanted to say thank you for the lovely gift. It was so thoughtful of you, and I really appreciate it.

Let's catch up soon!

[Your Name]
```

## Linking to Tasks

An online assistant can ask DSAI to draft an email as part of a larger task. For example:

```markdown
# Task: Draft response to job offer

**Goal:** Write a professional thank-you email declining a job offer.

**Files to touch:**
- drafts/2026-11-07-job-offer-decline.md (create)

**What stays online:**
- Sending the email (you send it yourself)
```

DSAI will create the draft, and you review and send it.

---

## Quick Start

To draft an email with DSAI:

1. **Type in the Continue chat:**
   ```
   "Draft an email to my landlord explaining the rent will be late."
   ```

2. **DSAI suggests a draft.**

3. **You say** "Create a file for this" or run `tools/new-draft.ps1`.

4. **DSAI writes the complete draft to `drafts/`.**

5. **You review, edit, and send it yourself.**

Done! No internet needed, and full control before sending.
