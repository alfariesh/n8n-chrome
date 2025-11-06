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
# Need to patch BOTH .ts and .js files as n8n might use either one
PUPPETEER_BASE_PATH="/opt/n8n-custom-nodes/node_modules/n8n-nodes-puppeteer"

patch_puppeteer_file() {
    local file_path="$1"
    local file_type="$2"
    
    if [ ! -f "$file_path" ]; then
        return 1
    fi
    
    # Check if already patched
    if grep -q "no-sandbox" "$file_path"; then
        echo "  ✓ $file_type already patched"
        return 0
    fi
    
    echo "  → Patching $file_type..."
    
    # Create backup
    cp "$file_path" "$file_path.bak"
    
    # Apply patch using Node.js
    node -e "
const fs = require('fs');
const filePath = '$file_path';
let content = fs.readFileSync(filePath, 'utf8');

// Docker-safe Chrome arguments
const dockerArgs = [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-gpu',
    '--disable-accelerated-2d-canvas',
    '--no-first-run',
    '--no-zygote'
];

const argsString = JSON.stringify(dockerArgs);

// Pattern 1: puppeteer.launch({ existing options })
content = content.replace(
    /puppeteer\.launch\(\s*\{/g,
    \`puppeteer.launch({ args: \${argsString},\`
);

// Pattern 2: puppeteer.launch() with no args
content = content.replace(
    /puppeteer\.launch\(\s*\)/g,
    \`puppeteer.launch({ args: \${argsString} })\`
);

// Pattern 3: await puppeteer.launch (with optional whitespace)
content = content.replace(
    /(await\s+puppeteer\.launch\()(\s*\{)/g,
    \`\$1{ args: \${argsString},\`
);

fs.writeFileSync(filePath, content, 'utf8');
" && echo "    ✓ Patch applied to $file_type" || echo "    ✗ Failed to patch $file_type"
}

echo "Patching n8n-nodes-puppeteer for Docker compatibility..."

# Try to patch both JS and TS files
PATCHED=0

# Patch dist/nodes/Puppeteer/Puppeteer.node.js
if patch_puppeteer_file "$PUPPETEER_BASE_PATH/dist/nodes/Puppeteer/Puppeteer.node.js" "JS file"; then
    PATCHED=1
fi

# Patch nodes/Puppeteer/Puppeteer.node.ts (if exists)
if patch_puppeteer_file "$PUPPETEER_BASE_PATH/nodes/Puppeteer/Puppeteer.node.ts" "TS file"; then
    PATCHED=1
fi

if [ $PATCHED -eq 0 ]; then
    echo "  ⚠ Warning: n8n-nodes-puppeteer files not found yet"
else
    echo "✓ Puppeteer patching complete"
fi

print_banner

# Execute the original n8n entrypoint script
exec /docker-entrypoint.sh "$@"
