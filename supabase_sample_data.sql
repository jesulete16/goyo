-- ============================================================================
-- GOYO - Sistema Veterinario
-- DATOS POR DEFECTO PARA TESTING
-- ============================================================================

-- IMPORTANTE: Ejecutar este script DESPUÉS de haber ejecutado supabase_database.sql

-- ============================================================================
-- DATOS DE EJEMPLO - VETERINARIOS
-- ============================================================================
INSERT INTO public.veterinarios (
    id,
    nombre,
    correo,
    foto_url,
    contraseña,
    ubicacion,
    especialidad,
    numero_colegiado,
    años_experiencia,
    telefono
) VALUES 
(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Dr. Carlos Martínez',
    'carlos.martinez@goyo.vet',
    'https://example.com/veterinario1.jpg',
    '123456', -- Se encriptará automáticamente
    'Madrid',
    'Perro',
    'MAD-001',
    15,
    '+34 600 123 456'
),
(
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
    'Dra. María González',
    'maria.gonzalez@goyo.vet',
    'https://example.com/veterinario2.jpg',
    '123456',
    'Barcelona',
    'Gato',
    'BCN-002',
    12,
    '+34 600 234 567'
),
(
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13',
    'Dr. Antonio López',
    'antonio.lopez@goyo.vet',
    'https://example.com/veterinario3.jpg',
    '123456',
    'Valencia',
    'General',
    'VAL-003',
    8,
    '+34 600 345 678'
),
(
    'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14',
    'Dra. Laura Sánchez',
    'laura.sanchez@goyo.vet',
    'https://example.com/veterinario4.jpg',
    '123456',
    'Sevilla',
    'Pájaro',
    'SEV-004',
    10,
    '+34 600 456 789'
),
(
    'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15',
    'Dr. Roberto García',
    'roberto.garcia@goyo.vet',
    'https://example.com/veterinario5.jpg',
    '123456',
    'Madrid',
    'Caballo',
    'MAD-005',
    20,
    '+34 600 567 890'
);

-- ============================================================================
-- DATOS DE EJEMPLO - ANIMALES
-- ============================================================================
INSERT INTO public.animales (
    id,
    nombre,
    correo,
    foto_url,
    contraseña,
    ubicacion,
    tipo,
    raza,
    edad,
    altura
) VALUES 
(
    'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a16',
    'Max',
    'propietario.max@gmail.com',
    'https://example.com/animal1.jpg',
    '123456', -- Se encriptará automáticamente
    'Madrid',
    'Perro',
    'Labrador Retriever',
    '3 años',
    '60 cm'
),
(    '10eebc99-9c0b-4ef8-bb6d-6bb9bd380a17',
    'Luna',
    'propietario.luna@gmail.com',
    'https://example.com/animal2.jpg',
    '123456',
    'Barcelona',
    'Gato',
    'Persa',
    '2 años',
    '25 cm'
),
(
    '20eebc99-9c0b-4ef8-bb6d-6bb9bd380a18',
    'Rocky',
    'propietario.rocky@gmail.com',
    'https://example.com/animal3.jpg',
    '123456',
    'Valencia',
    'Perro',
    'Pastor Alemán',
    '5 años',
    '65 cm'
),
(
    '30eebc99-9c0b-4ef8-bb6d-6bb9bd380a19',
    'Coco',
    'propietario.coco@gmail.com',
    'https://example.com/animal4.jpg',
    '123456',
    'Sevilla',
    'Pájaro',
    'Canario',
    '1 año',
    '12 cm'
),
(
    '40eebc99-9c0b-4ef8-bb6d-6bb9bd380a20',
    'Bella',
    'propietario.bella@gmail.com',
    'https://example.com/animal5.jpg',
    '123456',
    'Madrid',
    'Gato',
    'Siamés',
    '4 años',
    '30 cm'
),
(
    '50eebc99-9c0b-4ef8-bb6d-6bb9bd380a21',
    'Thor',
    'propietario.thor@gmail.com',
    'https://example.com/animal6.jpg',
    '123456',
    'Madrid',
    'Caballo',
    'Andaluz',
    '8 años',
    '1.6 metros'
),
(
    '60eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'Nemo',
    'propietario.nemo@gmail.com',
    'https://example.com/animal7.jpg',
    '123456',
    'Barcelona',
    'Pez',
    'Goldfish',
    '6 meses',
    '8 cm'
),
(
    '70eebc99-9c0b-4ef8-bb6d-6bb9bd380a23',
    'Bongo',
    'propietario.bongo@gmail.com',
    'https://example.com/animal8.jpg',
    '123456',
    'Valencia',
    'Conejo',
    'Holandés',
    '2 años',
    '20 cm'
);

