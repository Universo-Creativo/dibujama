# Dibujama — Web

> *Galería de dibujos de la comunidad*

Sitio web público de la galería de dibujos de la comunidad **Universo Creativo**. Generado con `simple-photo-gallery` (Python) y servido con **GitHub Pages**.

URL pública: https://luisenriquepupo16-rgb.github.io/dibujama/

---

## ¿Qué es esto?

Este repositorio contiene:

1. La **web pública** de Dibujama (carpeta `docs/`), servida directamente por GitHub Pages.
2. Los **scripts de automatización** en PowerShell para añadir fotos nuevas, generar metadata y regenerar la galería.
3. La **metadata enriquecida** (autor, categoría, fecha, tags) que consume tanto la web como la app Android.

La galería visual se genera automáticamente con `simple-photo-gallery`, que se encarga de:

- Copiar y procesar las imágenes.
- Generar miniaturas.
- Renderizar el HTML con PhotoSwipe.
- Producir `images_data.json` con los datos de las imágenes.

Sobre esa base, este proyecto añade:

- Un `metadata.json` con información adicional por dibujo.
- Un `gallery.json` con la configuración visual del sitio.
- Scripts para que el flujo de añadir fotos sea cómodo.

---

## Estructura del repositorio

```
Dibujama_Web/
├── fotos/                          # Carpeta temporal para fotos nuevas
│   └── .gitkeep
├── docs/                           # Sitio web (servido por GitHub Pages)
│   ├── images/
│   │   ├── photos/                 # Fotos originales
│   │   └── thumbnails/             # Miniaturas generadas
│   ├── templates/                  # Plantillas Jinja
│   │   ├── gallery_macros.jinja
│   │   └── index_template.jinja
│   ├── gallery.json                # Configuración de la galería
│   ├── images_data.json            # Datos de imágenes (generado)
│   ├── metadata.json               # Metadata enriquecida
│   └── index.html                  # HTML final (generado)
├── build-gallery.ps1               # Script principal: añade fotos y sube
├── generate-metadata.ps1           # Script auxiliar: pregunta metadata
├── .gitignore
└── README.md
```

---

## Flujo de trabajo: añadir fotos nuevas

### 1. Copiar las fotos a `fotos/`

