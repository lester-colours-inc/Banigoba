-- The privilege guard ran as its owner, so is_server() (which looks at the
-- running role) was always true inside it and nothing was guarded. Run it as
-- the caller instead; it only calls is_admin(), which is itself definer.
alter function public.guard_profile_privileges() security invoker;
