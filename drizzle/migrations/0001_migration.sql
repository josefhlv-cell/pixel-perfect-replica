
revoke select on public.api_keys from authenticated;
grant select (id, organization_id, name, key_prefix, scopes, rate_limit_per_minute, created_by, last_used_at, expires_at, revoked_at, created_at, updated_at) on public.api_keys to authenticated;
revoke select on public.organization_invitations from authenticated;
grant select (id, organization_id, email, role, status, invited_by, expires_at, accepted_at, created_at, updated_at) on public.organization_invitations to authenticated;
-- Only allow revoking keys/invites via update, never changing hash
revoke update on public.api_keys from authenticated;
grant update (name, revoked_at) on public.api_keys to authenticated;
revoke update on public.organization_invitations from authenticated;
grant update (status) on public.organization_invitations to authenticated;
