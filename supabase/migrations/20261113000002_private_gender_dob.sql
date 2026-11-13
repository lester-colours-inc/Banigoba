-- Edit Profile: gender and date of birth live in the owner-only private
-- table (never on the public profile). Gender drives "For you" ordering in
-- the shop; date of birth is only used to confirm age.
alter table public.private_account
  add column gender text
    check (gender is null or gender in ('male', 'female', 'non_binary', 'prefer_not')),
  add column date_of_birth date
    check (date_of_birth is null or (date_of_birth <= current_date and date_of_birth > date '1900-01-01'));
