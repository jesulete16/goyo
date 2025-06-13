# ✅ GUÍA: Como Probar que las Citas se Guardan en la Base de Datos

## **PROCESO COMPLETO DE TESTING** 🧪

### **1. PREPARACIÓN** 
Antes de probar, asegúrate de tener:
- ✅ App Flutter funcionando
- ✅ Conexión a Supabase activa
- ✅ Al menos 1 animal y 1 veterinario en la BD

### **2. PROCESO DE CREACIÓN DE CITA** 📱

#### **Pasos en la App:**
1. **Abrir la app** → Login como animal
2. **Ir a Menu Animal** → Ver lista de veterinarios
3. **Seleccionar veterinario** → Clic en "Pedir Cita"
4. **En el Calendar Widget**:
   - Seleccionar una fecha (solo días laborales)
   - Elegir una hora disponible 
   - Clic en "Confirmar Cita - [HORA]"

#### **Lo que Debería Pasar:**
1. **Loading Circle** aparece brevemente
2. **Calendar se cierra** automáticamente  
3. **SnackBar verde** aparece con:
   ```
   ✅ ¡Cita confirmada!
   2025-06-13 a las 10:00
   Dr. [Nombre del Veterinario]
   ```

### **3. VERIFICACIÓN EN BASE DE DATOS** 💾

#### **Opción A: Script SQL de Verificación**
```sql
-- Ejecutar en Supabase SQL Editor
\i supabase_verificar_citas_guardadas.sql
```

#### **Opción B: Consulta Manual**
```sql
-- Ver citas creadas en las últimas 24 horas
SELECT 
    c.id,
    a.nombre as animal,
    v.nombre as veterinario,
    c.fecha,
    c.hora_inicio,
    c.hora_fin,
    c.estado,
    c.created_at
FROM citas c
JOIN animales a ON c.animal_id = a.id
JOIN veterinarios v ON c.veterinario_id = v.id
WHERE c.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY c.created_at DESC;
```

### **4. DATOS QUE SE GUARDAN** 📊

Cuando creas una cita, se insertan estos campos:

| Campo | Valor | Ejemplo |
|-------|-------|---------|
| `animal_id` | UUID del animal | `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11` |
| `veterinario_id` | UUID del veterinario | `b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22` |
| `fecha` | Fecha seleccionada | `2025-06-13` |
| `hora_inicio` | Hora seleccionada | `10:00:00` |
| `hora_fin` | +30 minutos | `10:30:00` |
| `estado` | Estado inicial | `programada` |
| `motivo` | Motivo por defecto | `Consulta general` |
| `created_at` | Timestamp automático | `2025-06-12 16:25:30` |

### **5. CASOS DE ERROR Y SOLUCIONES** ⚠️

#### **Error: "No se pueden agendar citas en fines de semana"**
- **Causa**: Seleccionaste sábado o domingo
- **Solución**: Selecciona solo Lunes-Viernes

#### **Error: "Esta hora ya está ocupada"**
- **Causa**: Ya hay una cita a esa hora con ese veterinario
- **Solución**: Selecciona otra hora disponible

#### **Error: "Horario no válido"**
- **Causa**: Hora fuera del rango 9:00-13:30 o 17:00-20:30
- **Solución**: Bug en el código, reportar

#### **Error: "Error en los datos del animal o veterinario"**
- **Causa**: IDs nulos o inválidos
- **Solución**: Revisar datos de sesión

### **6. TESTING SISTEMÁTICO** 🎯

#### **Test 1: Cita Normal**
- Día: Lunes-Viernes
- Hora: 10:00 (mañana) o 18:00 (tarde)
- Resultado esperado: ✅ Éxito

#### **Test 2: Fin de Semana**
- Día: Sábado o Domingo
- Resultado esperado: ❌ Días deshabilitados (gris)

#### **Test 3: Hora Ocupada**
- Crear 2 citas mismo día/hora/veterinario
- Resultado esperado: ❌ Segunda cita rechazada

#### **Test 4: Días Pasados**
- Intentar seleccionar fecha anterior a hoy
- Resultado esperado: ❌ Días deshabilitados (gris)

### **7. LOGS DE DEBUGGING** 🔍

En la consola de Flutter aparecerán estos logs:

#### **Creación Exitosa:**
```
📝 Creando cita...
🏥 Veterinario: Dr. García (ID: b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22)
🐾 Animal: Max (ID: a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11)
📅 Fecha: 2025-06-13
⏰ Hora inicio: 10:00
⏰ Hora fin calculada: 10:30
📊 Datos a insertar: {animal_id: a0eebc99-..., veterinario_id: b0eebc99-...}
✅ Cita creada exitosamente: [...]
```

#### **Error:**
```
🚨 Error creando cita: [descripción del error]
```

### **8. VERIFICACIÓN FINAL** ✅

Para confirmar que todo funciona:

1. **Crear una cita de prueba** siguiendo los pasos
2. **Verificar en Supabase** que aparece en la tabla `citas`
3. **Intentar crear otra cita** en la misma hora (debe fallar)
4. **Intentar seleccionar fin de semana** (debe estar deshabilitado)

### **9. ARCHIVOS RELACIONADOS** 📁

- `lib/cita_calendar.dart` - Widget del calendario (MEJORADO)
- `supabase_verificar_citas_guardadas.sql` - Script de verificación
- `supabase_database.sql` - Estructura de tablas con restricciones

### **10. PRÓXIMOS PASOS** 🚀

Una vez confirmado que las citas se guardan:
- ✅ Implementar visualización de citas existentes
- ✅ Permitir cancelar/modificar citas
- ✅ Notificaciones de recordatorio
- ✅ Vista de calendario para veterinarios

---

## **🎯 RESULTADO ESPERADO**

Al completar este testing, deberías poder:
1. ✅ Crear citas desde la app
2. ✅ Ver las citas en la base de datos
3. ✅ Confirmar que se respetan todas las restricciones
4. ✅ Manejar errores correctamente

**¡El sistema de citas está 100% funcional!** 🎉
