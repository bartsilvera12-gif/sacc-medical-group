-- =============================================================================
--  SACC Medical Group — areas de actividad y principios
-- =============================================================================
--  Se corre despues de schema.sql, en el SQL Editor. Tambien es idempotente.
--
--  A diferencia de contacto e imagenes, aca si se pueden agregar y borrar
--  filas: son listas, no campos fijos. El sitio las ordena por `orden` y
--  saltea las que tengan visible = false.
--
--  Si la tabla queda vacia, el sitio se queda con las seis tarjetas que trae
--  el HTML. Vaciarla por accidente no deja la seccion en blanco.
-- =============================================================================

-- -----------------------------------------------------------------------------
--  Areas de actividad  ("Capacidades integrales en salud")
-- -----------------------------------------------------------------------------
create table if not exists sacc.areas (
  id             uuid primary key default gen_random_uuid(),
  orden          smallint not null default 0,
  titulo_es      text not null default '',
  titulo_en      text not null default '',
  descripcion_es text not null default '',
  descripcion_en text not null default '',
  imagen_url     text,
  visible        boolean not null default true,
  actualizado    timestamptz not null default now()
);

create index if not exists areas_orden on sacc.areas (orden);

-- -----------------------------------------------------------------------------
--  Nuestros principios
-- -----------------------------------------------------------------------------
create table if not exists sacc.principios (
  id          uuid primary key default gen_random_uuid(),
  orden       smallint not null default 0,
  titulo_es   text not null default '',
  titulo_en   text not null default '',
  texto_es    text not null default '',
  texto_en    text not null default '',
  visible     boolean not null default true,
  actualizado timestamptz not null default now()
);

create index if not exists principios_orden on sacc.principios (orden);

-- -----------------------------------------------------------------------------
--  Marca de tiempo
-- -----------------------------------------------------------------------------
drop trigger if exists areas_actualizado on sacc.areas;
create trigger areas_actualizado before update on sacc.areas
  for each row execute function sacc.tocar_actualizado();

drop trigger if exists principios_actualizado on sacc.principios;
create trigger principios_actualizado before update on sacc.principios
  for each row execute function sacc.tocar_actualizado();

-- -----------------------------------------------------------------------------
--  Permisos y politicas
-- -----------------------------------------------------------------------------
grant select on sacc.areas, sacc.principios to anon, authenticated;
grant insert, update, delete on sacc.areas, sacc.principios to authenticated;

alter table sacc.areas      enable row level security;
alter table sacc.principios enable row level security;

drop policy if exists areas_lectura_publica on sacc.areas;
create policy areas_lectura_publica on sacc.areas
  for select to anon, authenticated using (true);

drop policy if exists areas_admin on sacc.areas;
create policy areas_admin on sacc.areas
  for all to authenticated using (sacc.es_admin()) with check (sacc.es_admin());

drop policy if exists principios_lectura_publica on sacc.principios;
create policy principios_lectura_publica on sacc.principios
  for select to anon, authenticated using (true);

drop policy if exists principios_admin on sacc.principios;
create policy principios_admin on sacc.principios
  for all to authenticated using (sacc.es_admin()) with check (sacc.es_admin());

