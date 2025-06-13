-- 🔧 CORRECCIÓN RLS SOLO PARA TABLA CITAS
-- ================================================================
-- IMPORTANTE: Este script se enfoca solo en arreglar la tabla de citas
-- ================================================================

-- INSTRUCCIONES:
-- 1. Inicia sesión en tu panel de Supabase (https://app.supabase.com)
-- 2. Selecciona tu proyecto
-- 3. Ve a "SQL Editor"
-- 4. Crea un nuevo query o copia este contenido en una consulta existente
-- 5. Ejecuta el script

-- =====================================================================
-- PASO 1: DESHABILITAR RLS ESPECÍFICAMENTE PARA LA TABLA DE CITAS
-- =====================================================================
ALTER TABLE public.citas DISABLE ROW LEVEL SECURITY;

-- VERIFICACIÓN DE ESTADO RLS
SELECT 
    tablename as "TABLA", 
    CASE WHEN rowsecurity THEN 'ACTIVADO' ELSE 'DESACTIVADO' END as "ESTADO_RLS"
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'citas';

-- =====================================================================
-- PASO 2: CONFIGURAR PERMISOS COMPLETOS PARA LA TABLA DE CITAS
-- =====================================================================
GRANT ALL PRIVILEGES ON TABLE public.citas TO authenticated, anon, service_role;

-- Otorgar permisos de secuencia (si hay autoincremento)
DO $$
DECLARE
    seq_name text;
BEGIN
    FOR seq_name IN 
        SELECT sequence_name FROM information_schema.sequences 
        WHERE sequence_schema = 'public' AND sequence_name LIKE '%cita%'
    LOOP
        EXECUTE 'GRANT USAGE, SELECT ON SEQUENCE public.' || seq_name || ' TO authenticated, anon';
    END LOOP;
END;
$$;

-- =====================================================================
-- PASO 3: VERIFICAR CONFIGURACIÓN
-- =====================================================================
DO $$
DECLARE
    test_animal_id uuid := 'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a16'; -- ID de un animal existente (Max)
    test_vet_id uuid := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';    -- ID de un veterinario existente (Dr. Carlos)
    test_cita_id uuid;
BEGIN
    -- Insertar cita de prueba
    INSERT INTO public.citas (
        animal_id, 
        veterinario_id, 
        fecha, 
        hora_inicio, 
        hora_fin, 
        motivo, 
        estado, 
        precio
    ) VALUES (
        test_animal_id,
        test_vet_id,
        '2025-06-20',  -- Una fecha futura (viernes)
        '10:00:00',
        '10:30:00',
        'PRUEBA RLS CITAS',
        'programada',
        0.00
    )
    RETURNING id INTO test_cita_id;

    -- Verificar que se insertó
    RAISE NOTICE '✅ Cita de prueba creada con ID: %', test_cita_id;
    
    -- Eliminar la cita de prueba
    DELETE FROM public.citas WHERE id = test_cita_id;
    RAISE NOTICE '✅ Cita de prueba eliminada correctamente';

    RAISE NOTICE '✅ CORRECCIÓN RLS PARA CITAS COMPLETADA';
END;
$$;

-- =====================================================================
-- PASO 4: INSTRUCCIONES PARA TU APLICACIÓN
-- =====================================================================
-- 1. El RLS para la tabla citas ahora está desactivado
-- 2. Tu aplicación Flutter debería poder crear citas sin problemas
-- 3. Si sigues teniendo problemas con citas, verifica que:
--    - No haya restricciones en la tabla que impidan ciertos valores
--    - Los IDs de animal y veterinario sean válidos
--    - La fecha y hora cumplan con el formato correcto
--
-- NOTA: Este script solo afecta a la tabla de citas. Si tienes problemas
-- con otras tablas, usa el script 'supabase_fix_rls_admin.sql'
