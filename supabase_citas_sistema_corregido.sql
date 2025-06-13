-- ========================================
-- SCRIPT SQL CORREGIDO PARA SISTEMA DE CITAS GOYO
-- Estructura actualizada para coincidir con BD real (UUIDs)
-- Fecha: 12 de junio 2025
-- ========================================

-- VERIFICAR ESTRUCTURA EXISTENTE
-- Primero verificamos que las tablas existen con la estructura correcta

-- ========================================
-- VERIFICACIÓN DE TABLA VETERINARIOS
-- ========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'veterinarios') THEN
        RAISE EXCEPTION 'Tabla veterinarios no existe. Debe crearse primero.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'veterinarios' AND column_name = 'id' AND data_type = 'uuid') THEN
        RAISE EXCEPTION 'Columna id en veterinarios debe ser UUID.';
    END IF;
END $$;

-- ========================================
-- VERIFICACIÓN DE TABLA ANIMALES
-- ========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'animales') THEN
        RAISE EXCEPTION 'Tabla animales no existe. Debe crearse primero.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'animales' AND column_name = 'id' AND data_type = 'uuid') THEN
        RAISE EXCEPTION 'Columna id en animales debe ser UUID.';
    END IF;
END $$;

-- ========================================
-- CREAR/ACTUALIZAR TABLA HORARIOS_VETERINARIO
-- ========================================
CREATE TABLE IF NOT EXISTS horarios_veterinario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    veterinario_id UUID NOT NULL REFERENCES veterinarios(id) ON DELETE CASCADE,
    dia_semana INTEGER NOT NULL CHECK (dia_semana >= 1 AND dia_semana <= 7), -- 1=Lunes, 7=Domingo
    hora_inicio_mañana TIME DEFAULT '09:00:00',
    hora_fin_mañana TIME DEFAULT '13:30:00',
    hora_inicio_tarde TIME DEFAULT '17:00:00',
    hora_fin_tarde TIME DEFAULT '20:30:00',
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para horarios_veterinario
CREATE INDEX IF NOT EXISTS idx_horarios_veterinario_id ON horarios_veterinario(veterinario_id);
CREATE INDEX IF NOT EXISTS idx_horarios_dia_semana ON horarios_veterinario(dia_semana);
CREATE UNIQUE INDEX IF NOT EXISTS idx_horarios_veterinario_dia_unico 
    ON horarios_veterinario(veterinario_id, dia_semana);

