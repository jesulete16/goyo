-- 🔍 DIAGNÓSTICO COMPLETO RLS - TABLA ANIMALES
-- Ejecutar este script en Supabase SQL Editor para identificar el problema

-- ============================================================================
-- 1. VERIFICAR ESTADO ACTUAL DE RLS
-- ============================================================================
SELECT 
    schemaname,
    tablename,
    rowsecurity as "RLS_ENABLED",
    hasinserts as "PERMITE_INSERT",
    hasselects as "PERMITE_SELECT"
FROM pg_tables 
WHERE tablename = 'animales';

-- ============================================================================
-- 2. LISTAR TODAS LAS POLÍTICAS EXISTENTES
-- ============================================================================
SELECT 
    policyname as "NOMBRE_POLITICA",
    cmd as "COMANDO",
    permissive as "PERMISIVA",
    roles as "ROLES",
    qual as "CONDICION_WHERE",
    with_check as "CONDICION_CHECK"
FROM pg_policies 
WHERE tablename = 'animales'
ORDER BY cmd;

-- ============================================================================
-- 3. VERIFICAR PERMISOS DE LA TABLA
-- ============================================================================
SELECT 
    grantee as "USUARIO",
    privilege_type as "PERMISO",
    is_grantable as "PUEDE_OTORGAR"
FROM information_schema.table_privileges 
WHERE table_name = 'animales'
ORDER BY grantee, privilege_type;

-- ============================================================================
-- 4. VERIFICAR ROL ACTUAL Y PERMISOS
-- ============================================================================
SELECT current_user as "USUARIO_ACTUAL";
SELECT current_role as "ROL_ACTUAL";

-- ============================================================================
-- 5. PROBAR INSERT DIRECTO (PARA IDENTIFICAR ERROR ESPECÍFICO)
-- ============================================================================
-- NOTA: Este INSERT debería fallar, pero nos dará más información
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
    'TEST_DIAGNOSTICO',
    'Perro',
    'Mestizo',
    2,
    0,
    15.5,
    'Marrón',
    'Macho',
    false,
    'Animal de prueba para diagnóstico RLS',
    NOW(),
    NOW()
);

-- ============================================================================
-- 6. SI EL INSERT FALLA, ELIMINARLO
-- ============================================================================
DELETE FROM public.animales WHERE nombre = 'TEST_DIAGNOSTICO';

-- ============================================================================
-- 7. VERIFICAR SI HAY TRIGGERS QUE INTERFIEREN
-- ============================================================================
SELECT 
    trigger_name as "NOMBRE_TRIGGER",
    event_manipulation as "EVENTO",
    action_timing as "MOMENTO",
    action_statement as "ACCION"
FROM information_schema.triggers 
WHERE event_object_table = 'animales';

-- ============================================================================
-- 8. VERIFICAR FUNCIONES RLS PERSONALIZADAS
-- ============================================================================
SELECT 
    routine_name as "NOMBRE_FUNCION",
    routine_type as "TIPO"
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%animal%' 
OR routine_name LIKE '%rls%';
