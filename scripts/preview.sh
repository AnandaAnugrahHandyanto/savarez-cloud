#!/bin/bash

# Source common libraries and config
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

# --- Script Variables ---
PORT=8000

# --- Usage Function ---
usage() {
    echo -e "${YELLOW}Usage: $0 [PORT]${NC}"
    echo -e "${YELLOW}  PORT (optional): The port number for the local web server (default: 8000).${NC}"
    exit 1
}

# --- Argument Parsing ---
if [ "$#" -ge 1 ]; then
    PORT="$1"
fi

# Check dependencies (python3, xdg-open/open/start for browser)
check_dependencies "python3"

# Find a suitable browser open command
BROWSER_OPEN_CMD=""
if command -v xdg-open &> /dev/null; then
    BROWSER_OPEN_CMD="xdg-open"
elif command -v open &> /dev/null; then # macOS
    BROWSER_OPEN_CMD="open"
elif command -v start &> /dev/null; then # Windows (WSL)
    BROWSER_OPEN_CMD="start"
fi

if [ -z "$BROWSER_OPEN_CMD" ]; then
    log WARN "Could not find a command to open the browser automatically (xdg-open, open, start). Please open the URL manually."
fi

log INFO "Starting local preview server for ${SAVAREZ_THEME_APP_NAME}..."

# Create a temporary HTML file for preview
PREVIEW_HTML_PATH="${LOCAL_APP_PATH}/preview.html"
cat > "${PREVIEW_HTML_PATH}" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Savarez Theme Preview</title>
    <link rel="stylesheet" href="./css/style.css">
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #1a1a2e; /* From layout.css */
            color: #e0e0e0;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            margin: 40px auto;
            background-color: rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            backdrop-filter: blur(5px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            padding: 30px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
        }
        h1 {
            color: #9c27b0; /* Savarez accent */
            margin-bottom: 20px;
        }
        .card-example {
            width: 250px;
            height: 150px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.2em;
            margin-bottom: 20px;
        }
        .button-example {
            padding: 10px 20px;
            border: none;
            cursor: pointer;
            font-size: 1em;
        }
        .button-example:hover {
            background-color: rgba(255, 255, 255, 0.15);
        }
        .breadcrumb-example {
            padding: 10px;
            margin-top: 20px;
        }
        .file-list-example .file-list-item {
            width: 100%;
            cursor: pointer;
        }
        .file-list-example .file-list-item:nth-child(even) {
            background-color: rgba(255, 255, 255, 0.08);
        }
        .file-list-example .file-list-item.selected {
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Savarez Theme Local Preview</h1>

        <h2>Card Example</h2>
        <div class="oc-background-container card-example">A Sample Card</div>

        <h2>Button Example</h2>
        <button class="button button-example">Click Me</button>
        <button class="icon-button button-example">&#9889; Icon Button</button>

        <h2>Breadcrumb Example</h2>
        <nav class="breadcrumb breadcrumb-example">
            <a href="#">Home</a> <span class="icon-triangle-n"></span>
            <a href="#">Files</a> <span class="icon-triangle-n"></span>
            <span>My Documents</span>
        </nav>

        <h2>File List Example</h2>
        <div class="file-list-example">
            <div class="file-list-item">Document 1.pdf</div>
            <div class="file-list-item selected">Selected Photo.jpg</div>
            <div class="file-list-item">Presentation.pptx</div>
        </div>

        <h2>Empty State Example</h2>
        <div class="emptycontent">
            <h3 class="emptycontent__title">No files here yet!</h3>
            <p class="emptycontent__text">Drag and drop files to get started.</p>
        </div>

    </div>
</body>
</html>
EOF

# Navigate to the app directory (where preview.html and css/ are)
cd "${LOCAL_APP_PATH}" || error_exit "Could not navigate to local app path: ${LOCAL_APP_PATH}"

log INFO "Starting Python HTTP server on port ${PORT}..."
python3 -m http.server "$PORT" & # Run in background
SERVER_PID=$!

# Give server a moment to start
sleep 1

LOCAL_URL="http://localhost:${PORT}/preview.html"
log SUCCESS "Preview server running at: ${LOCAL_URL}"

if [ -n "$BROWSER_OPEN_CMD" ]; then
    log INFO "Opening browser..."
    "$BROWSER_OPEN_CMD" "$LOCAL_URL"
fi

log INFO "Press Ctrl+C to stop the server."
wait $SERVER_PID # Wait for the server process to be stopped

log INFO "Stopping local preview server."
# Clean up temporary preview.html file
rm "${PREVIEW_HTML_PATH}"
log SUCCESS "Preview server stopped and temporary files cleaned up."
