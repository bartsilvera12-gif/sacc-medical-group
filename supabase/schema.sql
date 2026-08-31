-- =============================================================================
--  SACC Medical Group — esquema del panel de administracion
-- =============================================================================
--  Se pega entero en el SQL Editor de Supabase. Es idempotente: se puede
--  volver a correr sin romper nada.
--
--  Despues de correrlo hay UN paso manual imprescindible:
--    Settings -> API -> Exposed schemas: agregar  sacc
--  Sin eso la API REST no ve estas tablas y todo devuelve 404.
-- =============================================================================

create schema if not exists sacc;

-- -----------------------------------------------------------------------------
--  Quien puede escribir
-- -----------------------------------------------------------------------------
--  La anon key es publica por definicion: cualquiera puede leer. Lo que protege
--  la escritura es esta tabla mas las politicas de abajo. Un usuario de
--  Supabase Auth solo puede modificar contenido si su id figura aca.
create table if not exists sacc.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email   text not null,
  creado  timestamptz not null default now()
);

create or replace function sacc.es_admin()
returns boolean
language sql
security definer
set search_path = sacc, public
as $$
  select exists (select 1 from sacc.admins a where a.user_id = auth.uid());
$$;

-- -----------------------------------------------------------------------------
--  Datos de contacto (una sola fila)
-- -----------------------------------------------------------------------------
create table if not exists sacc.contacto (
  id            smallint primary key default 1 check (id = 1),
  email         text not null default 'info@saccmedicalgroup.com',
  linkedin      text not null default 'https://www.linkedin.com',
  sede_es       text not null default 'Asunción · República del Paraguay',
  sede_en       text not null default 'Asunción · Republic of Paraguay',
  titulo_es     text not null default 'Desarrollemos juntos el mercado sanitario paraguayo.',
  titulo_en     text not null default 'Let''s develop the Paraguayan healthcare market together.',
  bajada_es     text not null default 'Si su compañía está explorando oportunidades en Paraguay, conversemos.',
  bajada_en     text not null default 'If your company is exploring opportunities in Paraguay, let''s talk.',
  actualizado   timestamptz not null default now()
);

insert into sacc.contacto (id) values (1) on conflict (id) do nothing;

-- -----------------------------------------------------------------------------
--  Imagenes
-- -----------------------------------------------------------------------------
--  Una fila por hueco del sitio. `slot` es el id del <image-slot> en el HTML;
--  si `url` esta vacia el sitio se queda con la foto que ya trae, asi que la
--  tabla nunca puede dejar la pagina sin imagen.
create table if not exists sacc.imagenes (
  slot        text primary key,
  url         text,
  alt_es      text,
  alt_en      text,
  descripcion text,
  orden       smallint not null default 0,
  actualizado timestamptz not null default now()
);

insert into sacc.imagenes (slot, descripcion, orden) values
  ('sacc-intro',      'Presentación — panorámica de entorno científico', 1),
  ('sacc-area-1',     'Áreas — especialidades farmacéuticas',            2),
  ('sacc-area-2',     'Áreas — dispositivos médicos',                    3),
  ('sacc-area-3',     'Áreas — insumos médicos',                         4),
  ('sacc-area-4',     'Áreas — equipamiento médico',                     5),
  ('sacc-area-5',     'Áreas — regulatorio y acceso al mercado',         6),
  ('sacc-area-6',     'Áreas — negocios internacionales',                7),
  ('sacc-regulatory', 'Regulatorio — documentación y cumplimiento',      8),
  ('sacc-global',     'Negocios internacionales — fondo',                9),
  ('sacc-model-1',    'Modelo — desarrollo de producto',                10),
  ('sacc-model-2',    'Modelo — estrategia regulatoria',                11),
  ('sacc-model-3',    'Modelo — acceso al mercado',                     12),
  ('sacc-model-4',    'Modelo — desarrollo comercial',                  13),
  ('sacc-mission',    'Nosotros — misión y visión',                     14),
  ('sacc-purpose',    'Propósito — fondo',                              15)
