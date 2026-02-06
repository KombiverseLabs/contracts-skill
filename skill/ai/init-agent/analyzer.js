#!/usr/bin/env node
/**
 * Contract Analyzer - AI-Assisted Semantic Project Analysis
 * 
 * This module performs semantic analysis of a codebase to identify
 * modules that would benefit from contracts. Instead of using fixed
 * patterns, it analyzes:
 * - Project structure and configuration
 * - Source code organization
 * - Import/export relationships
 * - Existing documentation
 * 
 * The AI uses this analysis to make informed decisions about where
 * contracts should be placed.
 */

const fs = require('fs');
const path = require('path');

/**
 * Configuration for different project types
 */
const PROJECT_PATTERNS = {
  // Node.js / JavaScript / TypeScript
  nodejs: {
    configFiles: ['package.json', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml'],
    sourceDirs: ['src', 'lib', 'app', 'pages', 'api', 'server', 'client'],
    moduleIndicators: ['index.js', 'index.ts', 'index.jsx', 'index.tsx', 'main.js'],
    testPatterns: ['*.test.js', '*.test.ts', '*.spec.js', '*.spec.ts'],
    ignoreDirs: ['node_modules', 'dist', 'build', '.git', 'coverage', '.next', '.nuxt']
  },
  // Python
  python: {
    configFiles: ['pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile'],
    sourceDirs: ['src', 'app', 'api', 'core', 'utils', 'lib', 'modules', 'packages'],
    moduleIndicators: ['__init__.py'],
    testPatterns: ['test_*.py', '*_test.py'],
    ignoreDirs: ['__pycache__', '.venv', 'venv', 'env', 'dist', 'build', '.git', '.pytest_cache']
  },
  // Go
  go: {
    configFiles: ['go.mod', 'go.sum'],
    sourceDirs: ['cmd', 'internal', 'pkg', 'api', 'web', 'services'],
    moduleIndicators: ['main.go'],
    testPatterns: ['*_test.go'],
    ignoreDirs: ['vendor', 'bin', '.git']
  },
  // Rust
  rust: {
    configFiles: ['Cargo.toml', 'Cargo.lock'],
    sourceDirs: ['src', 'crates', 'libs'],
    moduleIndicators: ['main.rs', 'lib.rs'],
    testPatterns: [],
    ignoreDirs: ['target', '.git']
  },
  // Generic fallback
  generic: {
    configFiles: ['README.md', 'LICENSE'],
    sourceDirs: ['src', 'source', 'lib', 'app', 'core', 'features', 'modules'],
    moduleIndicators: [],
    testPatterns: [],
    ignoreDirs: ['.git', 'dist', 'build', 'out', 'target', 'node_modules', '__pycache__', '.venv']
  }
};

/**
 * Detect project type based on configuration files
 * @param {string} root - Project root directory
 * @returns {string} - Project type key
 */
function detectProjectType(root) {
  const files = fs.readdirSync(root);
  
  for (const [type, config] of Object.entries(PROJECT_PATTERNS)) {
    if (type === 'generic') continue;
    
    const hasConfig = config.configFiles.some(f => files.includes(f));
    if (hasConfig) {
      return type;
    }
  }
  
  return 'generic';
}

/**
 * Read and parse package.json if it exists
 * @param {string} root - Project root
 * @returns {object|null} - Parsed package.json or null
 */
function readPackageJson(root) {
  const pkgPath = path.join(root, 'package.json');
  if (!fs.existsSync(pkgPath)) return null;
  
  try {
    return JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
  } catch {
    return null;
  }
}

/**
 * Read and parse pyproject.toml if it exists
 * @param {string} root - Project root
 * @returns {object|null} - Parsed pyproject.toml or null
 */
function readPyProject(root) {
  const ppPath = path.join(root, 'pyproject.toml');
  if (!fs.existsSync(ppPath)) return null;
  
  try {
    const content = fs.readFileSync(ppPath, 'utf8');
    // Simple parsing for key sections
    const result = { name: null, description: null };
    
    const nameMatch = content.match(/name\s*=\s*["']([^"']+)["']/);
    if (nameMatch) result.name = nameMatch[1];
    
    const descMatch = content.match(/description\s*=\s*["']([^"']+)["']/);
    if (descMatch) result.description = descMatch[1];
    
    return result;
  } catch {
    return null;
  }
}

/**
 * Read README for project description
 * @param {string} root - Project root
 * @returns {string|null} - README content or null
 */
function readReadme(root) {
  const readmeNames = ['README.md', 'README.txt', 'README.rst', 'README'];
  
  for (const name of readmeNames) {
    const readmePath = path.join(root, name);
    if (fs.existsSync(readmePath)) {
      try {
        const content = fs.readFileSync(readmePath, 'utf8');
        // Return first 2000 chars for analysis
        return content.slice(0, 2000);
      } catch {
        continue;
      }
    }
  }
  
  return null;
}

/**
 * Check if a directory should be ignored
 * @param {string} dirName - Directory name
 * @param {string[]} ignoreList - List of patterns to ignore
 * @returns {boolean}
 */
function shouldIgnoreDir(dirName, ignoreList) {
  return ignoreList.some(pattern => {
    if (pattern.includes('*')) {
      const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
      return regex.test(dirName);
    }
    return dirName === pattern;
  });
}

/**
 * Calculate directory complexity score
 * @param {string} dirPath - Directory path
 * @param {number} depth - Current recursion depth
 * @returns {object} - Complexity metrics
 */
function analyzeDirectoryComplexity(dirPath, depth = 0) {
  const metrics = {
    fileCount: 0,
    lineCount: 0,
    subDirCount: 0,
    hasEntryPoint: false,
    hasTests: false,
    maxDepth: depth
  };
  
  try {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dirPath, entry.name);
      
      if (entry.isDirectory()) {
        metrics.subDirCount++;
        if (depth < 3) { // Limit recursion depth
          const subMetrics = analyzeDirectoryComplexity(fullPath, depth + 1);
          metrics.fileCount += subMetrics.fileCount;
          metrics.lineCount += subMetrics.lineCount;
          metrics.maxDepth = Math.max(metrics.maxDepth, subMetrics.maxDepth);
        }
      } else if (entry.isFile()) {
        const ext = path.extname(entry.name);
        if (['.js', '.ts', '.jsx', '.tsx', '.py', '.go', '.rs', '.java'].includes(ext)) {
          metrics.fileCount++;
          
          try {
            const content = fs.readFileSync(fullPath, 'utf8');
            metrics.lineCount += content.split('\n').length;
          } catch {
            // Ignore files we can't read
          }
        }
        
        // Check for entry points
        if (['index.js', 'index.ts', 'main.js', 'main.ts', '__init__.py', 'main.go'].includes(entry.name)) {
          metrics.hasEntryPoint = true;
        }
        
        // Check for tests
        if (entry.name.includes('.test.') || entry.name.includes('.spec.') || entry.name.includes('_test.')) {
          metrics.hasTests = true;
        }
      }
    }
  } catch {
    // Permission denied or other error
  }
  
  return metrics;
}

