-- 🔍 VERIFICACIÓN ESTRUCTURA TABLA ANIMALES
-- Ejecutar para verificar que la tabla tenga la estructura correcta

-- ============================================================================
-- 1. VERIFICAR ESTRUCTURA COMPLETA DE LA TABLA
-- ============================================================================
SELECT 
    column_name as "COLUMNA",
    data_type as "TIPO",
    is_nullable as "PERMITE_NULL",
    column_default as "VALOR_DEFAULT",
    character_maximum_length as "LONGITUD_MAX"
FROM information_schema.columns 
WHERE table_name = 'animales' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================================================
-- 2. VERIFICAR CONSTRAINTS Y CLAVES
-- ============================================================================
SELECT 
    constraint_name as "CONSTRAINT",
    constraint_type as "TIPO",
    column_name as "COLUMNA"
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'animales'
ORDER BY constraint_type;

-- ============================================================================
-- 3. VERIFICAR SECUENCIA PARA ID AUTOINCREMENTAL
-- ============================================================================
SELECT 
    sequence_name as "SECUENCIA",
    data_type as "TIPO",
    start_value as "VALOR_INICIO",
    increment as "INCREMENTO"
FROM information_schema.sequences 
WHERE sequence_name LIKE '%animales%';

-- ============================================================================
-- 4. PROBAR INSERCIÓN MÍNIMA (SOLO CAMPOS OBLIGATORIOS)
-- ============================================================================
-- Insertar con los mínimos campos requeridos
INSERT INTO public.animales (nombre, especie) 
VALUES ('PRUEBA_MINIMA', 'Perro');

-- Verificar que se insertó
SELECT * FROM public.animales WHERE nombre = 'PRUEBA_MINIMA';

-- Eliminar la prueba
DELETE FROM public.animales WHERE nombre = 'PRUEBA_MINIMA';

-- ============================================================================
-- 5. MOSTRAR TABLA COMPLETA (SI TIENE POCOS REGISTROS)
-- ============================================================================
SELECT COUNT(*) as "TOTAL_REGISTROS" FROM public.animales;

-- Solo mostrar contenido si hay menos de 10 registros
SELECT * FROM public.animales LIMIT 10;
