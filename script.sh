# ==============================================================================
# Script de Interacción con la API de Gemini AI
# Autor: Gemini (Google)
# Fecha: 13 de Julio de 2025
# Descripción: Permite interactuar con la API de Google Gemini desde la terminal,
#              gestionando el historial de conversación, cambiando modelos y
#              mostrando respuestas en Markdown con 'glow'.
# Requisitos: curl, jq, glow
# ==============================================================================

# Variables de entorno
# ==============================================================================
# Script de Interacción con la API de Gemini AI
# Autor: Gemini (Google)
# Fecha: 13 de Julio de 2025
# Descripción: Permite interactuar con la API de Google Gemini desde la terminal,
#              gestionando el historial de conversación, cambiando modelos y
#              mostrando respuestas en Markdown con 'glow'.
# Requisitos: curl, jq, glow
# ==============================================================================

# Variables de entorno
export GOOGLE_API_KEY="HERE_GO_YOUR_API_KEY"
export CURRENT_GEMINI_MODEL="gemini-1.5-flash-latest"

# --- Rutas de Configuración y Archivos de Historial ---
GEMINI_CONFIG_DIR="$HOME/.config/gemini_ai"
GEMINI_CONFIG_FILE="$GEMINI_CONFIG_DIR/config"
GEMINI_HISTORY_FILE="$GEMINI_CONFIG_DIR/history"
GEMINI_MODEL_LIST_CACHE="$GEMINI_CONFIG_DIR/models_cache" # Caché para la lista de modelos

# Asegura que el directorio de configuración exista
mkdir -p "$GEMINI_CONFIG_DIR" 2>/dev/null # Redirige errores si ya existe

# --- Variables Globales (se cargarán desde el archivo de configuración o el entorno) ---
GOOGLE_API_KEY=""        # Tu clave API de Google Gemini
CURRENT_GEMINI_MODEL="gemini-pro" # Modelo de Gemini actual por defecto

# --- Función para Cargar la Configuración ---
# Carga la clave API y el modelo actual.
# La variable de entorno GOOGLE_API_KEY tiene prioridad sobre el archivo de configuración.
load_gemini_config() {
    # Prioriza la variable de entorno GOOGLE_API_KEY si está establecida
    if [ -n "$GOOGLE_API_KEY" ]; then
        # Si la clave API ya está en el entorno, solo carga el modelo del archivo si existe
        if [ -f "$GEMINI_CONFIG_FILE" ]; then
            local config_model=$(grep "^CURRENT_GEMINI_MODEL=" "$GEMINI_CONFIG_FILE" | cut -d'=' -f2- | tr -d '"')
            if [ -n "$config_model" ]; then
                CURRENT_GEMINI_MODEL="$config_model"
            fi
        fi
        return 0 # Clave API configurada, procede
    fi

    # Si no está en el entorno, intenta cargar desde el archivo de configuración
    if [ -f "$GEMINI_CONFIG_FILE" ]; then
        local config_key=$(grep "^GOOGLE_API_KEY=" "$GEMINI_CONFIG_FILE" | cut -d'=' -f2- | tr -d '"')
        local config_model=$(grep "^CURRENT_GEMINI_MODEL=" "$GEMINI_CONFIG_FILE" | cut -d'=' -f2- | tr -d '"')

        if [ -n "$config_key" ]; then
            GOOGLE_API_KEY="$config_key"
        fi
        if [ -n "$config_model" ]; then
            CURRENT_GEMINI_MODEL="$config_model"
        fi
    else
        # Crea el archivo de configuración por defecto si no existe
        echo "GOOGLE_API_KEY=\"\"" > "$GEMINI_CONFIG_FILE"
        echo "CURRENT_GEMINI_MODEL=\"gemini-pro\"" >> "$GEMINI_CONFIG_FILE"
        echo "Archivo de configuración creado en $GEMINI_CONFIG_FILE."
        echo "Por favor, edita este archivo para añadir tu GOOGLE_API_KEY."
        echo "O establece la variable de entorno GOOGLE_API_KEY (ej. export GOOGLE_API_KEY=\"TU_CLAVE\")."
    fi

    # Si la clave API sigue sin estar configurada, muestra una advertencia
    if [ -z "$GOOGLE_API_KEY" ]; then
        echo "Advertencia: GOOGLE_API_KEY no está configurada." >&2
        echo "Por favor, edita $GEMINI_CONFIG_FILE o establece la variable de entorno GOOGLE_API_KEY." >&2
        return 1 # Indica que falta la clave API
    fi
    return 0
}

