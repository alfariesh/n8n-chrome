#!/bin/sh

print_banner() {
    echo "----------------------------------------"
    echo "n8n Puppeteer Node - Environment Details"
    echo "----------------------------------------"
    echo "Node.js version: $(node -v)"
    echo "n8n version: $(n8n --version)"

    # Get Chromium version specifically from the path we're using for Puppeteer
    CHROME_VERSION=$("$PUPPETEER_EXECUTABLE_PATH" --version 2>/dev/null || echo "Chromium not found")
    echo "Chromium version: $CHROME_VERSION"

    # Get Puppeteer version if installed
    PUPPETEER_PATH="/opt/n8n-custom-nodes/node_modules/n8n-nodes-puppeteer"
    if [ -f "$PUPPETEER_PATH/package.json" ]; then
        PUPPETEER_VERSION=$(node -p "require('$PUPPETEER_PATH/package.json').version")
        echo "n8n-nodes-puppeteer version: $PUPPETEER_VERSION"

        # Try to resolve puppeteer package from the n8n-nodes-puppeteer directory
        CORE_PUPPETEER_VERSION=$(cd "$PUPPETEER_PATH" && node -e "try { const version = require('puppeteer/package.json').version; console.log(version); } catch(e) { console.log('not found'); }")
        echo "Puppeteer core version: $CORE_PUPPETEER_VERSION"
    else
        echo "n8n-nodes-puppeteer: not installed"
    fi

    echo "Puppeteer executable path: $PUPPETEER_EXECUTABLE_PATH"
    echo "----------------------------------------"
}

# Add custom nodes to the NODE_PATH
if [ -n "$N8N_CUSTOM_EXTENSIONS" ]; then
    export N8N_CUSTOM_EXTENSIONS="/opt/n8n-custom-nodes:${N8N_CUSTOM_EXTENSIONS}"
else
    export N8N_CUSTOM_EXTENSIONS="/opt/n8n-custom-nodes"
fi

# Patch n8n-nodes-puppeteer to add --no-sandbox flags
PUPPETEER_NODE_JS="/opt/n8n-custom-nodes/node_modules/n8n-nodes-puppeteer/dist/nodes/Puppeteer/Puppeteer.node.js"

if [ -f "$PUPPETEER_NODE_JS" ]; then
    echo "Patching n8n-nodes-puppeteer for Docker compatibility..."
    
    # Check if already patched
    if ! grep -q "no-sandbox" "$PUPPETEER_NODE_JS"; then
        # Create backup
        cp "$PUPPETEER_NODE_JS" "$PUPPETEER_NODE_JS.bak"
        
        # Patch the file to add default args
        # Find "const browser = await puppeteer.launch" and inject args
        node -e "
const fs = require('fs');
const filePath = '$PUPPETEER_NODE_JS';
let content = fs.readFileSync(filePath, 'utf8');

// Add args to puppeteer.launch calls
const dockerArgs = [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-gpu',
    '--disable-accelerated-2d-canvas',
    '--no-first-run',
    '--no-zygote'
];

// Pattern 1: launch with object argument
content = content.replace(
    /puppeteer\.launch\(\s*\{/g,
    \`puppeteer.launch({ args: \${JSON.stringify(dockerArgs)},\`
);

// Pattern 2: launch with empty/no arguments  
content = content.replace(
    /puppeteer\.launch\(\s*\)/g,
    \`puppeteer.launch({ args: \${JSON.stringify(dockerArgs)} })\`
);

fs.writeFileSync(filePath, content, 'utf8');
console.log('Patch applied successfully');
"
        
        echo "✓ Puppeteer node patched for Docker"
    else
        echo "✓ Puppeteer node already patched"
    fi
else
    echo "⚠ Warning: n8n-nodes-puppeteer not found yet (will be available after first start)"
fi

print_banner

# Execute the original n8n entrypoint script
exec /docker-entrypoint.sh "$@"