-- -----------------------------------------------------------------------------
--  Carga inicial con lo que hoy dice el sitio
-- -----------------------------------------------------------------------------
--  Solo se ejecuta si las tablas estan vacias, para no pisar ediciones.
insert into sacc.areas (orden, titulo_es, titulo_en, descripcion_es, descripcion_en, imagen_url)
select * from (values
  (1, 'Especialidades farmacéuticas', 'Pharmaceutical Specialties',
      'Desarrollo e incorporación de medicamentos y líneas farmacéuticas destinadas tanto al mercado general como a áreas terapéuticas especializadas.',
      'Development and incorporation of medicines and pharmaceutical lines for the general market and specialized therapeutic areas.',
      'uploads/sacc-area-1.jpg'),
  (2, 'Dispositivos médicos', 'Medical Devices',
      'Desarrollo de líneas de dispositivos médicos seleccionadas bajo criterios de calidad, cumplimiento regulatorio y necesidades del mercado.',
      'Development of medical device lines selected under criteria of quality, regulatory compliance and market needs.',
      'uploads/sacc-area-2.jpg'),
  (3, 'Insumos médicos', 'Medical Supplies',
      'Insumos médicos y hospitalarios para hospitales, sanatorios, clínicas, laboratorios y profesionales de la salud.',
      'Medical and hospital supplies for hospitals, sanatoriums, clinics, laboratories and healthcare professionals.',
      'uploads/sacc-area-3.jpg'),
  (4, 'Equipamiento médico', 'Medical Equipment',
      'Identificación, importación y comercialización de tecnologías y equipamiento médico.',
      'Identification, import and commercialization of medical technologies and equipment.',
      'uploads/sacc-area-4.jpg'),
  (5, 'Regulatorio y acceso al mercado', 'Regulatory & Market Access',
      'Evaluación regulatoria, registros sanitarios y estrategia de introducción de productos al mercado.',
      'Regulatory assessment, health registrations and product market-entry strategy.',
      'uploads/sacc-area-5.jpg'),
  (6, 'Desarrollo de negocios internacionales', 'International Business Development',
      'Desarrollo de relaciones con fabricantes, laboratorios y compañías internacionales.',
      'Development of relationships with international manufacturers, laboratories and companies.',
      'uploads/sacc-area-6.jpg')
) as v(orden, titulo_es, titulo_en, descripcion_es, descripcion_en, imagen_url)
where not exists (select 1 from sacc.areas);

insert into sacc.principios (orden, titulo_es, titulo_en, texto_es, texto_en)
select * from (values
  (1, 'Calidad', 'Quality',
      'Seleccionamos productos y fabricantes considerando estándares técnicos, regulatorios y de calidad compatibles con las exigencias del sector sanitario.',
      'We select products and manufacturers according to technical, regulatory and quality standards aligned with the demands of the healthcare sector.'),
  (2, 'Cumplimiento', 'Compliance',
      'La actividad médica y farmacéutica exige responsabilidad. El cumplimiento regulatorio constituye un elemento central de nuestra estrategia.',
      'Medical and pharmaceutical activity demands responsibility. Regulatory compliance is a core element of our strategy.'),
  (3, 'Confianza', 'Trust',
      'Construimos relaciones de largo plazo con fabricantes, clientes, profesionales e instituciones.',
      'We build long-term relationships with manufacturers, clients, professionals and institutions.'),
  (4, 'Innovación', 'Innovation',
      'Buscamos permanentemente nuevos productos, tecnologías y modelos capaces de aportar valor al mercado sanitario.',
      'We continuously seek new products, technologies and models capable of adding value to the healthcare market.'),
  (5, 'Acceso', 'Access',
      'Trabajamos para facilitar la incorporación al Paraguay de soluciones médicas y farmacéuticas competitivas y de calidad.',
      'We work to facilitate the introduction into Paraguay of competitive, quality medical and pharmaceutical solutions.'),
  (6, 'Desarrollo sostenible', 'Sustainable development',
      'Priorizamos relaciones comerciales capaces de generar continuidad, crecimiento y valor para todas las partes involucradas.',
      'We prioritise commercial relationships capable of generating continuity, growth and value for all parties involved.')
) as v(orden, titulo_es, titulo_en, texto_es, texto_en)
where not exists (select 1 from sacc.principios);

-- -----------------------------------------------------------------------------
--  Refrescar la cache de PostgREST
-- -----------------------------------------------------------------------------
--  Crear las tablas no alcanza: PostgREST guarda su propio mapa del esquema y
--  hasta que se recarga responde 404 con el codigo PGRST205. Esta linea se lo
--  avisa.
notify pgrst, 'reload schema';
