-- ============================================================================
-- GOYO - Sistema Veterinario
-- Base de datos Supabase - Configuración completa
-- ============================================================================

-- 1. HABILITAR EXTENSIONES NECESARIAS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. CONFIGURAR STORAGE (BUCKETS PARA IMÁGENES)
-- ============================================================================
-- Bucket para fotos de animales
INSERT INTO storage.buckets (id, name, public) 
VALUES ('animal-photos', 'animal-photos', true);

-- Bucket para fotos de veterinarios
INSERT INTO storage.buckets (id, name, public) 
VALUES ('veterinario-photos', 'veterinario-photos', true);

-- 3. TABLA ANIMALES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.animales (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(255) UNIQUE NOT NULL,
    foto_url TEXT,
    contraseña TEXT NOT NULL, -- Se encriptará con bcrypt
    ubicacion VARCHAR(255) NOT NULL,
    tipo VARCHAR(50) NOT NULL CHECK (tipo IN (
        'Perro', 'Gato', 'Pájaro', 'Caballo', 'Conejo', 
        'Hamster', 'Pez', 'Reptil'
    )),
    raza VARCHAR(100) NOT NULL,
    edad VARCHAR(50) NOT NULL, -- Formato libre: "2 años", "6 meses", etc.
    altura VARCHAR(50) NOT NULL, -- Formato libre: "30 cm", "1.2 metros", etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimización
CREATE INDEX idx_animales_correo ON public.animales(correo);
CREATE INDEX idx_animales_tipo ON public.animales(tipo);
CREATE INDEX idx_animales_ubicacion ON public.animales(ubicacion);

-- 4. TABLA VETERINARIOS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.veterinarios (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(255) UNIQUE NOT NULL,
    foto_url TEXT,
    contraseña TEXT NOT NULL, -- Se encriptará con bcrypt
    ubicacion VARCHAR(255) NOT NULL,
    especialidad VARCHAR(50) NOT NULL CHECK (especialidad IN (
        'Perro', 'Gato', 'Pájaro', 'Caballo', 'Conejo', 
        'Hamster', 'Pez', 'Reptil', 'General'
    )),
    numero_colegiado VARCHAR(50), -- Número de colegio profesional
    años_experiencia INTEGER DEFAULT 0,
    telefono VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimización
CREATE INDEX idx_veterinarios_correo ON public.veterinarios(correo);
CREATE INDEX idx_veterinarios_especialidad ON public.veterinarios(especialidad);
CREATE INDEX idx_veterinarios_ubicacion ON public.veterinarios(ubicacion);

-- 5. TABLA CITAS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.citas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    animal_id UUID NOT NULL REFERENCES public.animales(id) ON DELETE CASCADE,
    veterinario_id UUID NOT NULL REFERENCES public.veterinarios(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    motivo TEXT,
    notas_veterinario TEXT,
    estado VARCHAR(20) DEFAULT 'programada' CHECK (estado IN (
        'programada', 'confirmada', 'en_curso', 'completada', 
        'cancelada', 'no_asistio'
    )),
    precio DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Restricciones de horario
    CONSTRAINT check_horario_valido CHECK (
        (hora_inicio >= '09:00:00' AND hora_fin <= '13:30:00') OR
        (hora_inicio >= '17:00:00' AND hora_fin <= '20:30:00')
    ),
    
    -- Restricción para evitar citas en fines de semana
    CONSTRAINT check_no_fin_semana CHECK (
        EXTRACT(DOW FROM fecha) NOT IN (0, 6) -- 0=Domingo, 6=Sábado
    ),
    
    -- Evitar citas duplicadas (mismo veterinario, fecha y hora)
    CONSTRAINT unique_veterinario_fecha_hora UNIQUE (veterinario_id, fecha, hora_inicio)
);

-- Índices para optimización de consultas
CREATE INDEX idx_citas_animal_id ON public.citas(animal_id);
CREATE INDEX idx_citas_veterinario_id ON public.citas(veterinario_id);
CREATE INDEX idx_citas_fecha ON public.citas(fecha);
CREATE INDEX idx_citas_estado ON public.citas(estado);

-- 6. TABLA HORARIOS DISPONIBLES VETERINARIOS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.horarios_veterinario (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    veterinario_id UUID NOT NULL REFERENCES public.veterinarios(id) ON DELETE CASCADE,
    dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 1 AND 5), -- 1=Lunes, 5=Viernes
    hora_inicio_mañana TIME DEFAULT '09:00:00',
    hora_fin_mañana TIME DEFAULT '13:30:00',
    hora_inicio_tarde TIME DEFAULT '17:00:00',
    hora_fin_tarde TIME DEFAULT '20:30:00',
    disponible_mañana BOOLEAN DEFAULT true,
    disponible_tarde BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Un horario único por veterinario y día
    CONSTRAINT unique_veterinario_dia UNIQUE (veterinario_id, dia_semana)
);

-- 7. FUNCIONES AUXILIARES
-- ============================================================================

-- Función para encriptar contraseñas
CREATE OR REPLACE FUNCTION encrypt_password()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.contraseña != OLD.contraseña) THEN
        NEW.contraseña = crypt(NEW.contraseña, gen_salt('bf'));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función para verificar contraseñas
