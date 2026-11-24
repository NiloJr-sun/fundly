# Spaces API — shared spaces C2 and C3

Online-only RPCs for managing spaces and their members. Records inside a space
are written through `fundly_apply_operations` and `fundly_import_dataset` with
an optional `space_id` ([WRITE_API.md](WRITE_API.md), Spaces). All functions
are SECURITY DEFINER, open to `authenticated` only, and refuse with `P0001`
and a message, which apps log as a final rejection (never `42501`). Membership
changes take the space's write lock (`'fundly:' || space_id`).

Every user has a **Personal** space (id = user id): it is never shared, left
or deleted (`personal_space`).

## Spaces (C2)

| RPC | Who | Notes |
|---|---|---|
| `fundly_create_space(space_id, name)` | anyone signed in | At most 10 owned spaces; idempotent for the same id and name |
| `fundly_rename_space(space_id, name, expected_revision)` | owner | Revision-checked |
| `fundly_delete_space(space_id, name)` (C3) | owner | Non-Personal; `name` must match (case and outer spaces ignored). Tombstones every record (so every device removes it), then removes invites, members and the space. Returns `{ space_id, deleted: counts }` |

Names: trimmed, 1–40 UTF-16 units, unique among the spaces the caller owns
(ASCII case ignored).

## Invites (C3)

Invites are bound to an email. The owner shares the link themselves; the app
sends no email. Only `SHA-256(secret)` is stored; the 64-hex-character secret
is returned once by `fundly_create_invite`. Invites last 7 days and work once.

| RPC | Who | Returns / does |
|---|---|---|
| `fundly_create_invite(space_id, email, role)` | owner | `{ invite_id, secret, email, role, expires_at }`. `role` is `editor` or `viewer`. A pending invite to the same email is revoked and replaced |
| `fundly_list_invites(space_id)` | owner | Pending invites `[{ invite_id, email, role, created_at, expires_at }]`, never secrets |
| `fundly_revoke_invite(invite_id)` | owner | Ends it |
| `fundly_preview_invite(secret)` | the invited email | `{ space_id, space_name, role, inviter_name, inviter_email, expires_at, already_member }` |
| `fundly_accept_invite(secret)` | the invited email | Joins with the invite's role (an existing member keeps their role); `{ space_id, space_name, role }` |
| `fundly_decline_invite(secret)` | the invited email | Ends it |

The invite link is `https://fundly-budget.vercel.app/join#<secret>`; the
secret after `#` never reaches the web server.

## Members (C3)

| RPC | Who | Notes |
|---|---|---|
| `fundly_set_member_role(space_id, user_id, role)` | owner | `owner`, `editor` or `viewer`; several owners allowed |
| `fundly_remove_member(space_id, user_id)` | owner | Not the last owner |
| `fundly_leave_space(space_id)` | any member | Not the last owner (promote someone or delete the space) |

Members see each other's `email` and `display_name` (copied from the sign-in
when they join; synced in `fundly_spaces`), nothing else about each other.
Limits: 10 members per space, 20 pending invites per space.

## Errors

| SQLSTATE | Message | Meaning |
|---|---|---|
| `28000` | `authentication_required` | No signed-in user |
| `22023` | `invalid_request` | Missing id, unknown role |
| `P0001` | `not_space_member` | The caller is not a member |
| `P0001` | `space_owner_only` | Owners only |
| `P0001` | `personal_space` | Not allowed for a Personal space |
| `P0001` | `invalid_name` / `name_taken` / `space_id_unavailable` / `space_limit_reached` | Creating or renaming (C2) |
| `P0001` | `revision_conflict` | Rename from a stale revision |
| `P0001` | `invalid_email` | The invite email is not an email |
| `P0001` | `already_member` | That email already belongs to the space |
| `P0001` | `member_limit_reached` / `invite_limit_reached` | 10 members / 20 pending invites |
| `P0001` | `invite_unavailable` | Unknown, malformed, used, declined, revoked or expired |
| `P0001` | `invite_other_email` | The invite names another email (nothing else is revealed) |
| `P0001` | `member_not_found` | The user is not a member |
| `P0001` | `last_owner` | The space would have no owner |
| `P0001` | `space_name_mismatch` | Deleting: the typed name does not match |