-- ============================================================================
-- DATOS DE EJEMPLO - CITAS PROGRAMADAS
-- ============================================================================
-- Citas para la próxima semana (ajusta las fechas según necesites)
INSERT INTO public.citas (
    id,
    animal_id,
    veterinario_id,
    fecha,
    hora_inicio,
    hora_fin,
    motivo,
    estado,
    precio
) VALUES 
(
    '80eebc99-9c0b-4ef8-bb6d-6bb9bd380a24',
    'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a16', -- Max
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- Dr. Carlos Martínez
    '2025-06-16', -- Lunes
    '09:00:00',
    '09:30:00',
    'Revisión general y vacunas',
    'programada',
    45.00
),
(    '90eebc99-9c0b-4ef8-bb6d-6bb9bd380a25',
    '10eebc99-9c0b-4ef8-bb6d-6bb9bd380a17', -- Luna
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', -- Dra. María González
    '2025-06-17', -- Martes
    '10:00:00',
    '10:30:00',
    'Control post-operatorio',
    'confirmada',
    60.00
),
(    'a1eebc99-9c0b-4ef8-bb6d-6bb9bd380a26',
    '20eebc99-9c0b-4ef8-bb6d-6bb9bd380a18', -- Rocky
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', -- Dr. Antonio López
    '2025-06-18', -- Miércoles
    '17:00:00',
    '17:45:00',
    'Problemas digestivos',
    'programada',
    55.00
),
(    'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a27',
    '30eebc99-9c0b-4ef8-bb6d-6bb9bd380a19', -- Coco
    'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14', -- Dra. Laura Sánchez
    '2025-06-19', -- Jueves
    '11:30:00',
    '12:00:00',
    'Revisión de plumaje',
    'programada',
    35.00
),
(    'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a28',
    '40eebc99-9c0b-4ef8-bb6d-6bb9bd380a20', -- Bella
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', -- Dra. María González
    '2025-06-20', -- Viernes
    '18:00:00',
    '18:30:00',
    'Esterilización',
    'programada',
    120.00
),
(    'd1eebc99-9c0b-4ef8-bb6d-6bb9bd380a29',
    '50eebc99-9c0b-4ef8-bb6d-6bb9bd380a21', -- Thor
    'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15', -- Dr. Roberto García
    '2025-06-16', -- Lunes
    '17:30:00',
    '18:30:00',
    'Revisión de cascos y herraje',
    'programada',
    80.00
);

-- ============================================================================
-- DATOS HISTÓRICOS - CITAS COMPLETADAS
-- ============================================================================
INSERT INTO public.citas (
    animal_id,
    veterinario_id,
    fecha,
    hora_inicio,
    hora_fin,
    motivo,
    notas_veterinario,
    estado,
    precio
) VALUES 
(
    'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a16', -- Max
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- Dr. Carlos Martínez
    '2025-05-15',
    '10:00:00',
    '10:30:00',
    'Vacuna anual',
    'Vacunación completada sin incidencias. Próxima cita en un año.',
    'completada',
    40.00
),
(
    '10eebc99-9c0b-4ef8-bb6d-6bb9bd380a17', -- Luna
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', -- Dra. María González
    '2025-05-20',
    '17:15:00',
    '18:00:00',
    'Cirugía menor',
    'Extracción de tumor benigno. Recuperación favorable.',
    'completada',
    150.00
),
(
    '20eebc99-9c0b-4ef8-bb6d-6bb9bd380a18', -- Rocky
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', -- Dr. Antonio López
    '2025-06-02',
    '09:30:00',
    '10:00:00',
    'Revisión rutinaria',
    'Animal en excelente estado de salud.',
    'completada',
    35.00
),
(
    '30eebc99-9c0b-4ef8-bb6d-6bb9bd380a19', -- Coco
    'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14', -- Dra. Laura Sánchez
    '2025-05-28',
    '11:00:00',
    '11:30:00',
    'Control de salud',
    'Ave en perfecto estado. Se recomienda seguir con la dieta actual.',
    'completada',
    30.00
),
(
    '40eebc99-9c0b-4ef8-bb6d-6bb9bd380a20', -- Bella
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', -- Dra. María González
    '2025-04-10',
    '17:30:00',
    '18:00:00',
    'Desparasitación',
    'Tratamiento antiparasitario aplicado correctamente.',
    'completada',
    25.00
);