CREATE OR REPLACE FUNCTION verify_password(input_password TEXT, stored_password TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN stored_password = crypt(input_password, stored_password);
END;
$$ LANGUAGE plpgsql;

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. TRIGGERS
-- ============================================================================

-- Triggers para encriptar contraseñas
CREATE TRIGGER encrypt_animal_password
    BEFORE INSERT OR UPDATE ON public.animales
    FOR EACH ROW EXECUTE FUNCTION encrypt_password();

CREATE TRIGGER encrypt_veterinario_password
    BEFORE INSERT OR UPDATE ON public.veterinarios
    FOR EACH ROW EXECUTE FUNCTION encrypt_password();

-- Triggers para actualizar updated_at
CREATE TRIGGER update_animales_updated_at
    BEFORE UPDATE ON public.animales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_veterinarios_updated_at
    BEFORE UPDATE ON public.veterinarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_citas_updated_at
    BEFORE UPDATE ON public.citas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.animales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.veterinarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.citas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.horarios_veterinario ENABLE ROW LEVEL SECURITY;

-- Políticas para animales (solo pueden ver/editar sus propios datos)
CREATE POLICY "Animales pueden ver sus propios datos"
    ON public.animales FOR SELECT
    USING (auth.jwt() ->> 'email' = correo);

CREATE POLICY "Animales pueden actualizar sus propios datos"
    ON public.animales FOR UPDATE
    USING (auth.jwt() ->> 'email' = correo);

-- Políticas para veterinarios (solo pueden ver/editar sus propios datos)
CREATE POLICY "Veterinarios pueden ver sus propios datos"
    ON public.veterinarios FOR SELECT
    USING (auth.jwt() ->> 'email' = correo);

CREATE POLICY "Veterinarios pueden actualizar sus propios datos"
    ON public.veterinarios FOR UPDATE
    USING (auth.jwt() ->> 'email' = correo);

-- Políticas para citas
CREATE POLICY "Animales pueden ver sus citas"
    ON public.citas FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.animales 
            WHERE id = citas.animal_id 
            AND correo = auth.jwt() ->> 'email'
        )
    );

CREATE POLICY "Veterinarios pueden ver sus citas"
    ON public.citas FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.veterinarios 
            WHERE id = citas.veterinario_id 
            AND correo = auth.jwt() ->> 'email'
        )
    );

-- 10. STORAGE POLICIES
-- ============================================================================

-- Políticas para bucket de fotos de animales
CREATE POLICY "Animales pueden subir sus fotos"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'animal-photos' AND
        auth.role() = 'authenticated'
    );

CREATE POLICY "Fotos de animales son públicas para lectura"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'animal-photos');

-- Políticas para bucket de fotos de veterinarios
CREATE POLICY "Veterinarios pueden subir sus fotos"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'veterinario-photos' AND
        auth.role() = 'authenticated'
    );

CREATE POLICY "Fotos de veterinarios son públicas para lectura"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'veterinario-photos');