/**
 * Extract exports from a JavaScript/TypeScript file
 * @param {string} filePath - Path to source file
 * @returns {string[]} - Array of exported names
 */
function extractJsExports(filePath) {
  const exports = [];
  
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Match ES6 exports
    const es6Matches = content.match(/export\s+(?:const|let|var|function|class|interface|type)?\s+(\w+)/g);
    if (es6Matches) {
      es6Matches.forEach(match => {
        const name = match.match(/\b(\w+)$/);
        if (name) exports.push(name[1]);
      });
    }
    
    // Match export { ... }
    const exportBlock = content.match(/export\s*\{([^}]+)\}/g);
    if (exportBlock) {
      exportBlock.forEach(block => {
        const names = block.replace(/export\s*\{|\}/g, '').split(',');
        names.forEach(n => {
          const clean = n.trim().split(' ')[0]; // Handle 'as' syntax
          if (clean) exports.push(clean);
        });
      });
    }
    
    // Match module.exports
    const cjsMatches = content.match(/module\.exports\s*=\s*\{([^}]+)\}/);
    if (cjsMatches) {
      const pairs = cjsMatches[1].split(',');
      pairs.forEach(pair => {
        const name = pair.split(':')[0].trim();
        if (name) exports.push(name);
      });
    }
  } catch {
    // Ignore errors
  }
  
  return [...new Set(exports)]; // Remove duplicates
}

/**
 * Extract public API from Python module
 * @param {string} dirPath - Module directory path
 * @returns {string[]} - Array of exported names
 */