on conflict (slot) do update set descripcion = excluded.descripcion, orden = excluded.orden;

-- -----------------------------------------------------------------------------
--  Marca de tiempo automatica
-- -----------------------------------------------------------------------------
create or replace function sacc.tocar_actualizado()
returns trigger language plpgsql as $$
begin
  new.actualizado := now();
  return new;
end $$;

drop trigger if exists contacto_actualizado on sacc.contacto;
create trigger contacto_actualizado before update on sacc.contacto
  for each row execute function sacc.tocar_actualizado();

drop trigger if exists imagenes_actualizado on sacc.imagenes;
create trigger imagenes_actualizado before update on sacc.imagenes
  for each row execute function sacc.tocar_actualizado();

-- -----------------------------------------------------------------------------
--  Permisos y politicas
-- -----------------------------------------------------------------------------
grant usage on schema sacc to anon, authenticated;
grant select on sacc.contacto, sacc.imagenes to anon, authenticated;
grant insert, update on sacc.contacto, sacc.imagenes to authenticated;
grant select on sacc.admins to authenticated;

alter table sacc.contacto enable row level security;
alter table sacc.imagenes enable row level security;
alter table sacc.admins   enable row level security;

drop policy if exists contacto_lectura_publica on sacc.contacto;
create policy contacto_lectura_publica on sacc.contacto
  for select to anon, authenticated using (true);

drop policy if exists contacto_escritura_admin on sacc.contacto;
create policy contacto_escritura_admin on sacc.contacto
  for update to authenticated using (sacc.es_admin()) with check (sacc.es_admin());

drop policy if exists imagenes_lectura_publica on sacc.imagenes;
create policy imagenes_lectura_publica on sacc.imagenes
  for select to anon, authenticated using (true);

drop policy if exists imagenes_escritura_admin on sacc.imagenes;
create policy imagenes_escritura_admin on sacc.imagenes
  for update to authenticated using (sacc.es_admin()) with check (sacc.es_admin());

drop policy if exists imagenes_alta_admin on sacc.imagenes;
create policy imagenes_alta_admin on sacc.imagenes
  for insert to authenticated with check (sacc.es_admin());

--  Cada admin solo se ve a si mismo: alcanza para que el panel confirme el
--  permiso, y no expone la lista de administradores.
drop policy if exists admins_se_ve_a_si_mismo on sacc.admins;
create policy admins_se_ve_a_si_mismo on sacc.admins
  for select to authenticated using (user_id = auth.uid());

-- -----------------------------------------------------------------------------
--  Almacenamiento de imagenes
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('sacc-imagenes', 'sacc-imagenes', true)
on conflict (id) do update set public = true;

drop policy if exists sacc_img_lectura on storage.objects;
create policy sacc_img_lectura on storage.objects
  for select to anon, authenticated using (bucket_id = 'sacc-imagenes');

drop policy if exists sacc_img_alta on storage.objects;
create policy sacc_img_alta on storage.objects
  for insert to authenticated with check (bucket_id = 'sacc-imagenes' and sacc.es_admin());

drop policy if exists sacc_img_reemplazo on storage.objects;
create policy sacc_img_reemplazo on storage.objects
  for update to authenticated using (bucket_id = 'sacc-imagenes' and sacc.es_admin());

drop policy if exists sacc_img_baja on storage.objects;
create policy sacc_img_baja on storage.objects
  for delete to authenticated using (bucket_id = 'sacc-imagenes' and sacc.es_admin());

-- =============================================================================
--  Ultimo paso: dar de alta al administrador
-- =============================================================================
--  1. Authentication -> Users -> Add user, con correo y contraseña.
--  2. Copiar su UID y correr:
--
--       insert into sacc.admins (user_id, email)
--       values ('PEGAR-EL-UID-AQUI', 'correo@ejemplo.com');
--
--  Sin este paso el usuario entra al panel pero no puede guardar nada.
-- =============================================================================
