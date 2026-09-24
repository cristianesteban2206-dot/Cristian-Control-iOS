# Cristian Control — iPhone

Aplicación personal nativa para iPhone con:

- Finanzas: gastos, ingresos, historial, presupuesto mensual y alertas.
- Peso: registro diario, meta, historial y gráfico.
- Actividad: gimnasio, caminata, running, bicicleta, yoga, funcional, entrenamiento y más.
- Aviso local cuando pasan más de 2 días sin actividad registrada.
- Hábitos: agua, sueño y estado de ánimo.
- Medidas corporales.
- Metas personales.
- Estadísticas financieras, de peso y actividad.
- Calendario integral.
- Centro de avisos.
- Face ID opcional.
- Datos locales con SwiftData.

## Compatibilidad
- iOS 17 o posterior.
- Diseñada para iPhone, incluida la familia Pro Max.

## Importante sobre la instalación
Apple no permite instalar un APK ni un ejecutable iOS sin firma. Para instalar esta app nativa en un iPhone físico:
1. Usá una Mac con Xcode.
2. Abrí `CristianControl.xcodeproj`.
3. Conectá el iPhone o elegilo por Wi‑Fi.
4. En el target **CristianControl > Signing & Capabilities**, seleccioná tu Apple ID/Team.
5. Presioná **Run**.

Con un Apple ID gratuito, Xcode puede instalar una app de desarrollo en tu dispositivo, aunque Apple puede exigir renovarla periódicamente. Con una cuenta Apple Developer paga se puede distribuir de forma más estable (por ejemplo mediante TestFlight).

Bundle ID provisorio: `com.cristian.control`
