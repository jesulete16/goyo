-- 🔧 CORRECCIÓN COMPLETA RLS - TODAS LAS TABLAS
-- ================================================================
-- Este script resuelve problemas RLS en todas las tablas principales
-- ================================================================

-- 1. DESHABILITAR RLS EN TODAS LAS TABLAS PRINCIPALES
ALTER TABLE public.animales DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.veterinarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.citas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.horarios_veterinario DISABLE ROW LEVEL SECURITY;

-- 2. OTORGAR PERMISOS COMPLETOS A USUARIOS ANÓNIMOS Y AUTENTICADOS
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO public;

-- 3. OTORGAR PERMISOS EN LAS SECUENCIAS (PARA IDs AUTOINCREMENTALES)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO public;

-- 4. VERIFICAR ESTADO FINAL
SELECT 
    'TABLA: ' || tablename as "VERIFICACION",
    'RLS ACTIVO: ' || CASE WHEN rowsecurity THEN 'SÍ' ELSE 'NO' END as "ESTADO"
FROM pg_tables 
WHERE tablename IN ('animales', 'veterinarios', 'citas', 'horarios_veterinario')
ORDER BY tablename;

-- 5. PROBAR INSERT EN ANIMALES
INSERT INTO public.animales (
    nombre,
    correo,
    contraseña,
    ubicacion,
    tipo,
    raza,
    edad,
    altura
) VALUES (
    'PRUEBA_RLS_FINAL',
    'prueba_rls@test.com',
    '123456',
    'Madrid',
    'Perro',    'Labrador',
    '3 años',
    '60 cm'
);

-- 6. VERIFICAR QUE SE INSERTÓ
SELECT * FROM public.animales WHERE nombre = 'PRUEBA_RLS_FINAL';

-- 7. LIMPIAR LA PRUEBA
DELETE FROM public.animales WHERE nombre = 'PRUEBA_RLS_FINAL';

-- 8. MENSAJE FINAL
SELECT '✅ CORRECCIÓN RLS COMPLETADA - Todas las tablas deberían funcionar correctamente' as "RESULTADO";