-- ============================================================================
-- CITAS ADICIONALES PARA DIVERSIDAD DE DATOS
-- ============================================================================
INSERT INTO public.citas (
    animal_id,
    veterinario_id,
    fecha,
    hora_inicio,
    hora_fin,
    motivo,
    estado,
    precio
) VALUES 
-- Citas futuras adicionales
(
    '60eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', -- Nemo
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', -- Dr. Antonio López
    '2025-06-17', -- Martes
    '17:30:00',
    '18:00:00',
    'Control de calidad del agua',
    'programada',
    25.00
),
(
    '70eebc99-9c0b-4ef8-bb6d-6bb9bd380a23', -- Bongo
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', -- Dr. Antonio López
    '2025-06-19', -- Jueves
    '09:30:00',
    '10:00:00',
    'Revisión dental',
    'programada',
    40.00
),
-- Más citas históricas
(
    '50eebc99-9c0b-4ef8-bb6d-6bb9bd380a21', -- Thor
    'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15', -- Dr. Roberto García
    '2025-05-08',
    '09:00:00',
    '10:00:00',
    'Entrenamiento y ejercicio',
    'completada',
    75.00
),
(
    '60eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', -- Nemo
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', -- Dr. Antonio López
    '2025-04-22',
    '18:00:00',
    '18:15:00',
    'Cambio de pecera',
    'completada',
    20.00
);

-- ============================================================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- ============================================================================

-- CREDENCIALES DE PRUEBA:
-- ========================================
-- Contraseña para todos los usuarios: 123456
-- 
-- VETERINARIOS:
-- - carlos.martinez@goyo.vet (Especialista en Perros, Madrid)
-- - maria.gonzalez@goyo.vet (Especialista en Gatos, Barcelona) 
-- - antonio.lopez@goyo.vet (Veterinario General, Valencia)
-- - laura.sanchez@goyo.vet (Especialista en Pájaros, Sevilla)
-- - roberto.garcia@goyo.vet (Especialista en Caballos, Madrid)
--
-- PROPIETARIOS DE ANIMALES:
-- - propietario.max@gmail.com (Max - Labrador Retriever, Madrid)
-- - propietario.luna@gmail.com (Luna - Gato Persa, Barcelona)
-- - propietario.rocky@gmail.com (Rocky - Pastor Alemán, Valencia)
-- - propietario.coco@gmail.com (Coco - Canario, Sevilla)
-- - propietario.bella@gmail.com (Bella - Gato Siamés, Madrid)
-- - propietario.thor@gmail.com (Thor - Caballo Andaluz, Madrid)
-- - propietario.nemo@gmail.com (Nemo - Goldfish, Barcelona)
-- - propietario.bongo@gmail.com (Bongo - Conejo Holandés, Valencia)

-- RESUMEN DE DATOS:
-- ========================================
-- • 5 Veterinarios con diferentes especialidades
-- • 8 Animales de tipos y razas variadas
-- • 6 Citas programadas para la semana del 16-20 junio 2025
-- • 7 Citas históricas completadas para demostrar historial
-- • 2 Citas adicionales futuras
--
-- INSTRUCCIONES DE USO:
-- ========================================
-- 1. Ejecutar primero: supabase_database.sql (configuración)
-- 2. Ejecutar después: este archivo (datos de prueba)
-- 3. Probar login con cualquier correo y contraseña "123456"
-- 4. Las fechas de citas están basadas en junio 2025
--
-- NOTA: Los UUIDs están fijos para facilitar testing.
-- En producción se generarán automáticamente.

-- Comentarios en las tablas para referencia
COMMENT ON TABLE public.animales IS 'Datos de ejemplo: 8 animales de diferentes tipos y razas para testing';
COMMENT ON TABLE public.veterinarios IS 'Datos de ejemplo: 5 veterinarios con especialidades variadas para testing';
COMMENT ON TABLE public.citas IS 'Datos de ejemplo: Citas programadas, confirmadas y completadas para testing';
