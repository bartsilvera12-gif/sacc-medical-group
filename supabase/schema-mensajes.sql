-- Mensajes del formulario de contacto.
--
-- Correr una sola vez en Supabase -> SQL Editor. Es idempotente: se puede
-- volver a correr sin romper nada.
--
-- La regla importante de este archivo es quien puede LEER. La anon key vive en
-- el navegador y cualquiera puede sacarla del codigo fuente, asi que si anon
-- pudiera hacer select sobre esta tabla, cualquiera podria bajarse todos los
-- mensajes que le escriben a SACC, con nombres, correos y telefonos. Por eso
-- anon solo puede INSERTAR. Leer, solo los administradores.

create schema if not exists sacc;

create table if not exists sacc.mensajes (
  id         bigint generated always as identity primary key,
  creado_en  timestamptz not null default now(),
  nombre     text        not null,
  empresa    text,
  email      text        not null,
  telefono   text,
  interes    text,
  mensaje    text        not null,
  leido      boolean     not null default false,
  origen     text
);

comment on table sacc.mensajes is
  'Consultas recibidas por el formulario de contacto del sitio.';

-- Limites de tamaño y forma. No reemplazan a la validacion del navegador:
-- son la que vale, porque el navegador se puede saltear.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'mensajes_forma'
  ) then
    alter table sacc.mensajes add constraint mensajes_forma check (
      length(nombre)  between 2 and 120
      and length(email) between 5 and 160
      and email like '%_@_%.__%'
      and length(mensaje) between 10 and 4000
      and (empresa  is null or length(empresa)  <= 160)
      and (telefono is null or length(telefono) <= 40)
      and (interes  is null or length(interes)  <= 60)
      and (origen   is null or length(origen)   <= 120)
    );
  end if;
end $$;

create index if not exists mensajes_por_fecha on sacc.mensajes (creado_en desc);
create index if not exists mensajes_sin_leer  on sacc.mensajes (leido) where not leido;

-- ---------------------------------------------------------------- permisos
grant usage  on schema sacc to anon, authenticated;
grant insert on sacc.mensajes to anon, authenticated;
grant select, update on sacc.mensajes to authenticated;

alter table sacc.mensajes enable row level security;

-- Cualquiera puede dejar un mensaje: es un formulario publico.
drop policy if exists mensajes_alta_publica on sacc.mensajes;
create policy mensajes_alta_publica on sacc.mensajes
  for insert to anon, authenticated with check (true);

-- Pero leerlos es solo de administradores. Sin esta politica, anon no ve
-- ninguna fila, que es justamente lo que se quiere.
drop policy if exists mensajes_lectura_admin on sacc.mensajes;
create policy mensajes_lectura_admin on sacc.mensajes
  for select to authenticated using (sacc.es_admin());

-- Marcar como leido, tambien.
drop policy if exists mensajes_marcar_admin on sacc.mensajes;
create policy mensajes_marcar_admin on sacc.mensajes
  for update to authenticated
  using (sacc.es_admin()) with check (sacc.es_admin());

-- Sin esto la tabla existe pero la API sigue contestando PGRST205, porque
-- PostgREST guarda en cache el esquema y no se entera solo.
notify pgrst, 'reload schema';