-- ========================================
-- CREAR/ACTUALIZAR TABLA CITAS
-- ========================================
CREATE TABLE IF NOT EXISTS citas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id UUID NOT NULL REFERENCES animales(id) ON DELETE CASCADE,
    veterinario_id UUID NOT NULL REFERENCES veterinarios(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'programada' 
        CHECK (estado IN ('programada', 'confirmada', 'en_curso', 'completada', 'cancelada', 'no_asistio')),
    motivo TEXT DEFAULT 'Consulta general',
    notas TEXT,
    precio DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para citas
CREATE INDEX IF NOT EXISTS idx_citas_animal_id ON citas(animal_id);
CREATE INDEX IF NOT EXISTS idx_citas_veterinario_id ON citas(veterinario_id);
CREATE INDEX IF NOT EXISTS idx_citas_fecha ON citas(fecha);
CREATE INDEX IF NOT EXISTS idx_citas_estado ON citas(estado);
CREATE INDEX IF NOT EXISTS idx_citas_fecha_veterinario ON citas(fecha, veterinario_id);

-- Índice único para prevenir citas duplicadas en la misma hora
CREATE UNIQUE INDEX IF NOT EXISTS idx_citas_veterinario_fecha_hora_unica 
    ON citas(veterinario_id, fecha, hora_inicio) 
    WHERE estado NOT IN ('cancelada', 'no_asistio');

-- ========================================
-- TRIGGERS PARA UPDATED_AT
-- ========================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para horarios_veterinario
DROP TRIGGER IF EXISTS update_horarios_veterinario_updated_at ON horarios_veterinario;
CREATE TRIGGER update_horarios_veterinario_updated_at 
    BEFORE UPDATE ON horarios_veterinario 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para citas
DROP TRIGGER IF EXISTS update_citas_updated_at ON citas;
CREATE TRIGGER update_citas_updated_at 
    BEFORE UPDATE ON citas 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- FUNCIÓN PARA VERIFICAR CONFLICTOS DE CITAS
-- ========================================
CREATE OR REPLACE FUNCTION verificar_conflicto_citas()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar si hay conflicto de horarios
    IF EXISTS (
        SELECT 1 FROM citas 
        WHERE veterinario_id = NEW.veterinario_id 
        AND fecha = NEW.fecha 
        AND estado NOT IN ('cancelada', 'no_asistio')
        AND id != COALESCE(NEW.id, gen_random_uuid())
        AND (
            (NEW.hora_inicio >= hora_inicio AND NEW.hora_inicio < hora_fin) OR
            (NEW.hora_fin > hora_inicio AND NEW.hora_fin <= hora_fin) OR
            (NEW.hora_inicio <= hora_inicio AND NEW.hora_fin >= hora_fin)
        )
    ) THEN
        RAISE EXCEPTION 'Ya existe una cita programada para este veterinario en ese horario';
    END IF;
    
    -- Verificar que hora_fin sea posterior a hora_inicio
    IF NEW.hora_fin <= NEW.hora_inicio THEN
        RAISE EXCEPTION 'La hora de fin debe ser posterior a la hora de inicio';
    END IF;
    
    -- Verificar que la cita no sea en el pasado
    IF NEW.fecha < CURRENT_DATE THEN
        RAISE EXCEPTION 'No se pueden programar citas en fechas pasadas';
    END IF;
    
    -- Si es hoy, verificar que la hora no sea pasada
    IF NEW.fecha = CURRENT_DATE AND NEW.hora_inicio < CURRENT_TIME THEN
        RAISE EXCEPTION 'No se pueden programar citas en horas pasadas';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para verificar conflictos
DROP TRIGGER IF EXISTS trigger_verificar_conflicto_citas ON citas;
CREATE TRIGGER trigger_verificar_conflicto_citas
    BEFORE INSERT OR UPDATE ON citas
    FOR EACH ROW
    EXECUTE FUNCTION verificar_conflicto_citas();

-- ========================================
-- INSERTAR HORARIOS POR DEFECTO PARA VETERINARIOS EXISTENTES
-- ========================================

-- Insertar horarios de lunes a viernes para todos los veterinarios que no tengan horarios
INSERT INTO horarios_veterinario (veterinario_id, dia_semana)
SELECT v.id, d.dia
FROM veterinarios v
CROSS JOIN (VALUES (1), (2), (3), (4), (5)) AS d(dia) -- Lunes a Viernes
WHERE NOT EXISTS (
    SELECT 1 FROM horarios_veterinario h 
    WHERE h.veterinario_id = v.id AND h.dia_semana = d.dia
);

-- ========================================
-- DATOS DE EJEMPLO (OPCIONAL)
-- ========================================

-- Insertar algunos ejemplos de citas para testing (solo si no existen)
DO $$
DECLARE
    vet_id UUID;
    animal_id UUID;
BEGIN
    -- Obtener un veterinario y un animal de ejemplo
    SELECT id INTO vet_id FROM veterinarios LIMIT 1;
    SELECT id INTO animal_id FROM animales LIMIT 1;
    
    -- Solo insertar si tenemos veterinario y animal
    IF vet_id IS NOT NULL AND animal_id IS NOT NULL THEN
        -- Cita de ejemplo para mañana a las 10:00
        INSERT INTO citas (animal_id, veterinario_id, fecha, hora_inicio, hora_fin, motivo)
        VALUES (
            animal_id,
            vet_id,
            CURRENT_DATE + INTERVAL '1 day',
            '10:00:00',
            '10:30:00',
            'Consulta de ejemplo'
        )
        ON CONFLICT DO NOTHING;
        
        -- Cita de ejemplo para pasado mañana a las 17:30
        INSERT INTO citas (animal_id, veterinario_id, fecha, hora_inicio, hora_fin, motivo)
        VALUES (
            animal_id,
            vet_id,
            CURRENT_DATE + INTERVAL '2 days',
            '17:30:00',
            '18:00:00',
            'Vacunación de ejemplo'
        )
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- ========================================
-- VERIFICACIÓN FINAL
-- ========================================

-- Verificar que todo se creó correctamente
DO $$
BEGIN
    -- Verificar tablas
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'horarios_veterinario') THEN
        RAISE EXCEPTION 'Error: Tabla horarios_veterinario no se creó';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'citas') THEN
        RAISE EXCEPTION 'Error: Tabla citas no se creó';
    END IF;
    
    -- Verificar triggers
    IF NOT EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trigger_verificar_conflicto_citas') THEN
        RAISE EXCEPTION 'Error: Trigger de verificación de conflictos no se creó';
    END IF;
    
    RAISE NOTICE '✅ Sistema de citas configurado correctamente';
    RAISE NOTICE '✅ Tablas: horarios_veterinario, citas';
    RAISE NOTICE '✅ Triggers: actualización automática, verificación de conflictos';
    RAISE NOTICE '✅ Índices: optimización de consultas';
    RAISE NOTICE '✅ Horarios por defecto: Lunes a Viernes 9:00-13:30 y 17:00-20:30';
END $$;

-- ========================================
-- CONSULTAS ÚTILES PARA VERIFICACIÓN
-- ========================================

-- Ver horarios de todos los veterinarios
-- SELECT v.nombre, h.dia_semana, h.hora_inicio_mañana, h.hora_fin_mañana, h.hora_inicio_tarde, h.hora_fin_tarde
-- FROM veterinarios v
-- JOIN horarios_veterinario h ON v.id = h.veterinario_id
-- ORDER BY v.nombre, h.dia_semana;

-- Ver citas programadas
-- SELECT 
--     v.nombre as veterinario,
--     a.nombre as animal,
--     c.fecha,
--     c.hora_inicio,
--     c.hora_fin,
--     c.estado,
--     c.motivo
-- FROM citas c
-- JOIN veterinarios v ON c.veterinario_id = v.id
-- JOIN animales a ON c.animal_id = a.id
-- ORDER BY c.fecha, c.hora_inicio;
