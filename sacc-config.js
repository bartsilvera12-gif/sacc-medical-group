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
  URL: '',
  ANON_KEY: '',
  ESQUEMA: 'sacc',
  BUCKET: 'sacc-imagenes',
};