function extractPythonExports(dirPath) {
  const exports = [];
  const initPath = path.join(dirPath, '__init__.py');
  
  if (!fs.existsSync(initPath)) return exports;
  
  try {
    const content = fs.readFileSync(initPath, 'utf8');
    
    // Match __all__ definition
    const allMatch = content.match(/__all__\s*=\s*\[([^\]]+)\]/);
    if (allMatch) {
      const items = allMatch[1].match(/['"]([^'"]+)['"]/g);
      if (items) {
        items.forEach(item => {
          exports.push(item.replace(/['"]/g, ''));
        });
      }
    }
    
    // Match from X import Y
    const importMatches = content.match(/from\s+\S+\s+import\s+(.+)/g);
    if (importMatches) {
      importMatches.forEach(match => {
        const names = match.replace(/from\s+\S+\s+import\s+/, '').split(',');
        names.forEach(n => {
          const clean = n.trim().split(' ')[0];
          if (clean && clean !== '*') exports.push(clean);
        });
      });
    }
  } catch {
    // Ignore errors
  }
  
  return [...new Set(exports)];
}

/**
 * Analyze a potential module directory
 * @param {string} dirPath - Full directory path
 * @param {string} relPath - Relative path from project root
 * @param {string} projectType - Detected project type
 * @returns {object|null} - Module analysis or null
 */
function analyzePotentialModule(dirPath, relPath, projectType) {
  const dirName = path.basename(dirPath);
  const pattern = PROJECT_PATTERNS[projectType] || PROJECT_PATTERNS.generic;
  
  // Skip ignored directories
  if (shouldIgnoreDir(dirName, pattern.ignoreDirs)) {
    return null;
  }
  
  const metrics = analyzeDirectoryComplexity(dirPath);
  
  // Skip very small directories (likely not a module)
  if (metrics.fileCount < 1 && metrics.subDirCount < 1) {
    return null;
  }
  
  // Determine module type based on path
  let moduleType = 'feature';
  if (relPath.includes('core') || relPath.includes('lib') || relPath.includes('pkg')) {
    moduleType = 'core';
  } else if (relPath.includes('integration') || relPath.includes('adapter')) {
    moduleType = 'integration';
  } else if (relPath.includes('util') || relPath.includes('helper')) {
    moduleType = 'utility';
  }
  
  // Determine tier based on complexity
  let tier = 'standard';
  if (metrics.lineCount < 100 && metrics.subDirCount <= 1) {
    tier = 'core';
  } else if (metrics.lineCount > 500 || metrics.subDirCount > 3) {
    tier = 'complex';
  }
  
  // Extract exports based on project type
  let exports = [];
  if (projectType === 'nodejs') {
    const entryPoint = ['index.js', 'index.ts', 'index.jsx', 'index.tsx']
      .map(f => path.join(dirPath, f))
      .find(p => fs.existsSync(p));
    if (entryPoint) {
      exports = extractJsExports(entryPoint);
    }
  } else if (projectType === 'python') {
    exports = extractPythonExports(dirPath);
  }
  
  return {
    name: dirName,
    path: relPath,
    type: moduleType,
    tier: tier,
    metrics: metrics,
    exports: exports.slice(0, 10), // Limit to first 10 exports
    hasEntryPoint: metrics.hasEntryPoint,
    hasTests: metrics.hasTests
  };
}

/**
 * Recursively scan for modules
 * @param {string} root - Project root
 * @param {string} currentDir - Current directory being scanned
 * @param {string} projectType - Detected project type
 * @param {number} depth - Current depth
 * @param {object[]} modules - Accumulated modules
 * @returns {object[]} - Found modules
 */
function scanForModules(root, currentDir, projectType, depth = 0, modules = []) {
  if (depth > 4) return modules; // Limit depth
  
  const pattern = PROJECT_PATTERNS[projectType] || PROJECT_PATTERNS.generic;
  
  try {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      
      const dirPath = path.join(currentDir, entry.name);
      const relPath = path.relative(root, dirPath);
      
      if (shouldIgnoreDir(entry.name, pattern.ignoreDirs)) continue;
      
      // Check if this is a likely module
      const moduleInfo = analyzePotentialModule(dirPath, relPath, projectType);
      
      if (moduleInfo && moduleInfo.metrics.fileCount > 0) {
        modules.push(moduleInfo);
      }
      
      // Recurse into subdirectories
      scanForModules(root, dirPath, projectType, depth + 1, modules);
    }
  } catch {
    // Permission denied or other error
  }
  
  return modules;
}

/**
 * Perform complete project analysis
 * @param {string} root - Project root directory
 * @returns {object} - Complete analysis result
 */
function analyzeProject(root) {
  const resolvedRoot = path.resolve(root);
  
  // 1. Detect project type
  const projectType = detectProjectType(resolvedRoot);
  
  // 2. Read project metadata
  const packageJson = projectType === 'nodejs' ? readPackageJson(resolvedRoot) : null;
  const pyProject = projectType === 'python' ? readPyProject(resolvedRoot) : null;
  const readme = readReadme(resolvedRoot);
  
  // 3. Scan for modules
  const pattern = PROJECT_PATTERNS[projectType] || PROJECT_PATTERNS.generic;
  let modules = [];
  
  // Scan standard source directories first
  for (const srcDir of pattern.sourceDirs) {
    const fullPath = path.join(resolvedRoot, srcDir);
    if (fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory()) {
      scanForModules(resolvedRoot, fullPath, projectType, 0, modules);
    }
  }
  
  // If no modules found in standard dirs, scan root (but not too deep)
  if (modules.length === 0) {
    const rootEntries = fs.readdirSync(resolvedRoot, { withFileTypes: true });
    for (const entry of rootEntries) {
      if (entry.isDirectory() && !shouldIgnoreDir(entry.name, pattern.ignoreDirs)) {
        const dirPath = path.join(resolvedRoot, entry.name);
        const relPath = entry.name;
        const moduleInfo = analyzePotentialModule(dirPath, relPath, projectType);
        if (moduleInfo && moduleInfo.metrics.fileCount > 2) {
          modules.push(moduleInfo);
        }
      }
    }
  }
  
  // 4. Score and rank modules
  modules = modules.map(m => ({
    ...m,
    score: calculateModuleScore(m)
  })).sort((a, b) => b.score - a.score);
  
  // 5. Return complete analysis
  return {
    project: {
      path: resolvedRoot,
      type: projectType,
      name: packageJson?.name || pyProject?.name || path.basename(resolvedRoot),
      description: packageJson?.description || pyProject?.description || null,
      readme: readme
    },
    modules: modules,
    recommendations: generateRecommendations(modules)
  };
}

/**
 * Calculate a relevance score for a module
 * @param {object} moduleInfo - Module information
 * @returns {number} - Score (higher = more important)
 */
function calculateModuleScore(moduleInfo) {
  let score = 0;
  
  // Complexity score
  score += Math.min(moduleInfo.metrics.lineCount / 10, 50);
  score += moduleInfo.metrics.subDirCount * 5;
  
  // Quality indicators
  if (moduleInfo.hasEntryPoint) score += 10;
  if (moduleInfo.hasTests) score += 10;
  if (moduleInfo.exports.length > 0) score += moduleInfo.exports.length * 2;
  
  // Type bonus
  if (moduleInfo.type === 'core') score += 20;
  
  return score;
}

/**
 * Generate recommendations for which modules should have contracts
 * @param {object[]} modules - All found modules
 * @returns {object[]} - Recommended modules with reasoning
 */
function generateRecommendations(modules) {
  // Take top modules by score
  const topModules = modules
    .filter(m => m.score > 15) // Threshold
    .slice(0, 10); // Max 10 recommendations
  
  return topModules.map(m => ({
    ...m,
    reasoning: generateReasoning(m)
  }));
}

/**
 * Generate human-readable reasoning for a recommendation
 * @param {object} moduleInfo - Module information
 * @returns {string} - Reasoning text
 */
function generateReasoning(moduleInfo) {
  const reasons = [];
  
  if (moduleInfo.metrics.lineCount > 200) {
    reasons.push('significant codebase');
  }
  if (moduleInfo.exports.length > 5) {
    reasons.push('public API surface');
  }
  if (moduleInfo.hasTests) {
    reasons.push('test coverage exists');
  }
  if (moduleInfo.type === 'core') {
    reasons.push('core functionality');
  }
  if (moduleInfo.metrics.subDirCount > 2) {
    reasons.push('complex structure');
  }
  
  if (reasons.length === 0) {
    return 'moderate complexity module';
  }
  
  return reasons.join(', ');
}

/**
 * Generate contract draft for a module
 * @param {object} moduleInfo - Module information
 * @param {object} projectInfo - Project information
 * @returns {object} - Contract draft content
 */
function generateContractDraft(moduleInfo, projectInfo) {
  const name = moduleInfo.name
    .split('-')
    .map(w => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');

  // Purpose: prompt user to describe the problem, not list exports
  let purpose = `<!-- What user problem does ${name} solve? Don't just list exports. -->\n`;
  if (moduleInfo.type === 'core') {
    purpose += `Handles [describe responsibility] for ${projectInfo.name || 'the project'}.`;
  } else if (moduleInfo.type === 'integration') {
    purpose += `Connects to [external system] to provide [capability] for ${projectInfo.name || 'the project'}.`;
  } else {
    purpose += `Enables [describe user-facing value] in ${projectInfo.name || 'the project'}.`;
  }

  // Features: map each export to a test file
  const testPattern = moduleInfo.hasTests ? moduleInfo.name + '.test.*' : 'TODO';
  const features = moduleInfo.exports
    .slice(0, 5)
    .map(exp => `- [ ] ${exp}: [describe behavior] → Test: ${testPattern}`);

  if (features.length === 0) {
    features.push(`- [ ] [Core capability]: [describe behavior] → Test: ${testPattern}`);
  }

  // Constraints: type-specific, testable
  const constraints = [];
  if (moduleInfo.type === 'core') {
    constraints.push('- MUST: Maintain backward compatibility for public API exports');
    constraints.push('- MUST NOT: Introduce breaking changes without version bump');
  } else if (moduleInfo.type === 'integration') {
    constraints.push('- MUST: Handle API errors and timeouts gracefully');
    constraints.push('- MUST NOT: Expose credentials in logs or error messages');
  } else {
    constraints.push('- MUST: [define testable requirement]');
    constraints.push('- MUST NOT: [define anti-pattern to prevent]');
  }

  // Success criteria: testable Given/When/Then format
  const successCriteria = generateTestableSuccessCriteria(moduleInfo);

  const mdContent = `<!-- DRAFT: Review and modify, then remove this line -->
# ${name}

## Purpose
${purpose}

## Core Features
${features.join('\n')}

## Constraints
${constraints.join('\n')}

## Success Criteria
${successCriteria}
`;

  return {
    markdown: mdContent,
    moduleInfo: moduleInfo
  };
}

/**
 * Generate testable success criteria based on module analysis
 * @param {object} moduleInfo - Module information
 * @returns {string} - Success criteria text
 */
function generateTestableSuccessCriteria(moduleInfo) {
  const criteria = [];

  if (moduleInfo.exports.length > 0) {
    const mainExport = moduleInfo.exports[0];
    criteria.push(`- [ ] Given valid input, when ${mainExport}() is called, then [expected outcome]`);
    criteria.push(`- [ ] Given invalid input, when ${mainExport}() is called, then [expected error handling]`);
  }

  if (moduleInfo.type === 'integration') {
    criteria.push('- [ ] Given API timeout, when requesting, then retries with backoff');
    criteria.push('- [ ] Given service unavailable, then degrades gracefully');
  }

  if (criteria.length === 0) {
    criteria.push('- [ ] Given [context], when [action], then [expected outcome]');
  }

  criteria.push('<!-- Define: what would a failing test look like for each criterion? -->');

  return criteria.join('\n');
}

// Export for use in other modules
module.exports = {
  analyzeProject,
  generateContractDraft,
  PROJECT_PATTERNS,
  detectProjectType,
  calculateModuleScore
};

// CLI mode
if (require.main === module) {
  const root = process.argv[2] || '.';
  
  console.log('🔍 Analyzing project for contract initialization...\n');
  
  const analysis = analyzeProject(root);
  
  console.log(`Project: ${analysis.project.name}`);
  console.log(`Type: ${analysis.project.type}`);
  if (analysis.project.description) {
    console.log(`Description: ${analysis.project.description}`);
  }
  console.log('');
  
  console.log(`Found ${analysis.modules.length} potential modules:`);
  console.log('');
  
  analysis.modules.slice(0, 10).forEach((m, i) => {
    console.log(`${i + 1}. ${m.name} (${m.type}, ${m.tier})`);
    console.log(`   Path: ${m.path}`);
    console.log(`   Files: ${m.metrics.fileCount}, Lines: ${m.metrics.lineCount}, Score: ${m.score.toFixed(1)}`);
    if (m.exports.length > 0) {
      console.log(`   Exports: ${m.exports.slice(0, 5).join(', ')}${m.exports.length > 5 ? '...' : ''}`);
    }
    console.log('');
  });
  
  console.log('\n📋 Top Recommendations for Contracts:');
  console.log('=====================================\n');
  
  analysis.recommendations.forEach((rec, i) => {
    console.log(`${i + 1}. ${rec.name}`);
    console.log(`   Reason: ${rec.reasoning}`);
    console.log(`   Suggested tier: ${rec.tier}`);
    console.log('');
  });
  
  // Output JSON for programmatic use
  if (process.argv.includes('--json')) {
    console.log('\n---JSON---');
    console.log(JSON.stringify(analysis, null, 2));
  }
}
