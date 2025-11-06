// Puppeteer Launch Args Wrapper for Docker
// This wraps puppeteer.launch() to automatically inject --no-sandbox flags

const Module = require('module');
const originalRequire = Module.prototype.require;

Module.prototype.require = function (id) {
  const module = originalRequire.apply(this, arguments);
  
  // Intercept puppeteer module
  if (id === 'puppeteer' || id === 'puppeteer-core') {
    const originalLaunch = module.launch;
    
    module.launch = function(options = {}) {
      // Docker-safe default args
      const dockerArgs = [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--single-process' // Additional flag for root execution
      ];
      
      // Merge with existing args
      const existingArgs = options.args || [];
      options.args = [...new Set([...dockerArgs, ...existingArgs])]; // Remove duplicates
      
      console.log('[Puppeteer Wrapper] Launching with args:', options.args);
      
      return originalLaunch.call(this, options);
    };
  }
  
  return module;
};

console.log('[Puppeteer Wrapper] Initialized - will inject --no-sandbox to all puppeteer.launch() calls');
