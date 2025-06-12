## 🚨 INSTRUCCIONES URGENTES - Error RLS

### **PROBLEMA ACTUAL:**
```
Error registering animal: PostgrestException(message: new row violates row-level security policy for table "animales", code: 42501)
```

### **CAUSA:**
- La tabla `animales` tiene RLS habilitado
- **Falta política INSERT** para permitir registro de nuevos animales

### **✅ SOLUCIÓN INMEDIATA:**

**1. Ve a Supabase:**
- Abre tu proyecto Supabase
- Ve a **SQL Editor**

**2. Ejecuta este código:**
```sql
-- CREAR POLÍTICA INSERT PARA ANIMALES
CREATE POLICY "allow_insert_animales" 
    ON public.animales FOR INSERT 
    WITH CHECK (true);

-- VERIFICAR QUE SE APLICÓ
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'animales';
```

**3. Haz clic en "Run"**

### **🔍 VERIFICACIÓN:**
Después del script deberías ver:
- ✅ `allow_insert_animales` INSERT
- ✅ Otras políticas SELECT/UPDATE existentes

### **📱 CAMBIOS EN FLUTTER:**
✅ **Imagen ahora es OPCIONAL:**
- Se eliminó validación obligatoria de imagen
- Texto cambiado a "Opcional" (azul)
- Manejo robusto de errores de subida
- Continúa registro aunque falle la imagen

### **🧪 PROBAR:**
1. Ejecuta el script SQL
2. Ejecuta: `flutter run -d chrome`
3. Ve a Registro → Registrar Animal
4. Llena formulario (imagen opcional)
5. Debería registrarse correctamente

### **⚠️ SI AÚN FALLA:**
- Revisa logs de Supabase en Dashboard → Logs
- Verifica que la política se creó correctamente

**¡EJECUTA EL SCRIPT SQL AHORA!**
