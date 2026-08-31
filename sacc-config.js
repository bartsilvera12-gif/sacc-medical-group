// Conexion con Supabase.
//
// Los dos valores salen de: Supabase -> Settings -> API.
//   URL      = "Project URL"
//   ANON_KEY = "anon public"   <-- la publica, NUNCA la service_role
//
// La anon key esta pensada para vivir en el navegador: no da permisos por si
// sola. Lo que decide quien puede escribir son las politicas RLS de
// supabase/schema.sql, que exigen que el usuario figure en sacc.admins.
//
// Mientras esten vacios, el sitio funciona igual con el contenido que ya trae
// y el panel avisa que falta configurarlo.
window.SACC_SUPABASE = {
  URL: 'https://api.neura.com.py',
  ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MTAxNDYxLCJleHAiOjE5MzE3ODE0NjF9.7_wAph8IolPMXtgfpezSwS5XR62IdD__qhqCywLDp3Q',
  ESQUEMA: 'sacc',
  BUCKET: 'sacc-imagenes',
};
