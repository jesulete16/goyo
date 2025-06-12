-- 🔍 VERIFICACIÓN FINAL GOYO - DIAGNÓSTICO COMPLETO
-- ================================================================
-- EJECUTAR ESTE SCRIPT ANTES Y DESPUÉS DEL FIX RLS
-- ================================================================

-- 1. VERIFICAR ESTADO RLS DE TABLAS PRINCIPALES
SELECT 
    schemaname as "ESQUEMA",
    tablename as "TABLA",
    rowsecurity as "RLS_ACTIVO",
    CASE 
        WHEN rowsecurity = true THEN '🔒 ACTIVO'
        ELSE '🔓 DESACTIVADO'
    END as "ESTADO"
FROM pg_tables 
WHERE tablename IN ('animales', 'veterinarios')
ORDER BY tablename;

-- 2. CONTAR REGISTROS EXISTENTES
SELECT 
    'animales' as tabla,
    COUNT(*) as total_registros
FROM public.animales
UNION ALL
SELECT 
    'veterinarios' as tabla,
    COUNT(*) as total_registros  
FROM public.veterinarios;

-- 3. VERIFICAR ESTRUCTURA DE TABLA ANIMALES
SELECT 
    column_name as "COLUMNA",
    data_type as "TIPO",
    is_nullable as "PERMITE_NULL",
    column_default as "VALOR_DEFAULT"
FROM information_schema.columns
WHERE table_name = 'animales'
ORDER BY ordinal_position;

-- 4. VERIFICAR FUNCIÓN verify_password EXISTE
SELECT 
    routine_name as "FUNCIÓN",
    routine_type as "TIPO",
    CASE 
        WHEN routine_name = 'verify_password' THEN '✅ DISPONIBLE'
        ELSE '❌ NO ENCONTRADA'
    END as "ESTADO"
FROM information_schema.routines
WHERE routine_name = 'verify_password';

-- 5. PROBAR INSERT DE PRUEBA (SOLO DESPUÉS DE DESHABILITAR RLS)
-- NOTA: Ejecutar solo después del fix RLS
/*
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
    'Test Animal',
    'test@goyo.com',
    'test_password_hash',
    'Test Location',
    'Perro',
    'Labrador',
    3,
    60.5
) ON CONFLICT (correo) DO NOTHING;
*/

-- 6. VERIFICAR POLÍTICAS RLS EXISTENTES
SELECT 
    tablename as "TABLA",
    policyname as "POLÍTICA",
    cmd as "COMANDO",
    qual as "CONDICIÓN"
FROM pg_policies
WHERE tablename IN ('animales', 'veterinarios')
ORDER BY tablename, policyname;

-- ================================================================
-- RESULTADO ESPERADO DESPUÉS DEL FIX:
-- 
-- 1. RLS_ACTIVO debe ser 'false' para tabla 'animales'
-- 2. verify_password debe aparecer como 'DISPONIBLE'
-- 3. Insert de prueba debe ejecutarse sin errores
-- ================================================================
