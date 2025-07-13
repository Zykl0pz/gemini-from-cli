# Google-Gemini-from-cli
Este script de Bash permite interactuar con la API de Google Gemini directamente desde la terminal. Facilita la gestión del historial de conversación, el cambio entre diferentes modelos de IA y la visualización de las respuestas en formato Markdown utilizando `glow`.

## Tabla de Contenidos

*   **Descripción General**
*   **Requisitos Previos**
*   **Instalación**
    *   Instalación de Dependencias
    *   Configuración del Script
*   **Primeros Pasos**
*   **Guía de Uso**
    *   Envío de Peticiones Básicas
    *   Gestión del Historial de Conversación
        *   Uso del Contexto con `@history`
        *   Uso del Último Contexto con `@latest`
    *   Cambio de Modelo de IA
*   **Funcionalidades Detalladas**
    *   `load_gemini_config()`
    *   `save_gemini_config()`
    *   `append_to_gemini_history()`
    *   `get_gemini_history_context()`
    *   `call_gemini_api()`
    *   `switch_gemini_model()`
    *   `ai()` (Función Principal)
*   **Configuración de Variables de Entorno**
*   **Estructura de Archivos Generados**
*   **Solución de Problemas Comunes**

---

## Descripción General

El script `ai` (nombre de la función principal) es una herramienta de línea de comandos diseñada para simplificar la interacción con la API de Google Gemini. Permite a los usuarios enviar prompts, mantener un historial de conversación para proporcionar contexto en futuras interacciones y cambiar dinámicamente el modelo de IA utilizado. Las respuestas de la IA se formatean y se muestran de manera legible en la terminal gracias a la herramienta `glow`.

## Requisitos Previos

Para que este script funcione correctamente, necesitas tener instaladas las siguientes herramientas en tu sistema Ubuntu:

*   **`curl`**: Herramienta de línea de comandos para transferir datos con sintaxis URL. Se utiliza para realizar las peticiones a la API de Gemini.
*   **`jq`**: Procesador JSON ligero y flexible de línea de comandos. Se utiliza para parsear las respuestas JSON de la API de Gemini.
*   **`glow`**: Renderizador de Markdown de línea de comandos. Se utiliza para mostrar las respuestas de la IA en un formato legible y atractivo.

## Instalación

Sigue estos pasos para instalar las dependencias y configurar el script en tu sistema Ubuntu.

### Instalación de Dependencias

Abre tu terminal y ejecuta los siguientes comandos para instalar `curl`, `jq` y `glow`:

```bash
sudo apt update
sudo apt install -y curl jq

# Instalación de glow (método recomendado para Ubuntu/Debian)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update
sudo apt install -y glow
```

### Configuración del Script

1.  **Guarda el script**:
    Copia el contenido del script proporcionado en un archivo llamado `ai_gemini.sh` (o el nombre que prefieras) en tu directorio personal, por ejemplo, en `~/scripts/`:

    ```bash
    mkdir -p ~/scripts
    nano ~/scripts/ai_gemini.sh
    # Pega el contenido del script y guarda (Ctrl+S, Ctrl+X en nano)
    ```

2.  **Haz el script ejecutable**:

    ```bash
    chmod +x ~/scripts/ai_gemini.sh
    ```

3.  **Añade el script a tu `~/.bashrc`**:
    Para que la función `ai` esté disponible cada vez que abras una nueva terminal, necesitas "sourcear" el script en tu archivo de configuración de Bash.

    Abre tu `~/.bashrc` con un editor de texto:

    ```bash
    nano ~/.bashrc
    ```

    Añade la siguiente línea al final del archivo:

    ```bash
    # Cargar el script de Gemini AI
    source ~/scripts/ai_gemini.sh
    ```

    Guarda el archivo y ciérralo.

4.  **Aplica los cambios en tu sesión actual**:
    Para que los cambios surtan efecto inmediatamente sin reiniciar la terminal:

    ```bash
    source ~/.bashrc
    ```

