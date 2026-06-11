# CTWA Referral Capture Plan

## Context

Customers running Meta Click-to-WhatsApp ads need to know which ad or creative
created an inbound WhatsApp conversation. Meta sends this information on the
first inbound message, but Chatwoot currently drops it in both WhatsApp paths:

- WhatsApp Cloud API (`Channel::Whatsapp`)
- Twilio WhatsApp (`Channel::TwilioSms` with WhatsApp medium)

Related GitHub issues:

- [#12560: Feature Request: Preserve WhatsApp url_preview & referral in messages](https://github.com/chatwoot/chatwoot/issues/12560)
- [#13006: Show Ad Source (Instagram / WhatsApp) in Conversations](https://github.com/chatwoot/chatwoot/issues/13006)
- [#13995: Capture Facebook Click-to-WhatsApp Ad Ref Parameter in Conversation Attributes](https://github.com/chatwoot/chatwoot/issues/13995)
- [#14047: Twilio Click-to-WhatsApp referral attributes](https://github.com/chatwoot/chatwoot/issues/14047)

Related Linear issues:

- [CW-7090: Surface Meta CTWA referral on incoming WhatsApp messages - Cloud API](https://linear.app/chatwoot/issue/CW-7090/surface-meta-ctwa-referral-on-incoming-whatsapp-messages-cloud-api)
- [CW-7301: Capture Instagram ad referral metadata on incoming messages](https://linear.app/chatwoot/issue/CW-7301/capture-instagram-ad-referral-metadata-on-incoming-messages)
- [CW-7302: Capture Messenger ad referral metadata on Facebook Page conversations](https://linear.app/chatwoot/issue/CW-7302/capture-messenger-ad-referral-metadata-on-facebook-page-conversations)
- [CW-7303: Capture TikTok ad referral metadata from im_referral_msg events](https://linear.app/chatwoot/issue/CW-7303/capture-tiktok-ad-referral-metadata-from-im-referral-msg-events)
- [CW-7330: Design and surface cross-channel ad referral metadata in conversation UI](https://linear.app/chatwoot/issue/CW-7330/design-and-surface-cross-channel-ad-referral-metadata-in-conversation)

Related community PRs:

- [#13130: feat: init ad source metadata ability](https://github.com/chatwoot/chatwoot/pull/13130)
- [#14121: feat(whatsapp): store ctwa_clid and referral metadata on conversations](https://github.com/chatwoot/chatwoot/pull/14121)
- [#14180: feat(twilio): capture Meta Click-to-WhatsApp referral attributes on incoming messages](https://github.com/chatwoot/chatwoot/pull/14180)

The immediate product need is to preserve referral metadata for API/webhook
consumers and future UI/reporting work. The canonical storage location should
be message-level metadata:

```json
{
  "content_attributes": {
    "referral": {
      "source_url": "https://fb.me/...",
      "source_id": "52558118838064",
      "source_type": "ad",
      "body": "Ad body",
      "headline": "Ad headline",
      "media_type": "video",
      "video_url": "https://www.facebook.com/reel/...",
      "thumbnail_url": "https://scontent.xx.fbcdn.net/...",
      "ctwa_clid": "Afhc...",
      "welcome_message": {
        "text": "Hi! Please let us know how we can help you."
      }
    }
  }
}
```

## Evidence From Production Logs

CTWA = Click to WhatsApp Ads.

### WhatsApp Cloud API

Cloud API sends referral data at:

```text
entry[0].changes[0].value.messages[0].referral
```

Observed fields:

- `source_url`
- `source_id`
- `source_type`
- `body`
- `headline`
- `media_type`
- `video_url`
- `thumbnail_url`
- `ctwa_clid`
- `welcome_message.text`

The same payload also includes BSUID fields such as `from_user_id` and
`contacts[].user_id`, but those are out of scope for this plan.

Cloud API can also send referral metadata on parent messages whose
`type` is not text. For `type: contacts`, Chatwoot creates one message per
contact card from `message['contacts']`, but the referral remains on the
parent WhatsApp message. The implementation must therefore preserve referral
metadata from the parent message while still rendering the child contact
payload.

### Twilio WhatsApp

Twilio sends CTWA referral fields as flat webhook params:

- `ReferralCtwaClid`
- `ReferralSourceId`
- `ReferralSourceUrl`
- `ReferralSourceType`
- `ReferralHeadline`
- `ReferralBody`
- `ReferralMediaId`
- `ReferralNumMedia`
- optional `ReferralMediaContentType`
- optional `ReferralMediaUrl`

Production logs show `ReferralCtwaClid`, `ReferralMediaId`, and similar fields
can be present as empty strings. The implementation should omit blank values
from the normalized referral payload.

### Instagram

Instagram ads can send referral data under both active and standby webhook
events:

```text
entry[0].messaging[0].message.referral
entry[0].standby[0].message.referral
```

Observed shape:

```json
{
  "source": "ADS",
  "type": "OPEN_THREAD",
  "ad_id": "52509866634569",
  "ads_context_data": {
    "ad_title": "Publicación de Instagram: Casting...",
    "photo_url": "https://scontent.xx.fbcdn.net/..."
  }
}
```

This is tracked separately in CW-7301 and should be handled after the WhatsApp
storage PR.

### Messenger / Facebook Page

Messenger referral details are expected on Facebook Page webhook referral
events or postback referral payloads, commonly shaped like:

```json
{
  "referral": {
    "source": "ADS",
    "type": "OPEN_THREAD",
    "ad_id": "6045246247433",
    "ads_context_data": {
      "ad_title": "Ad title",
      "photo_url": "https://..."
    }
  }
}
```

Current Chatwoot Facebook Page setup mounts Messenger webhooks at `/bot`, not
`/webhooks/facebook`. The current subscription and handler path does not appear
to capture Messenger referral events yet. This is tracked separately in
CW-7302.

### TikTok

TikTok sends ad referral data through `im_referral_msg` events with referral
metadata inside the JSON `content` param:

```json
{
  "event": "im_referral_msg",
  "content": {
    "referral": {
      "source": "ad",
      "ad": {
        "ad_id": "1865980816147570",
        "ad_name": "Ad name",
        "embed_url": "https://www.tiktok.com/player/v1/...",
        "advertiser_id": "7642959100829106192",
        "message_material_id": ""
      }
    }
  }
}
```

This is tracked separately in CW-7303.

## Decision

Store CTWA referral metadata on the incoming message:

```ruby
message.content_attributes['referral']
```

Do not store the canonical payload on `conversation.additional_attributes`.
Referral is message-scoped metadata and is only sent on the inbound message that
originated from the ad click.

Normalize both channels into the Cloud API snake_case shape:

| Cloud API key | Twilio source |
| --- | --- |
| `source_id` | `ReferralSourceId` |
| `source_type` | `ReferralSourceType` |
| `source_url` | `ReferralSourceUrl` |
| `headline` | `ReferralHeadline` |
| `body` | `ReferralBody` |
| `media_id` | `ReferralMediaId` |
| `media_content_type` | `ReferralMediaContentType` |
| `media_url` | `ReferralMediaUrl` |
| `num_media` | `ReferralNumMedia` |
| `ctwa_clid` | `ReferralCtwaClid` |

Preserve unknown nested Cloud API referral fields, such as
`welcome_message.text`, by storing the full referral object after stringifying
keys.

## Implementation Plan

Current PR: [#14681](https://github.com/chatwoot/chatwoot/pull/14681)

### 1. WhatsApp Cloud API

Update `Whatsapp::IncomingMessageBaseService#create_message` or a helper used
by it to merge referral content into `content_attributes`.

Target behavior:

- If `message[:referral]` is present, store it as
  `content_attributes['referral']`.
- Preserve existing content attributes such as `in_reply_to_external_id`.
- Preserve unknown nested fields.
- Do not run this for outgoing echo messages.
- For `type: contacts`, read referral metadata from the parent WhatsApp message,
  not from the child contact-card object.

Expected shape:

```ruby
content_attrs = {}
content_attrs[:in_reply_to_external_id] = @in_reply_to_external_id if @in_reply_to_external_id.present?
content_attrs[:referral] = normalized_referral(message) if inbound_referral?(message)
```

### 2. Twilio WhatsApp

Update `Twilio::CallbackController#permitted_params` to allow all Twilio
`Referral*` params.

Update `Twilio::IncomingMessageService` to build nested referral
`content_attributes` for WhatsApp messages only.

Target behavior:

- Only create `content_attributes['referral']` when `ReferralSourceId` is
  present.
- Omit blank values.
- Normalize keys to the same snake_case names used by Cloud API.
- Keep SMS behavior unchanged.

### 3. API And Webhooks

No serializer changes are expected because message APIs and message webhooks
already include `content_attributes`.

Verify:

- Conversation messages API includes `content_attributes.referral`.
- `message_created` webhook includes `content_attributes.referral`.

### 4. Tests

Add focused specs:

- Cloud API incoming message with `referral` stores nested referral on the
  created message.
- Cloud API referral preserves unknown nested fields such as
  `welcome_message.text`.
- Cloud API contact-card message preserves referral from the parent message.
- Cloud API message without referral behaves unchanged.
- Cloud API reply context and referral can coexist in `content_attributes`.
- Twilio callback permits `Referral*` params.
- Twilio WhatsApp incoming message with referral stores normalized nested
  referral on the created message.
- Twilio omits blank optional values.
- Twilio SMS remains unchanged.

Suggested spec files:

- `spec/services/whatsapp/incoming_message_whatsapp_cloud_service_spec.rb`
- `spec/services/twilio/incoming_message_service_spec.rb`
- Controller/request coverage for `Twilio::CallbackController` if existing
  tests cover permitted params there.

## UI Follow-Up

Do not include UI in the first backend PR.

After backend capture lands for all relevant channels, add a focused UI
follow-up that surfaces referral metadata in conversations. Avoid a WhatsApp-only
UI design until Instagram, Messenger, and TikTok storage shapes are settled.

Recommended UI fields:

- headline
- body
- source type
- source ID
- source URL
- media thumbnail/link
- `ctwa_clid` behind a copy/details affordance, not as primary agent-facing text

## Out Of Scope

- Sidebar UI in the backend capture PR
- Instagram referral capture in the WhatsApp CTWA PR
- Messenger referral capture in the WhatsApp CTWA PR
- TikTok referral capture in the WhatsApp CTWA PR

## Open Questions

- Should the UI read referral directly from the selected/visible message, from
  the first inbound message that has referral metadata, or from a derived
  conversation-level convenience value?
- Should we expose a convenience field on conversation API later for easier
  filtering, while keeping message-level storage canonical?
- Should automation conditions support nested message referral metadata in a
  follow-up?
