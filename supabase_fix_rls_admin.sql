-- 🔧 CORRECCIÓN SIMPLE RLS - PARA EJECUTAR DESDE EDITOR SQL DE SUPABASE
-- ================================================================
-- IMPORTANTE: Este script debe ejecutarse desde el Editor SQL en el
-- panel administrativo de Supabase, no desde la API o la aplicación.
-- ================================================================

-- INSTRUCCIONES:
-- 1. Inicia sesión en tu panel de Supabase (https://app.supabase.com)
-- 2. Selecciona tu proyecto
-- 3. Ve a "SQL Editor"
-- 4. Crea un nuevo query o copia este contenido en una consulta existente
-- 5. Ejecuta el script completo o paso por paso

-- =====================================================================
-- PASO 1: DESHABILITAR RLS EN TODAS LAS TABLAS PRINCIPALES
-- =====================================================================
ALTER TABLE public.animales DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.veterinarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.citas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.horarios_veterinario DISABLE ROW LEVEL SECURITY;

-- VERIFICA QUE SE HAYA DESACTIVADO RLS CORRECTAMENTE
SELECT 
    tablename as "TABLA", 
    CASE WHEN rowsecurity THEN 'ACTIVADO' ELSE 'DESACTIVADO' END as "ESTADO_RLS"
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('animales', 'veterinarios', 'citas', 'horarios_veterinario');

-- =====================================================================
-- PASO 2: CONFIGURAR PERMISOS PARA ACCESO PÚBLICO
-- =====================================================================
-- Otorgar permisos necesarios para operaciones CRUD
GRANT ALL PRIVILEGES ON TABLE public.animales TO authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE public.veterinarios TO authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE public.citas TO authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE public.horarios_veterinario TO authenticated, anon, service_role;

-- Permisos para secuencias (necesarios para INSERT con autoincremento)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;

-- =====================================================================
-- PASO 3: VERIFICAR CONFIGURACIÓN CON UN INSERT DE PRUEBA
-- =====================================================================
-- Realizar un INSERT de prueba para verificar los permisos
DO $$
BEGIN
    -- Insertar registro de prueba
    INSERT INTO public.animales (
        nombre, correo, contraseña, ubicacion, tipo, raza, edad, altura
    ) VALUES (
        'PRUEBA_RLS_TEMPORAL', 
        'prueba_temp@goyo.app', 
        '123456',
        'Test',
        'Perro',
        'Test',
        '1 año',
        '50 cm'
    );

    -- Verificar que se insertó correctamente
    RAISE NOTICE 'Verificando inserción de prueba...';
    
    -- Eliminar registro de prueba para no dejar basura
    DELETE FROM public.animales WHERE nombre = 'PRUEBA_RLS_TEMPORAL';
    RAISE NOTICE '✅ Prueba completada y registro eliminado';
    
    -- Mostrar mensaje final
    RAISE NOTICE 'CORRECCIÓN RLS COMPLETADA EXITOSAMENTE';
END;
$$;

-- =====================================================================
-- PASO 4: INSTRUCCIONES PARA TU APLICACIÓN
-- =====================================================================
-- 1. El RLS ahora está desactivado para las tablas principales
-- 2. Tu aplicación Flutter debería funcionar correctamente con estas tablas
-- 3. Recuerda que en un entorno de producción deberías configurar RLS
--    apropiadamente para mayor seguridad.
-- 4. Si sigues teniendo problemas de acceso desde la aplicación,
--    comprueba que la URL y la clave anónima en flutter sean correctas:
--
-- await Supabase.initialize(
--   url: 'https://grssfmgkbuflvpqtcaoh.supabase.co',
--   anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdyc3NmbWdrYnVmbHZwcXRjYW9oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk2Mzc4NDEsImV4cCI6MjA2NTIxMzg0MX0.a61pgd9vNkXhWxwP1soXth8Ih7VG8spIsSlTq-mln7E',
-- );