5.  **Configura tu `GOOGLE_API_KEY`**:
    El script necesita tu clave API de Google Gemini para funcionar. Tienes dos opciones para configurarla:

    *   **Opción 1 (Recomendada - Variable de Entorno)**: Establece la clave API como una variable de entorno en tu `~/.bashrc`. Esto es más seguro ya que la clave no se guarda directamente en el archivo de configuración del script.

        Abre `~/.bashrc` de nuevo:

        ```bash
        nano ~/.bashrc
        ```

        Añade la siguiente línea (reemplaza `TU_CLAVE_API_DE_GEMINI` con tu clave real):

        ```bash
        export GOOGLE_API_KEY="TU_CLAVE_API_DE_GEMINI"
        ```

        Guarda y cierra, luego ejecuta `source ~/.bashrc`.

    *   **Opción 2 (Archivo de Configuración)**: El script creará un archivo de configuración en `~/.config/gemini_ai/config` la primera vez que lo uses. Puedes editar este archivo para añadir tu clave API.

        ```bash
        nano ~/.config/gemini_ai/config
        ```

        Busca la línea `GOOGLE_API_KEY=""` y reemplázala con tu clave:

        ```bash
        GOOGLE_API_KEY="TU_CLAVE_API_DE_GEMINI"
        ```

        **Nota**: La variable de entorno tiene prioridad sobre la clave en el archivo de configuración.

## Primeros Pasos

Una vez que hayas completado la instalación y configuración, puedes empezar a usar el script.

1.  **Verifica la instalación**:
    Abre una nueva terminal y escribe `ai`. Si todo está configurado correctamente, deberías ver el mensaje de uso:

    ```bash
    ai
    # Salida esperada:
    # Uso: ai [opciones] <tu_petición>
    # Opciones:
    #   ai <tu_petición>             : Envía una nueva petición a la IA.
    #   ai @history <número> <petición> : Envía las últimas <número> interacciones (comandos y respuestas de la IA) como contexto.
    #   ai @latest <petición>      : Envía la última interacción (tu último comando a 'ai' y la última respuesta de la IA) como contexto.
    #   ai @switch_model           : Muestra los modelos de IA disponibles y te permite cambiar el modelo actual.
    ```

2.  **Haz tu primera pregunta**:
    Intenta enviar un prompt simple a Gemini:

    ```bash
    ai "Hola Gemini, ¿cómo estás hoy?"
    ```

    La primera vez que ejecutes el script, se creará el directorio `~/.config/gemini_ai/` y los archivos `config` e `history` si no existen. Si no configuraste la `GOOGLE_API_KEY` como variable de entorno, el script te advertirá que la configures en el archivo `config`.

## Guía de Uso

El script `ai` ofrece varias formas de interactuar con la API de Gemini.

### Envío de Peticiones Básicas

Para enviar una pregunta o una instrucción simple a la IA, simplemente escribe `ai` seguido de tu prompt:

```bash
ai "Explícame la diferencia entre un proceso y un hilo en sistemas operativos."
```

La respuesta de la IA se mostrará en tu terminal, formateada con `glow`.

### Gestión del Historial de Conversación

El script puede enviar interacciones previas como contexto a la IA, lo que permite conversaciones más coherentes y continuas.

#### Uso del Contexto con `@history`

Utiliza `@history <número>` para incluir las últimas `<número>` interacciones (tus comandos y las respuestas de la IA) como contexto para tu nueva petición.

**Sintaxis**: `ai @history <número> <tu_petición>`

**Ejemplo**: Si quieres que la IA recuerde las últimas 4 interacciones para tu próxima pregunta:

```bash
ai @history 4 "Basado en nuestra conversación anterior, ¿podrías darme un ejemplo práctico?"
```

#### Uso del Último Contexto con `@latest`

Utiliza `@latest` para enviar la última interacción completa (tu último comando a `ai` y la última respuesta de la IA) como contexto. Esto es útil para seguir una conversación sin especificar un número.

**Sintaxis**: `ai @latest <tu_petición>`

**Ejemplo**:

```bash
ai @latest "Entendido. Ahora, ¿cómo se aplica esto en un entorno de microservicios?"
```

### Cambio de Modelo de IA

Puedes cambiar el modelo de Gemini que el script utiliza para generar respuestas.

**Sintaxis**: `ai @switch_model`

