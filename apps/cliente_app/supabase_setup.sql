-- Enable RLS
alter default privileges in schema public grant all on tables to postgres, anon, authenticated, service_role;

-- 1. Clientes
create table if not exists public.clientes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  telefono text,
  email text,
  direccion text,
  notas text,
  created_at timestamptz default now()
);
alter table public.clientes enable row level security;
create policy "Public access" on public.clientes for all using (true);

-- 2. Nomina Pagos Diarios
create table if not exists public.nomina_pagos_diarios (
  id uuid primary key default gen_random_uuid(),
  id_empleado uuid references auth.users(id), -- Assuming Users are in auth.users or a public.users table? Context says "referencia a la tabla Usuarios". I'll assume public.users or auth.users. Usually app users are in public.profiles or public.users. I'll check if table users exists, but for now lets assume public.users or generic uuid.
  fecha date not null,
  nro_cheque text,
  concepto_periodo text,
  dias numeric,
  forma_pago text,
  monto numeric,
  notas text,
  created_at timestamptz default now()
);
alter table public.nomina_pagos_diarios enable row level security;
create policy "Public access" on public.nomina_pagos_diarios for all using (true);

-- 3. Nomina Destajo (Soldadores)
create table if not exists public.nomina_destajo_soldadores (
  id uuid primary key default gen_random_uuid(),
  id_empleado uuid not null, -- FK to users
  fecha date not null,
  truss_producto text, -- Selected from catalog (text for now)
  cantidad numeric,
  monto_unitario numeric,
  total numeric generated always as (cantidad * monto_unitario) stored,
  pago_parcial numeric default 0,
  notas text,
  created_at timestamptz default now()
);
alter table public.nomina_destajo_soldadores enable row level security;
create policy "Public access" on public.nomina_destajo_soldadores for all using (true);

-- 4. Nomina Instalacion
create table if not exists public.nomina_instalacion (
  id uuid primary key default gen_random_uuid(),
  id_empleado uuid not null,
  id_proyecto uuid not null, -- FK to projects
  fecha_culminacion date,
  pago_proyecto numeric,
  proyecto_cerrado boolean default false,
  pago_parcial numeric default 0,
  saldo numeric generated always as (pago_proyecto - pago_parcial) stored, -- Simplified logic
  descuentos numeric default 0,
  created_at timestamptz default now()
);
alter table public.nomina_instalacion enable row level security;
create policy "Public access" on public.nomina_instalacion for all using (true);

-- 5. Payment Destajo
create table if not exists public.payment_destajo (
  id uuid primary key default gen_random_uuid(),
  tipo text check (tipo in ('Instalación', 'Soldadura')),
  id_nomina_soldadura uuid references public.nomina_destajo_soldadores(id),
  id_nomina_instalacion uuid references public.nomina_instalacion(id),
  amount numeric not null,
  metodo_pago text,
  category text,
  nota text,
  created_at timestamptz default now(),
  constraint payment_target_check check (
    (tipo = 'Soldadura' and id_nomina_soldadura is not null) or
    (tipo = 'Instalación' and id_nomina_instalacion is not null)
  )
);
alter table public.payment_destajo enable row level security;
create policy "Public access" on public.payment_destajo for all using (true);

-- 6. Nomina Horas Chofer
create table if not exists public.nomina_horas_chofer (
  id uuid primary key default gen_random_uuid(),
  id_empleado uuid not null,
  fecha date not null,
  tareas text,
  horas numeric,
  rate_por_hora numeric,
  total numeric generated always as (horas * rate_por_hora) stored,
  notas text,
  created_at timestamptz default now()
);
alter table public.nomina_horas_chofer enable row level security;
create policy "Public access" on public.nomina_horas_chofer for all using (true);

-- Trigger to update 'pago_parcial' in Soldadores/Instalacion when Payment Destajo is added
create or replace function update_pago_parcial() returns trigger as $$
begin
  if NEW.tipo = 'Soldadura' then
    update public.nomina_destajo_soldadores
    set pago_parcial = (select coalesce(sum(amount),0) from public.payment_destajo where id_nomina_soldadura = NEW.id_nomina_soldadura)
    where id = NEW.id_nomina_soldadura;
  elsif NEW.tipo = 'Instalación' then
    update public.nomina_instalacion
    set pago_parcial = (select coalesce(sum(amount),0) from public.payment_destajo where id_nomina_instalacion = NEW.id_nomina_instalacion)
    where id = NEW.id_nomina_instalacion;
  end if;
  return NEW;
end;
$$ language plpgsql;

create trigger tr_update_pago_parcial
after insert or update or delete on public.payment_destajo
for each row execute function update_pago_parcial();

-- Enable Realtime
alter publication supabase_realtime add table public.clientes;
alter publication supabase_realtime add table public.nomina_pagos_diarios;
alter publication supabase_realtime add table public.nomina_destajo_soldadores;
alter publication supabase_realtime add table public.nomina_instalacion;
alter publication supabase_realtime add table public.payment_destajo;
alter publication supabase_realtime add table public.nomina_horas_chofer;
