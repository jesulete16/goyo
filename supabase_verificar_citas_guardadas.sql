-- ===============================================================
-- SCRIPT PARA VERIFICAR CITAS GUARDADAS DESDE LA APP
-- ===============================================================
-- Este script te permite verificar que las citas se están guardando
-- correctamente desde el widget cita_calendar.dart

-- 1. Mostrar todas las citas recientes (últimas 24 horas)
SELECT 
    'CITAS RECIENTES (últimas 24 horas)' as seccion;

SELECT 
    c.id,
    a.nombre as animal_nombre,
    a.especie,
    v.nombre as veterinario_nombre,
    c.fecha,
    c.hora_inicio,
    c.hora_fin,
    c.estado,
    c.motivo,
    c.created_at,
    CASE EXTRACT(DOW FROM c.fecha)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 0 THEN 'Domingo'
    END as dia_semana
FROM citas c
JOIN animales a ON c.animal_id = a.id
JOIN veterinarios v ON c.veterinario_id = v.id
WHERE c.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY c.created_at DESC;

-- 2. Mostrar citas de hoy
SELECT 
    'CITAS DE HOY' as seccion;

SELECT 
    c.id,
    a.nombre as animal_nombre,
    v.nombre as veterinario_nombre,
    c.fecha,
    c.hora_inicio,
    c.hora_fin,
    c.estado,
    c.created_at
FROM citas c
JOIN animales a ON c.animal_id = a.id
JOIN veterinarios v ON c.veterinario_id = v.id
WHERE c.fecha = CURRENT_DATE
ORDER BY c.hora_inicio;

-- 3. Mostrar próximas citas (próximos 7 días)
SELECT 
    'PRÓXIMAS CITAS (próximos 7 días)' as seccion;

SELECT 
    c.id,
    a.nombre as animal_nombre,
    a.especie,
    v.nombre as veterinario_nombre,
    c.fecha,
    c.hora_inicio,
    c.hora_fin,
    c.estado,
    c.motivo,
    CASE EXTRACT(DOW FROM c.fecha)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 0 THEN 'Domingo'
    END as dia_semana
FROM citas c
JOIN animales a ON c.animal_id = a.id
JOIN veterinarios v ON c.veterinario_id = v.id
WHERE c.fecha BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
  AND c.estado = 'programada'
ORDER BY c.fecha, c.hora_inicio;

-- 4. Verificar que no hay citas en fines de semana
SELECT 
    'VERIFICACIÓN: ¿Hay citas en fines de semana?' as seccion;

SELECT 
    COUNT(*) as citas_fin_semana,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Correcto: No hay citas en fines de semana'
        ELSE '❌ Error: Hay citas en fines de semana'
    END as resultado
FROM citas 
WHERE EXTRACT(DOW FROM fecha) IN (0, 6); -- 0=Domingo, 6=Sábado

-- 5. Mostrar estadísticas de citas por día de la semana
SELECT 
    'ESTADÍSTICAS POR DÍA DE LA SEMANA' as seccion;

SELECT 
    CASE EXTRACT(DOW FROM fecha)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 0 THEN 'Domingo'
    END as dia_semana,
    COUNT(*) as total_citas,
    COUNT(CASE WHEN estado = 'programada' THEN 1 END) as citas_programadas,
    COUNT(CASE WHEN estado = 'completada' THEN 1 END) as citas_completadas,
    COUNT(CASE WHEN estado = 'cancelada' THEN 1 END) as citas_canceladas
FROM citas
WHERE fecha >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY EXTRACT(DOW FROM fecha)
ORDER BY EXTRACT(DOW FROM fecha);

-- 6. Verificar restricciones de horario
SELECT 
    'VERIFICACIÓN: ¿Hay citas fuera de horario?' as seccion;

SELECT 
    COUNT(*) as citas_fuera_horario,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Correcto: Todas las citas están en horario válido'
        ELSE '❌ Error: Hay citas fuera de horario'
    END as resultado
FROM citas 
WHERE NOT (
    (hora_inicio >= '09:00:00' AND hora_fin <= '13:30:00') OR
    (hora_inicio >= '17:00:00' AND hora_fin <= '20:30:00')
);

-- 7. Mostrar citas que fallan alguna restricción (para debugging)
SELECT 
    'CITAS CON PROBLEMAS (si las hay)' as seccion;

SELECT 
    c.id,
    c.fecha,
    c.hora_inicio,
    c.hora_fin,
    EXTRACT(DOW FROM c.fecha) as dia_semana_num,
    CASE 
        WHEN EXTRACT(DOW FROM c.fecha) IN (0, 6) THEN 'Fin de semana'
        WHEN NOT (
            (c.hora_inicio >= '09:00:00' AND c.hora_fin <= '13:30:00') OR
            (c.hora_inicio >= '17:00:00' AND c.hora_fin <= '20:30:00')
        ) THEN 'Fuera de horario'
        ELSE 'OK'
    END as problema
FROM citas c
WHERE EXTRACT(DOW FROM c.fecha) IN (0, 6) -- Fin de semana
   OR NOT (
       (c.hora_inicio >= '09:00:00' AND c.hora_fin <= '13:30:00') OR
       (c.hora_inicio >= '17:00:00' AND c.hora_fin <= '20:30:00')
   ); -- Fuera de horario

-- 8. Mostrar resumen general
SELECT 
    'RESUMEN GENERAL' as seccion;

SELECT 
    'Total de citas' as metrica,
    COUNT(*) as valor
FROM citas
UNION ALL
SELECT 
    'Citas programadas',
    COUNT(*)
FROM citas WHERE estado = 'programada'
UNION ALL
SELECT 
    'Citas de hoy',
    COUNT(*)
FROM citas WHERE fecha = CURRENT_DATE
UNION ALL
SELECT 
    'Citas esta semana',
    COUNT(*)
FROM citas 
WHERE fecha >= date_trunc('week', CURRENT_DATE)
  AND fecha < date_trunc('week', CURRENT_DATE) + INTERVAL '7 days'
UNION ALL
SELECT 
    'Últimas 24 horas',
    COUNT(*)
FROM citas WHERE created_at >= NOW() - INTERVAL '24 hours';

-- Instrucciones de uso:
-- 1. Ejecuta este script después de crear citas desde la app
-- 2. Verifica que las citas aparecen en "CITAS RECIENTES"
-- 3. Confirma que no hay citas en fines de semana
-- 4. Verifica que todas las citas están en horarios válidos