Al ejecutar este comando, el script:
1.  Obtendrá una lista de los modelos de Gemini disponibles que soportan la generación de contenido.
2.  Mostrará estos modelos con un número.
3.  Te pedirá que introduzcas el número del modelo que deseas usar.

**Ejemplo**:

```bash
ai @switch_model
# Salida esperada:
# Obteniendo la lista de modelos disponibles...
# Modelos disponibles para 'generateContent':
# 1. Gemini 1.5 Flash (models/gemini-1.5-flash-latest)
# 2. Gemini 1.5 Pro (models/gemini-1.5-pro-latest)
# 3. Gemini Pro (models/gemini-pro)
# Introduce el número del modelo que deseas usar:
```

Introduce el número correspondiente al modelo que quieres usar (por ejemplo, `2` para `gemini-1.5-pro-latest`) y presiona Enter. El script guardará esta preferencia para futuras interacciones.

## Funcionalidades Detalladas

El script está compuesto por varias funciones auxiliares que gestionan la lógica interna:

### `load_gemini_config()`

*   **Descripción**: Carga la `GOOGLE_API_KEY` y el `CURRENT_GEMINI_MODEL` desde las variables de entorno o el archivo de configuración.
*   **Prioridad**: La variable de entorno `GOOGLE_API_KEY` tiene prioridad sobre la clave guardada en el archivo de configuración.
*   **Creación de Archivo**: Si el archivo de configuración no existe, lo crea con valores por defecto y advierte al usuario sobre la necesidad de configurar la clave API.
*   **Retorno**: Devuelve `0` si la configuración se carga correctamente (clave API presente), `1` si la clave API no está configurada.

### `save_gemini_config()`

*   **Descripción**: Guarda la `GOOGLE_API_KEY` y el `CURRENT_GEMINI_MODEL` actuales en el archivo de configuración (`~/.config/gemini_ai/config`).

### `append_to_gemini_history()`

*   **Descripción**: Añade una entrada al archivo de historial (`~/.config/gemini_ai/history`).
*   **Parámetros**:
    *   `$1`: Tipo de entrada (`"command"` para el prompt del usuario, `"prompt"` para la respuesta de la IA).
    *   `$2`: Contenido de la entrada.
*   **Formato**: Cada línea en el historial se guarda como `timestamp___tipo___contenido`.

### `get_gemini_history_context()`

*   **Descripción**: Recupera un número específico de entradas del historial y las formatea como una cadena JSON adecuada para el campo `contents` de la API de Gemini.
*   **Parámetros**:
    *   `$1`: Número de entradas a recuperar del final del historial.
*   **Roles**: Convierte las entradas de tipo `"command"` a rol `"user"` y las de tipo `"prompt"` a rol `"model"`.
*   **Salida**: Una cadena JSON que representa el historial de conversación.

### `call_gemini_api()`

*   **Descripción**: Envía una petición al endpoint `generateContent` de la API de Gemini y procesa la respuesta.
*   **Parámetros**:
    *   `$1`: El prompt principal del usuario para la petición actual.
    *   `$2`: Una cadena JSON opcional que contiene el contexto del historial.
*   **Manejo de Errores**: Verifica si la `GOOGLE_API_KEY` está configurada y maneja los errores de la API.
*   **Visualización**: Si la respuesta es exitosa, el texto generado se pasa a `glow` para su visualización y se añade al historial.

### `switch_gemini_model()`

*   **Descripción**: Permite al usuario cambiar el modelo de Gemini actual.
*   **Obtención de Modelos**: Consulta la API de Gemini para obtener una lista de modelos disponibles que soporten el método `generateContent`.
*   **Caché**: Utiliza un archivo de caché (`~/.config/gemini_ai/models_cache`) para evitar llamadas repetidas a la API si la lista de modelos es reciente (menos de 1 hora).
*   **Interacción**: Muestra los modelos al usuario y le pide que seleccione uno.
*   **Actualización**: Actualiza la variable `CURRENT_GEMINI_MODEL` y guarda la configuración.

### `ai()` (Función Principal)