# --- Función para Guardar la Configuración ---
# Guarda la clave API y el modelo actual en el archivo de configuración.
save_gemini_config() {
    echo "GOOGLE_API_KEY=\"$GOOGLE_API_KEY\"" > "$GEMINI_CONFIG_FILE"
    echo "CURRENT_GEMINI_MODEL=\"$CURRENT_GEMINI_MODEL\"" >> "$GEMINI_CONFIG_FILE"
}

# --- Función para Añadir al Historial ---
# Añade una entrada al archivo de historial.
# $1: Tipo de entrada ("command" para comandos del usuario, "prompt" para respuestas de la IA)
# $2: Contenido de la entrada
append_to_gemini_history() {
    local type="$1"
    local content="$2"
    # Formato: timestamp___tipo___contenido
    echo "$(date +%s)___${type}___${content}" >> "$GEMINI_HISTORY_FILE"
}

# --- Función para Obtener el Contexto del Historial ---
# Recupera las últimas 'num_entries' del historial y las formatea como JSON para la API.
# $1: Número de entradas a recuperar
get_gemini_history_context() {
    local num_entries="$1"
    local context_json=""
    local history_lines=()

    if [ -f "$GEMINI_HISTORY_FILE" ]; then
        # Lee las últimas N líneas del historial en orden cronológico
        mapfile -t history_lines < <(tail -n "$num_entries" "$GEMINI_HISTORY_FILE")

        for line in "${history_lines[@]}"; do
            # Extrae el tipo y el contenido de la línea
            local type=$(echo "$line" | cut -d'_' -f3)
            local content=$(echo "$line" | cut -d'_' -f5-) # El contenido puede contener guiones bajos

            local role=""
            if [ "$type" == "command" ]; then
                role="user"
            elif [ "$type" == "prompt" ]; then
                role="model"
            else
                # Ignora tipos desconocidos
                continue
            fi

            # Escapa las comillas dobles en el contenido para el formato JSON
            content=$(echo "$content" | sed 's/"/\\"/g')

            # Construye el fragmento JSON para esta entrada
            if [ -n "$context_json" ]; then
                context_json="${context_json}, "
            fi
            context_json="${context_json}{\"role\": \"${role}\", \"parts\": [{\"text\": \"${content}\"}]}"
        done
    fi
    echo "$context_json"
}