-- 11. VISTAS ÚTILES
-- ============================================================================

-- Vista de citas con información completa
CREATE OR REPLACE VIEW vista_citas_completa AS
SELECT 
    c.id,
    c.fecha,
    c.hora_inicio,
    c.hora_fin,
    c.motivo,
    c.estado,
    c.precio,
    a.nombre as animal_nombre,
    a.tipo as animal_tipo,
    a.raza as animal_raza,
    v.nombre as veterinario_nombre,
    v.especialidad as veterinario_especialidad,
    c.created_at
FROM public.citas c
JOIN public.animales a ON c.animal_id = a.id
JOIN public.veterinarios v ON c.veterinario_id = v.id;

-- Vista de horarios disponibles
CREATE OR REPLACE VIEW vista_horarios_disponibles AS
SELECT 
    h.veterinario_id,
    v.nombre as veterinario_nombre,
    v.especialidad,
    h.dia_semana,
    CASE h.dia_semana 
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
    END as dia_nombre,
    h.hora_inicio_mañana,
    h.hora_fin_mañana,
    h.hora_inicio_tarde,
    h.hora_fin_tarde,
    h.disponible_mañana,
    h.disponible_tarde
FROM public.horarios_veterinario h
JOIN public.veterinarios v ON h.veterinario_id = v.id;

-- 12. DATOS DE EJEMPLO (OPCIONAL)
-- ============================================================================

-- Crear horarios por defecto para veterinarios (se ejecutará con triggers)
CREATE OR REPLACE FUNCTION crear_horarios_default()
RETURNS TRIGGER AS $$
BEGIN
    -- Crear horarios de lunes a viernes para el nuevo veterinario
    INSERT INTO public.horarios_veterinario (veterinario_id, dia_semana)
    SELECT NEW.id, generate_series(1, 5);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER crear_horarios_veterinario_default
    AFTER INSERT ON public.veterinarios
    FOR EACH ROW EXECUTE FUNCTION crear_horarios_default();

-- ============================================================================
-- FIN DE LA CONFIGURACIÓN
-- ============================================================================

-- Para ejecutar este script en Supabase:
-- 1. Copia todo el contenido
-- 2. Ve a tu proyecto Supabase > SQL Editor
-- 3. Pega el código y ejecuta
-- 4. Verifica que todas las tablas se hayan creado correctamente

COMMENT ON TABLE public.animales IS 'Tabla de animales registrados en el sistema';
COMMENT ON TABLE public.veterinarios IS 'Tabla de veterinarios registrados en el sistema';
COMMENT ON TABLE public.citas IS 'Tabla de citas entre animales y veterinarios';
COMMENT ON TABLE public.horarios_veterinario IS 'Horarios de disponibilidad de cada veterinario';

-- ============================================================================
-- CONFIGURACIÓN ADICIONAL Y NOTAS
-- ============================================================================

-- Para cargar datos de ejemplo después de la configuración:
-- Ejecutar el archivo: supabase_sample_data.sql

-- COMENTARIOS FINALES:
-- - Todas las tablas están configuradas con RLS y políticas de seguridad
-- - Las contraseñas se encriptan automáticamente con bcrypt
-- - Los horarios están restringidos a días laborables y horarios específicos
-- - El storage está configurado para fotos públicas
-- - Los triggers automatizan la gestión de timestamps y horarios

-- Para desarrollo y testing:
-- 1. Ejecutar este script completo en Supabase SQL Editor
-- 2. Ejecutar supabase_sample_data.sql para datos de prueba
-- 3. Configurar las variables de entorno en la aplicación Flutter
-- 4. Probar la autenticación y funcionalidades

COMMENT ON TABLE public.animales IS 'Tabla de animales registrados en el sistema';
COMMENT ON TABLE public.veterinarios IS 'Tabla de veterinarios registrados en el sistema';
COMMENT ON TABLE public.citas IS 'Tabla de citas entre animales y veterinarios';
COMMENT ON TABLE public.horarios_veterinario IS 'Horarios de disponibilidad de cada veterinario';