*   **Descripción**: La función principal que se invoca desde la línea de comandos. Actúa como el punto de entrada para todas las interacciones con Gemini.
*   **Carga de Configuración**: Llama a `load_gemini_config()` al inicio.
*   **Manejo de Argumentos**:
    *   Si el primer argumento es `@history`, procesa el número de mensajes de historial y el prompt.
    *   Si el primer argumento es `@latest`, procesa el prompt y recupera las últimas dos interacciones como contexto.
    *   Si el primer argumento es `@switch_model`, llama a `switch_gemini_model()`.
    *   De lo contrario, trata todos los argumentos como el prompt principal.
*   **Registro de Historial**: Añade el comando del usuario al historial antes de llamar a la API.
*   **Llamada a la API**: Invoca `call_gemini_api()` con el prompt y el contexto (si aplica).
*   **Mensaje de Uso**: Muestra un mensaje de ayuda si no se proporcionan argumentos válidos.

## Configuración de Variables de Entorno

El script utiliza las siguientes variables de entorno y archivos de configuración:

*   **`GOOGLE_API_KEY`**: Tu clave API para acceder a la API de Google Gemini. **Es crucial que esta variable esté configurada.**
*   **`CURRENT_GEMINI_MODEL`**: El nombre del modelo de Gemini que se está utilizando actualmente (por defecto `gemini-pro`).
*   **`GEMINI_CONFIG_DIR`**: `$HOME/.config/gemini_ai` (Directorio donde se guardan los archivos de configuración y historial).
*   **`GEMINI_CONFIG_FILE`**: `$GEMINI_CONFIG_DIR/config` (Archivo que almacena la clave API y el modelo actual).
*   **`GEMINI_HISTORY_FILE`**: `$GEMINI_CONFIG_DIR/history` (Archivo que registra el historial de conversación).
*   **`GEMINI_MODEL_LIST_CACHE`**: `$GEMINI_CONFIG_DIR/models_cache` (Archivo para cachear la lista de modelos disponibles).

## Estructura de Archivos Generados

El script creará y gestionará los siguientes archivos en tu directorio de configuración:

```
~/.config/gemini_ai/
├── config        # Contiene GOOGLE_API_KEY y CURRENT_GEMINI_MODEL
├── history       # Almacena el historial de tus interacciones con la IA
└── models_cache  # Caché de la lista de modelos de Gemini disponibles
```

## Solución de Problemas Comunes

*   **"Error: GOOGLE_API_KEY no está configurada."**:
    *   Asegúrate de haber añadido `export GOOGLE_API_KEY="TU_CLAVE_API_DE_GEMINI"` a tu `~/.bashrc` y haber ejecutado `source ~/.bashrc`.
    *   Verifica que la clave en `~/.config/gemini_ai/config` sea correcta si optaste por esa vía.

*   **"Error de la API de Gemini: ..." o "Error: No se pudo obtener una respuesta válida..."**:
    *   **Clave API inválida**: Tu `GOOGLE_API_KEY` podría ser incorrecta o haber caducado. Verifica tu clave en la consola de Google Cloud.
    *   **Límites de cuota**: Podrías haber excedido los límites de uso de la API. Consulta tu panel de control de Google Cloud.
    *   **Problemas de red**: Verifica tu conexión a internet.
    *   **Modelo no disponible**: El modelo seleccionado (`CURRENT_GEMINI_MODEL`) podría no estar disponible o no soportar la operación `generateContent`. Intenta cambiar el modelo con `ai @switch_model`.

*   **`command not found: curl` (o `jq`, `glow`)**:
    *   Asegúrate de haber instalado todas las dependencias (`curl`, `jq`, `glow`) como se describe en la sección de instalación.

*   **El script no se ejecuta al abrir una nueva terminal**:
    *   Verifica que la línea `source ~/scripts/ai_gemini.sh` esté correctamente añadida a tu `~/.bashrc`.
    *   Asegúrate de que la ruta al script (`~/scripts/ai_gemini.sh`) sea correcta.

*   **Las respuestas no se muestran en Markdown o se ven mal**:
    *   Asegúrate de que `glow` esté correctamente instalado y en tu `PATH`. Puedes probar `glow --version` para verificarlo.

Si encuentras otros problemas, puedes revisar el contenido del archivo `~/.config/gemini_ai/history` para ver si las entradas se están guardando correctamente, y el archivo `~/.config/gemini_ai/config` para verificar la configuración.
