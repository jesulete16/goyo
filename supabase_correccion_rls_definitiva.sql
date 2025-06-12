-- 🛠️ CORRECCIÓN DEFINITIVA RLS - TABLA ANIMALES
-- Ejecutar DESPUÉS del diagnóstico para resolver el problema

-- ============================================================================
-- OPCIÓN 1: DESHABILITAR RLS TEMPORALMENTE (MÁS DIRECTO)
-- ============================================================================
-- NOTA: Esto es la solución más rápida para desarrollo
-- En producción, deberías usar políticas RLS apropiadas

-- Deshabilitar RLS para la tabla animales
ALTER TABLE public.animales DISABLE ROW LEVEL SECURITY;

-- Verificar que se deshabilitó
SELECT 
    tablename,
    rowsecurity as "RLS_ENABLED"
FROM pg_tables 
WHERE tablename = 'animales';

-- ============================================================================
-- OPCIÓN 2: LIMPIAR Y RECREAR POLÍTICAS RLS
-- ============================================================================
-- Solo ejecutar si OPCIÓN 1 no funciona

-- Eliminar todas las políticas existentes
DROP POLICY IF EXISTS "allow_insert_animales" ON public.animales;
DROP POLICY IF EXISTS "allow_select_animales" ON public.animales;
DROP POLICY IF EXISTS "allow_update_animales" ON public.animales;
DROP POLICY IF EXISTS "allow_delete_animales" ON public.animales;

-- Crear políticas permisivas para desarrollo
CREATE POLICY "animales_insert_policy" ON public.animales
    FOR INSERT WITH CHECK (true);

CREATE POLICY "animales_select_policy" ON public.animales
    FOR SELECT USING (true);

CREATE POLICY "animales_update_policy" ON public.animales
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "animales_delete_policy" ON public.animales
    FOR DELETE USING (true);

-- Habilitar RLS con las nuevas políticas
ALTER TABLE public.animales ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- OPCIÓN 3: OTORGAR PERMISOS DIRECTOS (RESPALDO)
-- ============================================================================
-- Solo ejecutar si las opciones anteriores fallan

-- Otorgar todos los permisos al usuario público
GRANT ALL ON public.animales TO public;
GRANT ALL ON public.animales TO anon;
GRANT ALL ON public.animales TO authenticated;

-- Otorgar permisos en la secuencia (para el ID autoincremental)
GRANT USAGE, SELECT ON SEQUENCE animales_id_seq TO public;
GRANT USAGE, SELECT ON SEQUENCE animales_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE animales_id_seq TO authenticated;

-- ============================================================================
-- VERIFICACIÓN FINAL
-- ============================================================================
-- Probar INSERT después de aplicar las correcciones
INSERT INTO public.animales (
    nombre,
    especie,
    raza,
    edad_anos,
    edad_meses,
    peso,
    color,
    sexo,
    esterilizado,
    observaciones_medicas,
    created_at,
    updated_at
) VALUES (
    'PRUEBA_FINAL',
    'Gato',
    'Siamés',
    1,
    6,
    4.2,
    'Blanco',
    'Hembra',
    true,
    'Prueba final después de corrección RLS',
    NOW(),
    NOW()
);

-- Si el INSERT fue exitoso, eliminar el registro de prueba
DELETE FROM public.animales WHERE nombre = 'PRUEBA_FINAL';

-- Mostrar estado final
SELECT 
    'RLS Status' as tipo,
    tablename,
    rowsecurity as estado
FROM pg_tables 
WHERE tablename = 'animales'

UNION ALL

SELECT 
    'Política' as tipo,
    policyname as tablename,
    cmd as estado
FROM pg_policies 
WHERE tablename = 'animales';

-- ============================================================================
-- MENSAJE FINAL
-- ============================================================================
SELECT '✅ CORRECCIÓN RLS COMPLETADA - La tabla animales debería aceptar INSERT ahora' as resultado;
