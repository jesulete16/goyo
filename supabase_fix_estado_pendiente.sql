-- Script para agregar el estado 'pendiente' a la tabla citas
-- Esto permite que las citas puedan estar en estado pendiente hasta que el veterinario las apruebe

-- Primero, vamos a ver la restricción actual
-- La restricción probablemente permite solo: 'programada', 'confirmada', 'completada', 'cancelada'

-- Eliminar la restricción existente
ALTER TABLE citas DROP CONSTRAINT IF EXISTS citas_estado_check;

-- Crear una nueva restricción que incluya 'pendiente'
ALTER TABLE citas ADD CONSTRAINT citas_estado_check 
CHECK (estado IN ('pendiente', 'programada', 'confirmada', 'completada', 'cancelada'));

-- Verificar que la restricción se creó correctamente
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_name = 'citas_estado_check';

-- Comentario sobre el flujo de estados:
-- 1. 'pendiente' - Cita solicitada por el usuario, esperando aprobación del veterinario
-- 2. 'programada' - Cita aprobada por el veterinario y confirmada
-- 3. 'confirmada' - Cita confirmada por el sistema (opcional)
-- 4. 'completada' - Cita realizada exitosamente
-- 5. 'cancelada' - Cita cancelada por veterinario o usuario
