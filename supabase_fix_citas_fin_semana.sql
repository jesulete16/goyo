-- ===============================================================
-- SCRIPT PARA CORREGIR PROBLEMA DE CITAS EN FINES DE SEMANA
-- ===============================================================
-- Este script crea datos de ejemplo que respetan las restricciones
-- de no permitir citas en fines de semana (sábados y domingos)

-- Limpiar datos existentes de citas de ejemplo (opcional)
DELETE FROM citas WHERE motivo LIKE '%ejemplo%';

-- Insertar citas de ejemplo solo en días laborales (Lunes a Viernes)
DO $$
DECLARE
    animal_id UUID;
    vet_id UUID;
    fecha_cita DATE;
    contador INTEGER := 0;
BEGIN
    -- Obtener un animal y veterinario para las citas de ejemplo
    SELECT id INTO animal_id FROM animales LIMIT 1;
    SELECT id INTO vet_id FROM veterinarios LIMIT 1;
    
    -- Verificar que existen datos
    IF animal_id IS NULL OR vet_id IS NULL THEN
        RAISE NOTICE 'No hay animales o veterinarios en la BD para crear citas de ejemplo';
        RETURN;
    END IF;
    
    -- Crear citas para los próximos 10 días laborales
    fecha_cita := CURRENT_DATE;
    
    WHILE contador < 10 LOOP
        -- Solo proceder si es día laboral (1=Lunes a 5=Viernes)
        IF EXTRACT(DOW FROM fecha_cita) BETWEEN 1 AND 5 THEN
            -- Insertar cita de mañana
            INSERT INTO citas (animal_id, veterinario_id, fecha, hora_inicio, hora_fin, motivo, estado)
            VALUES (
                animal_id,
                vet_id,
                fecha_cita,
                '10:00:00',
                '10:30:00',
                'Consulta general - ejemplo día ' || contador,
                'programada'
            )
            ON CONFLICT (veterinario_id, fecha, hora_inicio) DO NOTHING;
            
            -- Insertar cita de tarde
            INSERT INTO citas (animal_id, veterinario_id, fecha, hora_inicio, hora_fin, motivo, estado)
            VALUES (
                animal_id,
                vet_id,
                fecha_cita,
                '18:00:00',
                '18:30:00',
                'Vacunación - ejemplo día ' || contador,
                'programada'
            )
            ON CONFLICT (veterinario_id, fecha, hora_inicio) DO NOTHING;
            
            contador := contador + 1;
        END IF;
        
        fecha_cita := fecha_cita + INTERVAL '1 day';
    END LOOP;
    
    RAISE NOTICE 'Se crearon citas de ejemplo para % días laborales', contador;
END $$;

-- Verificar que las citas se crearon correctamente
SELECT 
    c.fecha,
    CASE EXTRACT(DOW FROM c.fecha)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 0 THEN 'Domingo'
    END as dia_semana,
    c.hora_inicio,
    c.hora_fin,
    c.motivo,
    c.estado
FROM citas c
WHERE c.motivo LIKE '%ejemplo%'
ORDER BY c.fecha, c.hora_inicio;

-- Mostrar información sobre las restricciones
SELECT 
    'Restricción check_no_fin_semana activa' as info,
    'Solo se permiten citas de Lunes a Viernes' as descripcion
UNION ALL
SELECT 
    'Horarios permitidos' as info,
    'Mañana: 09:00-13:30, Tarde: 17:00-20:30' as descripcion;
