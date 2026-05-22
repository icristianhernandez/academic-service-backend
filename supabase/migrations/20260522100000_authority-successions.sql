create table public.authority_successions (
    like public.audit_meta including all,
    id bigint generated always as identity primary key,
    predecessor_profile_id uuid not null references public.profiles(id),
    successor_email text not null,
    role_name text not null,
    entity_type text not null,
    entity_id text not null,
    entity_name text not null,
    reason text,
    performed_by_profile_id uuid not null references public.profiles(id),
    executed_at timestamptz default now() not null
);

call public.setup_audit('authority_successions');
