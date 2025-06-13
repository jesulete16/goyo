-- 📅 SCRIPTS SQL PARA SISTEMA DE CITAS GOYO
-- ================================================================
-- Crear tablas necesarias para el sistema de calendario de citas
-- ================================================================

-- TABLA: horarios_veterinario
-- Almacena los horarios de trabajo de cada veterinario por día de la semana
CREATE TABLE IF NOT EXISTS public.horarios_veterinario (
    id SERIAL PRIMARY KEY,
    veterinario_id INTEGER REFERENCES public.veterinarios(id) ON DELETE CASCADE,
    dia_semana VARCHAR(10) NOT NULL, -- 'Lunes', 'Martes', etc.
    hora_inicio TIME NOT NULL DEFAULT '09:00:00',
    hora_fin_manana TIME DEFAULT '13:30:00',
    hora_inicio_tarde TIME DEFAULT '17:00:00', 
    hora_fin TIME NOT NULL DEFAULT '20:30:00',
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA: citas
-- Almacena todas las citas programadas entre animales y veterinarios
CREATE TABLE IF NOT EXISTS public.citas (
    id SERIAL PRIMARY KEY,
    animal_id INTEGER REFERENCES public.animales(id) ON DELETE CASCADE,
    veterinario_id INTEGER REFERENCES public.veterinarios(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    estado VARCHAR(20) DEFAULT 'programada', -- 'programada', 'completada', 'cancelada'
    motivo TEXT DEFAULT 'Consulta general',
    notas TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evitar citas duplicadas en el mismo horario
    UNIQUE(veterinario_id, fecha, hora)
);

-- ÍNDICES para mejorar performance
CREATE INDEX IF NOT EXISTS idx_horarios_veterinario_vet_dia 
ON public.horarios_veterinario(veterinario_id, dia_semana);

CREATE INDEX IF NOT EXISTS idx_citas_veterinario_fecha 
ON public.citas(veterinario_id, fecha);

CREATE INDEX IF NOT EXISTS idx_citas_animal_fecha 
ON public.citas(animal_id, fecha);

-- INSERTAR HORARIOS POR DEFECTO PARA TODOS LOS VETERINARIOS
-- Horarios estándar: 9:00-13:30 y 17:00-20:30 de Lunes a Viernes
INSERT INTO public.horarios_veterinario (veterinario_id, dia_semana, hora_inicio, hora_fin_manana, hora_inicio_tarde, hora_fin, activo)
SELECT 
    v.id,
    dia.nombre,
    '09:00:00'::TIME,
    '13:30:00'::TIME,
    '17:00:00'::TIME,
    '20:30:00'::TIME,
    true
FROM public.veterinarios v
CROSS JOIN (
    VALUES 
        ('Lunes'),
        ('Martes'), 
        ('Miércoles'),
        ('Jueves'),
        ('Viernes')
) AS dia(nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM public.horarios_veterinario h 
    WHERE h.veterinario_id = v.id AND h.dia_semana = dia.nombre
);

-- TRIGGERS para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger a horarios_veterinario
DROP TRIGGER IF EXISTS update_horarios_veterinario_updated_at ON public.horarios_veterinario;
CREATE TRIGGER update_horarios_veterinario_updated_at
    BEFORE UPDATE ON public.horarios_veterinario
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Aplicar trigger a citas
DROP TRIGGER IF EXISTS update_citas_updated_at ON public.citas;
CREATE TRIGGER update_citas_updated_at
    BEFORE UPDATE ON public.citas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- DESHABILITAR RLS PARA DESARROLLO (temporal)
ALTER TABLE public.horarios_veterinario DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.citas DISABLE ROW LEVEL SECURITY;

-- DATOS DE EJEMPLO PARA PRUEBAS
-- Insertar algunas citas de ejemplo (opcional)
INSERT INTO public.citas (animal_id, veterinario_id, fecha, hora, estado, motivo)
VALUES
    (1, 1, '2025-06-13', '10:00:00', 'programada', 'Consulta de rutina'),
    (1, 1, '2025-06-13', '11:30:00', 'programada', 'Vacunación'),
    (1, 2, '2025-06-14', '17:00:00', 'programada', 'Revisión general')
ON CONFLICT (veterinario_id, fecha, hora) DO NOTHING;

-- VERIFICAR QUE TODO SE CREÓ CORRECTAMENTE
SELECT 'Tablas creadas correctamente' as status;

SELECT 
    'horarios_veterinario' as tabla,
    COUNT(*) as registros
FROM public.horarios_veterinario
UNION ALL
SELECT 
    'citas' as tabla,
    COUNT(*) as registros
FROM public.citas;

-- MOSTRAR ESTRUCTURA DE HORARIOS
SELECT 
    h.veterinario_id,
    v.nombre as veterinario,
    h.dia_semana,
    h.hora_inicio,
    h.hora_fin_manana,
    h.hora_inicio_tarde,
    h.hora_fin,
    h.activo
FROM public.horarios_veterinario h
JOIN public.veterinarios v ON v.id = h.veterinario_id
ORDER BY h.veterinario_id, 
    CASE h.dia_semana 
        WHEN 'Lunes' THEN 1
        WHEN 'Martes' THEN 2
        WHEN 'Miércoles' THEN 3
        WHEN 'Jueves' THEN 4
        WHEN 'Viernes' THEN 5
        WHEN 'Sábado' THEN 6
        WHEN 'Domingo' THEN 7
    END;