Copia los archivos de imagen (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.heic`) a la carpeta `fotos/` en la raíz del proyecto.

### 2. Ejecutar `build-gallery.ps1`

Desde la raíz del repositorio, en PowerShell:

```powershell
.\build-gallery.ps1
```

El script hace automáticamente:

1. **Ejecuta `generate-metadata.ps1`** para cada foto nueva que no tenga metadata todavía. Te preguntará:
   - **Autor** (por defecto `Anónimo`).
   - **Categoría** (por defecto `sin-categoria`).
   - **Fecha** (por defecto el día de hoy en formato `YYYY-MM-DD`).
   - **Tags** (opcional, separados por coma).
2. **Copia** las fotos de `fotos/` a `docs/images/photos/`.
3. **Ejecuta `gallery-build`** para regenerar el HTML y las miniaturas.
4. **Vacía** la carpeta `fotos/`.
5. Hace **git add**, **git commit** y **git push**.

### 3. Esperar a GitHub Pages

GitHub Pages se actualiza automáticamente en 1-2 minutos tras el push.

---

## Categorías disponibles

Las categorías se definen en `generate-metadata.ps1` y son:

- `retrato`
- `personaje`
- `logo`
- `paisaje`
- `abstracto`
- `animal`
- `objeto`
- `escena`
- `sin-categoria` (por defecto)

Si quieres añadir o quitar categorías, edita el array `$Categorias` en `generate-metadata.ps1`.

---

## Configuración de la galería: `gallery.json`

El archivo `docs/gallery.json` controla la configuración visual del sitio:

```json
{
    "images_data_file": ".\\images_data.json",
    "public_path": ".",
    "templates_path": ".\\templates",
    "images_path": ".\\images\\photos",
    "thumbnails_path": ".\\images\\thumbnails",
    "thumbnail_height": 160,
    "title": "Dibujama",
    "description": "Dibujos de la comunidad",
    "background_photo": "prueba.png",
    "url": "https://luisenriquepupo16-rgb.github.io/dibujama/",
    "background_photo_offset": 30,
    "disable_captions": false
}
```

### Campos más relevantes

| Campo | Descripción |
|---|---|
| `title` | Título de la web (aparece en el header y en el `<title>`) |
| `description` | Subtítulo de la web |
| `background_photo` | Imagen de fondo del header (debe existir en `docs/images/photos/`) |
| `background_photo_offset` | Porcentaje vertical del fondo (0-100). Útil para ajustar el encuadre |
| `thumbnail_height` | Altura de las miniaturas en píxeles |
| `url` | URL pública del sitio (se usa en las metaetiquetas `og:*`) |
| `disable_captions` | Si es `true`, oculta las descripciones bajo las imágenes |

---

## Metadata: `metadata.json`

El archivo `docs/metadata.json` guarda información adicional por imagen, indexada por nombre de archivo:

```json
{
    "prueba.png": {
        "author": "Luisi",
        "category": "abstracto",
        "date": "2026-10-09",
        "tags": ["prueba", "colorido"]
    }
}
```

### Campos

| Campo | Tipo | Por defecto | Descripción |
|---|---|---|---|
| `author` | string | `"Anónimo"` | Autor del dibujo |
| `category` | string | `"sin-categoria"` | Categoría (de la lista permitida) |
| `date` | string | Fecha actual | Fecha en formato `YYYY-MM-DD` |
| `tags` | array de strings | `[]` | Etiquetas libres |

### Importante

**La web actualmente NO consume `metadata.json`.** Solo lo consume la app Android. Si quieres que la web muestre autor, categoría o tags, habría que:

1. Modificar `docs/templates/index_template.jinja` y `docs/templates/gallery_macros.jinja` para incluir esos campos.
2. Añadir un paso en `build-gallery.ps1` que fusione `metadata.json` con `images_data.json` antes de regenerar el HTML (o hacer un post-proceso del HTML generado).

---

## Dependencias

### En el sistema

- **Python 3.8+**
- **PowerShell 5.1+** (Windows) o PowerShell 7+ (multiplataforma)
- **Git** con acceso al repositorio remoto

### Paquetes de Python

```bash
pip install simple-photo-gallery
```

Esto instala el comando `gallery-build` que usan los scripts.

---

## Instalación inicial

```bash
# Clonar el repositorio
git clone https://github.com/luisenriquepupo16-rgb/dibujama.git
cd dibujama

# Instalar simple-photo-gallery
pip install simple-photo-gallery

# Verificar que gallery-build está disponible
gallery-build --help
```

---

## Personalización de la web

### Cambiar el título y la descripción

Editar `docs/gallery.json`:

```json
"title": "Nuevo título",
"description": "Nueva descripción"
```

### Cambiar la imagen de fondo

Editar `docs/gallery.json`:

```json
"background_photo": "mi_nueva_foto.png"
```

La imagen debe existir en `docs/images/photos/`.

### Ajustar el encuadre del fondo

Editar `docs/gallery.json`:

```json
"background_photo_offset": 50
```

Valores entre `0` (arriba) y `100` (abajo). Por defecto `30`.

### Cambiar colores, tipografías o layout

`simple-photo-gallery` **no soporta** personalización visual directa. Para cambios profundos, hay dos opciones:

1. **Forkear `simple-photo-gallery`** y modificar sus templates.
2. **Hacer post-proceso** del HTML generado con un script propio.
3. **Migrar a otra herramienta** (por ejemplo, `thumbsup` o una web propia con HTML/CSS/JS).

### Plantillas Jinja

Las plantillas en `docs/templates/` son las que usa `simple-photo-gallery` para renderizar el HTML:

- `index_template.jinja` — la estructura completa de la página.
- `gallery_macros.jinja` — los macros de galería (secciones, grids, etc.).

Puedes modificarlas, pero ten en cuenta que se **sobrescriben** cada vez que ejecutas `gallery-build`... salvo que las tengas en el repo (como es el caso) y `simple-photo-gallery` las respete.

---

## Notas sobre Windows y codificación

### PowerShell 5.1 y UTF-8

PowerShell 5.1 lee los archivos `.ps1` como **ANSI**, no como UTF-8. Esto puede corromper tildes y caracteres especiales al cargar el script.

**Soluciones aplicadas en este proyecto:**

- Los prompts evitan tildes problemáticas (`"Anonimo"` en vez de `"Anónimo"`).
- Los archivos JSON se escriben con `[System.IO.File]::WriteAllText()` + `[System.Text.UTF8Encoding]::new($false)` (UTF-8 sin BOM).

### Rutas con backslashes

`simple-photo-gallery` en Windows genera rutas con `\` en el HTML:

```html
<img src="images\thumbnails\prueba.jpg" />
```

Esto **funciona en los navegadores modernos** (normalizan `\` a `/`), pero **no es estándar** y podría dar problemas en el futuro con otros navegadores o CDNs.

Si quieres arreglarlo:

1. Post-procesar `images_data.json` para convertir `\\` → `/`.
2. Modificar el macro de Jinja: `{{ image.src | replace('\\', '/') }}`.

---

## Problemas conocidos

| Problema | Estado | Solución |
|---|---|---|
| Backslashes en rutas del HTML | ⚠️ Latente | Post-proceso o modificar Jinja |
| `metadata.json` no se usa en la web | ℹ️ Informativo | Modificar templates + fusión |
| Doble `/` en `og:image` | 🟡 Cosmético | Quitar `/` final en `url` de `gallery.json` |
| `<html lang="en">` | 🟡 Detalle | Cambiar a `lang="es"` |
| `.gitignore` ignora `setup-dibujama.ps1` | ❓ Revisar | Quitar línea si quieres versionarlo |

---

## Hoja de ruta

### Corto plazo

- Probar la web con varias fotos y varios autores.
- Ajustar `background_photo_offset` si es necesario.
- Documentar el flujo completo en este README (✅ hecho).

### Mediano plazo

- Mostrar autor, categoría y fecha en la web (requiere tocar templates).
- Convertir rutas con `\` a `/` en `images_data.json`.
- Migrar a `github-pages-gallery` (Thumbsup) o forkear `simple-photo-gallery` si se necesita más personalización visual.

### Largo plazo

- Web propia desde cero con HTML/CSS/JS (control total).
- Backend real para comentarios o likes.
- Sistema de autores con páginas dedicadas por autor.

---

## Cómo permitir que otros suban fotos

Actualmente solo **Dreamer** (el administrador) sube fotos al repositorio. Opciones para abrirlo a más gente:

| Opción | Ventaja | Desventaja |
|---|---|---|
| **A — Colaborador** | Rápido | Acceso de escritura total al repo |
| **B — Fork + Pull Request** | Control total | Más lento para el miembro |
| **C — Pages CMS** | Interfaz visual | Requiere configuración |
| **D — GitHub Issues** | Fácil para el miembro | Requiere GitHub Actions |

---

## Ecosistema Dibujama

Este proyecto forma parte del ecosistema **Dibujama**, junto con:

- **App Android** (`Dibujama_Android`): lee la galería y la metadata desde esta web.
- **Web pública** (este repo): sirve la galería en https://luisenriquepupo16-rgb.github.io/dibujama/
- **Comunidad Universo Creativo**: grupo de WhatsApp donde los miembros comparten sus dibujos.

---

## Contribuir

Para enviar dibujos, únete al grupo de **Universo Creativo** en WhatsApp.

Para cambios en el código:

1. Haz un fork del repositorio.
2. Crea una rama con un nombre descriptivo (`feature/mi-cambio`, `fix/mi-bug`).
3. Haz tus cambios y haz commit.
4. Abre un Pull Request contra `main`.

---

## Licencia

Uso personal y comunitario.

---

*Parte del ecosistema Dibujama. Hecho con 💙 por y para la comunidad Universo Creativo.*
```

Aplícalo y la web tendrá un README a la altura de la app. 💙🚀