# --- Función para Llamar a la API de Gemini ---
# Envía una petición a la API de Gemini y muestra la respuesta.
# $1: El prompt principal del usuario
# $2: Contexto del historial en formato JSON (opcional)
call_gemini_api() {
    local prompt="$1"
    local context_json="$2" # Cadena JSON opcional para el contexto

    if [ -z "$GOOGLE_API_KEY" ]; then
        echo "Error: GOOGLE_API_KEY no está configurada." >&2
        return 1
    fi

    local payload="{\"contents\": ["

    # Añade el contexto si está presente
    if [ -n "$context_json" ]; then
        payload="${payload}${context_json}, "
    fi

    # Escapa las comillas dobles en el prompt para el formato JSON
    local escaped_prompt=$(echo "$prompt" | sed 's/"/\\"/g')

    # Añade el prompt actual del usuario
    payload="${payload}{\"role\": \"user\", \"parts\": [{\"text\": \"${escaped_prompt}\"}]}]}"

    local api_url="https://generativelanguage.googleapis.com/v1beta/models/${CURRENT_GEMINI_MODEL}:generateContent?key=${GOOGLE_API_KEY}"

    # Realiza la llamada a la API usando curl
    local response=$(curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$api_url")

    # Extrae el texto generado y los mensajes de error
    local generated_text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty')
    local error_message=$(echo "$response" | jq -r '.error.message // empty')

    if [ -n "$generated_text" ]; then
        # Muestra el texto generado con glow y lo añade al historial
        echo "$generated_text" | glow -
        append_to_gemini_history "prompt" "$generated_text"
    elif [ -n "$error_message" ]; then
        echo "Error de la API de Gemini: $error_message" >&2
        echo "Respuesta completa del error: $response" >&2
    else
        echo "Error: No se pudo obtener una respuesta válida de la API de Gemini." >&2
        echo "Respuesta completa: $response" >&2
    fi
}

# --- Función para Cambiar el Modelo de IA ---
# Lista los modelos disponibles y permite al usuario seleccionar uno.
switch_gemini_model() {
    if [ -z "$GOOGLE_API_KEY" ]; then
        echo "Error: GOOGLE_API_KEY no está configurada. No se puede obtener la lista de modelos." >&2
        return 1
    fi

    local api_url="https://generativelanguage.googleapis.com/v1beta/models?key=${GOOGLE_API_KEY}"
    local models_json=""

    # Usa la caché de modelos si es reciente (menos de 1 hora)
    if [ -f "$GEMINI_MODEL_LIST_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$GEMINI_MODEL_LIST_CACHE") )) -lt 3600 ]; then
        models_json=$(cat "$GEMINI_MODEL_LIST_CACHE")
    else
        echo "Obteniendo la lista de modelos disponibles..."
        models_json=$(curl -s "$api_url")
        # Valida que la respuesta sea JSON antes de cachearla
        if echo "$models_json" | jq -e . >/dev/null; then
            echo "$models_json" > "$GEMINI_MODEL_LIST_CACHE" # Cachea la respuesta
        else
            echo "Error al obtener la lista de modelos. Respuesta inválida o error de red." >&2
            echo "Respuesta: $models_json" >&2
            return 1
        fi
    fi

    local model_names=()
    local model_display_names=()
    local i=0

    # Parsea los modelos, filtrando solo aquellos que soportan 'generateContent'
    while IFS= read -r line; do
        local name=$(echo "$line" | jq -r '.name')
        local display_name=$(echo "$line" | jq -r '.displayName')
        local supported_methods=$(echo "$line" | jq -r '.supportedGenerationMethods[]')

        if echo "$supported_methods" | grep -q "generateContent"; then
            model_names+=("$name")
            model_display_names+=("$display_name")
            i=$((i+1))
        fi
    done < <(echo "$models_json" | jq -c '.models[]')

    if [ ${#model_names[@]} -eq 0 ]; then
        echo "No se encontraron modelos disponibles que soporten 'generateContent'." >&2
        return 1
    fi

    echo "Modelos disponibles para 'generateContent':"
    for (( j=0; j<${#model_names[@]}; j++ )); do
        echo "$((j+1)). ${model_display_names[j]} (${model_names[j]})"
    done

    echo -n "Introduce el número del modelo que deseas usar: "
    read -r selection

    # Valida la selección del usuario
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#model_names[@]}" ]; then
        CURRENT_GEMINI_MODEL="${model_names[$((selection-1))]}"
        save_gemini_config # Guarda el nuevo modelo en la configuración
        echo "Modelo cambiado a: $CURRENT_GEMINI_MODEL"
    else
        echo "Selección inválida. El modelo no ha cambiado." >&2
    fi
}

# --- Función Principal 'ai' ---
# Esta es la función que se ejecutará cuando escribas 'ai' en la terminal.
ai() {
    # Carga la configuración al inicio de cada llamada
    if ! load_gemini_config; then
        return 1 # Sale si la clave API no está configurada
    fi

    local first_arg="$1"
    local prompt_text=""
    local context=""

    # Manejo de argumentos
    case "$first_arg" in
        @history)
            local num_messages="$2"
            shift 2 # Elimina @history y el número
            prompt_text="$*" # El resto es el prompt
            if [[ "$num_messages" =~ ^[0-9]+$ ]] && [ "$num_messages" -gt 0 ]; then
                context=$(get_gemini_history_context "$num_messages")
            else
                echo "Uso: ai @history <número> <tu_petición>" >&2
                return 1
            fi
            ;;
        @latest)
            shift 1 # Elimina @latest
            prompt_text="$*" # El resto es el prompt
            # @latest envía la última interacción (último comando del usuario y última respuesta de la IA)
            context=$(get_gemini_history_context 2)
            ;;
        @switch_model)
            switch_gemini_model
            return $? # Devuelve el código de salida de switch_gemini_model
            ;;
        *)
            # Si no hay argumentos especiales, todo es el prompt
            prompt_text="$*"
            ;;
    esac

    # Si hay un prompt para enviar a la IA
    if [ -n "$prompt_text" ]; then
        # Añade el comando del usuario al historial
        append_to_gemini_history "command" "$prompt_text"
        # Llama a la API de Gemini
        call_gemini_api "$prompt_text" "$context"
    else
        # Muestra el mensaje de uso si no se proporciona un prompt o argumento válido
        echo "Uso: ai [opciones] <tu_petición>"
        echo "Opciones:"
        echo "  ai <tu_petición>             : Envía una nueva petición a la IA."
        echo "  ai @history <número> <petición> : Envía las últimas <número> interacciones (comandos y respuestas de la IA) como contexto."
        echo "  ai @latest <petición>      : Envía la última interacción (tu último comando a 'ai' y la última respuesta de la IA) como contexto."
        echo "  ai @switch_model           : Muestra los modelos de IA disponibles y te permite cambiar el modelo actual."
        return 1
    fi
}
