-- 🚨 SOLUCIÓN INMEDIATA - DESHABILITAR RLS PARA DESARROLLO
-- ================================================================
-- INSTRUCCIONES:
-- 1. Copiar este código
-- 2. Ir a Supabase Dashboard > SQL Editor  
-- 3. Pegar y ejecutar
-- 4. Probar el registro de animales inmediatamente
-- ================================================================

-- DESHABILITAR RLS EN TABLA ANIMALES (SOLUCIÓN INMEDIATA)
ALTER TABLE public.animales DISABLE ROW LEVEL SECURITY;

-- VERIFICAR QUE SE DESHABILITÓ CORRECTAMENTE
SELECT 
    tablename as "TABLA",
    rowsecurity as "RLS_ACTIVO"
FROM pg_tables 
WHERE tablename = 'animales';

-- PROBAR INSERT DIRECTO PARA CONFIRMAR QUE FUNCIONA
INSERT INTO public.animales (
    nombre,
    correo,
    contraseña,
    ubicacion,
    tipo,
    raza,
    edad,
    altura,
    created_at,
    updated_at
) VALUES (
    'PRUEBA_RLS_FIX',
    'prueba@test.com',
    'password123',
    'Madrid',
    'Perro',
    'Mestizo',
    '2 años',
    '50 cm',
    NOW(),
    NOW()
);

-- SI EL INSERT FUNCIONÓ, ELIMINAR EL REGISTRO DE PRUEBA
DELETE FROM public.animales WHERE nombre = 'PRUEBA_RLS_FIX';

-- MENSAJE DE CONFIRMACIÓN
SELECT '🎉 RLS DESHABILITADO - El registro de animales debería funcionar ahora' as "RESULTADO";

-- ================================================================
-- NOTA: Esto es seguro para desarrollo
-- En producción, necesitarás políticas RLS apropiadas
-- ================================================================
