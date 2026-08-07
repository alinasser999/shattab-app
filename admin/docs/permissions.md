# Admin Permission Matrix

The matrix is enforced in PostgreSQL by `admin_require_action()`. The client
only hides unavailable controls for clarity; it is not the security boundary.

| Action | Owner | Moderator | Audit |
| --- | --- | --- | --- |
| Read operational data | Yes | Yes | No, reads are not logged |
| Suspend / unsuspend account | Yes | Yes | Yes |
| Verify / unverify professional | Yes | Yes | Yes |
| Approve / reject verification | Yes | Yes | Yes |
| Remove post or comment through moderation | Yes | Yes | Yes |
| Dismiss or action a report | Yes | Yes | Yes |
| Grant or revoke Pro manually | Yes | No | Yes |
| Approve or reject payment | Yes | No | Yes |
| Edit admin membership | SQL/bootstrap process | SQL/bootstrap process | Outside current console |

The `admin_users` table is RLS-enabled with no client read/write policy. The
current-user `admin_level()` projection is safe to call from the console and
does not reveal another account's operator status.

