BEGIN;

CREATE TABLE IF NOT EXISTS public.user_invitations (
    id text PRIMARY KEY,
    email text NOT NULL,
    name text NOT NULL,
    role text NOT NULL CHECK (role IN ('ADMIN','MANAGER','OPERATOR','VIEWER')),
    company_id text NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    warehouse_id text NULL REFERENCES public.warehouses(id) ON DELETE SET NULL,
    invited_by_user_id text NULL REFERENCES public.users(id) ON DELETE SET NULL,
    token_hash text NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    accepted_at timestamptz NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS user_invitations_company_email_idx
    ON public.user_invitations (company_id, lower(email));

CREATE INDEX IF NOT EXISTS user_invitations_expiry_idx
    ON public.user_invitations (expires_at)
    WHERE accepted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.user_warehouse_assignments (
    id text PRIMARY KEY,
    "userId" text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    "warehouseId" text NOT NULL REFERENCES public.warehouses(id) ON DELETE CASCADE,
    "createdAt" timestamptz NOT NULL DEFAULT now(),
    UNIQUE ("userId", "warehouseId")
);

CREATE INDEX IF NOT EXISTS user_warehouse_assignments_warehouse_idx
    ON public.user_warehouse_assignments ("warehouseId");

COMMIT;
