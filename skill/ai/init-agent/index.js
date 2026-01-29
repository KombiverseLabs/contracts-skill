#!/usr/bin/env node
/**
 * AI-Assisted Contract Initialization Agent
 * 
 * This tool performs AI-assisted initialization of contracts for a project.
 * Unlike the old pattern-based approach, it uses semantic analysis of the
 * codebase to intelligently identify modules that need contracts.
 * 
 * Usage:
 *   # Analyze and show recommendations (AI-assisted mode)
 *   node index.js --path . --analyze
 * 
 *   # Generate contract drafts for recommended modules
 *   node index.js --path . --recommend
 * 
 *   # Dry-run (show what would be created)
 *   node index.js --path . --dry-run
 * 
 *   # Apply after confirmation
 *   node index.js --path . --apply
 * 
 *   # Create contract for specific module
 *   node index.js --path ./src/auth --module
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { analyzeProject, generateContractDraft } = require('./analyzer');

const COLORS = {
  reset: '\x1b[0m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  gray: '\x1b[90m'
};

function log(message, color = 'reset') {
  console.log(`${COLORS[color]}${message}${COLORS.reset}`);
}

function sha256(content) {
  const h = crypto.createHash('sha256');
  h.update(content);
  return 'sha256:' + h.digest('hex');
}

function makeYaml(name, type, relPath, hash, exports = []) {
  const date = new Date().toISOString();
  const shortDate = date.slice(0, 10);
  
  // Determine tier based on type
  const tier = type === 'core' ? 'core' : (type === 'complex' ? 'complex' : 'standard');
  
  // Build exports section
  const exportsYaml = exports.length > 0 
    ? exports.map(e => `    - "${e}"`).join('\n')
    : '    # Add public API exports here';

  return `# CONTRACT.yaml - Technical specification derived from CONTRACT.md
# This file is auto-synced with CONTRACT.md.

meta:
  source_hash: "${hash}"
  last_sync: "${date}"
  tier: ${tier}
  version: "1.0"

module:
  name: "${name}"
  type: "${type}"
  path: "${relPath.replace(/\\/g, '/')}"

features: []

constraints:
  must: []
  must_not: []

relationships:
  depends_on: []
  consumed_by: []

validation:
  exports:
${exportsYaml}
  test_pattern: "*.test.*"
  custom_script: null

changelog:
  - date: "${shortDate}"
    version: "1.0"
    change: "Initial contract (AI-assisted generation)"
    author: "init-agent"
`;
}

function findExistingContracts(root) {
  const contracts = [];
  
  function scan(dir) {
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        
        if (entry.isDirectory()) {
          // Skip common ignore directories
          if (['node_modules', '.git', 'dist', 'build', '.venv', '__pycache__'].includes(entry.name)) {
            continue;
          }
          scan(fullPath);
        } else if (entry.name === 'CONTRACT.md') {
          const yamlPath = path.join(dir, 'CONTRACT.yaml');
          contracts.push({
            mdPath: fullPath,
            yamlPath: fs.existsSync(yamlPath) ? yamlPath : null,
            dir: dir,
            relative: path.relative(root, dir)
          });
        }
      }
    } catch {
      // Ignore errors
    }
  }
  
  scan(root);
  return contracts;
}

async function analyzeMode(root) {
  log('🔍 AI-Assisted Project Analysis', 'cyan');
  log('================================\n');
  
  const analysis = analyzeProject(root);
  
  log(`Project: ${analysis.project.name}`, 'green');
  log(`Type: ${analysis.project.type}`);
  if (analysis.project.description) {
    log(`Description: ${analysis.project.description}`);
  }
  log('');
  
  log(`📊 Found ${analysis.modules.length} potential modules`, 'yellow');
  log('');
  
  // Show top modules
  analysis.modules.slice(0, 10).forEach((m, i) => {
    const hasContract = fs.existsSync(path.join(root, m.path, 'CONTRACT.md'));
    const status = hasContract ? '✓' : '○';
    log(`${status} ${i + 1}. ${m.name} (${m.type}, ${m.tier})`, hasContract ? 'gray' : 'reset');
    log(`   Path: ${m.path}`, 'gray');
    log(`   Files: ${m.metrics.fileCount}, Lines: ~${m.metrics.lineCount}, Score: ${m.score.toFixed(1)}`, 'gray');
    if (m.exports.length > 0) {
      log(`   Exports: ${m.exports.slice(0, 5).join(', ')}${m.exports.length > 5 ? '...' : ''}`, 'gray');
    }
    log('');
  });
  
  // Show recommendations
  if (analysis.recommendations.length > 0) {
    log('\n📋 Top Recommendations for Contracts:', 'cyan');
    log('=====================================\n');
    
    analysis.recommendations.forEach((rec, i) => {
      log(`${i + 1}. ${rec.name}`, 'yellow');
      log(`   Reason: ${rec.reasoning}`);
      log(`   Suggested tier: ${rec.tier}`);
      log(`   Path: ${rec.path}`);
      log('');
    });
    
    log('💡 Run with --recommend to generate contract drafts for these modules', 'cyan');
  }
  
  return analysis;
}

async function recommendMode(root, options = {}) {
  const analysis = analyzeProject(root);
  const drafts = [];
  
  log('🤖 Generating Contract Drafts (AI-Assisted)', 'cyan');
  log('============================================\n');
  
  for (const rec of analysis.recommendations) {
    const dirPath = path.join(root, rec.path);
    const contractMd = path.join(dirPath, 'CONTRACT.md');
    const contractYaml = path.join(dirPath, 'CONTRACT.yaml');
    
    // Skip if contract already exists
    if (fs.existsSync(contractMd) && !options.force) {
      log(`⏭️  Skipping ${rec.name} - CONTRACT.md already exists`, 'gray');
      continue;
    }
    
    // Generate draft
    const draft = generateContractDraft(rec, analysis.project);
    const hash = sha256(draft.markdown);
    const yaml = makeYaml(rec.name, rec.type, rec.path, hash, rec.exports);
    
    drafts.push({
      module: rec,
      mdContent: draft.markdown,
      yamlContent: yaml,
      mdPath: contractMd,
      yamlPath: contractYaml,
      exists: {
        md: fs.existsSync(contractMd),
        yaml: fs.existsSync(contractYaml)
      }
    });
    
    log(`📄 ${rec.name}`, 'yellow');
    log(`   Path: ${rec.path}`);
    log(`   Type: ${rec.type}, Tier: ${rec.tier}`);
    log(`   Reason: ${rec.reasoning}`);
    log('');
  }
  
  if (drafts.length === 0) {
    log('No new contract drafts to generate.', 'gray');
    return [];
  }
  
  log(`\n✨ Generated ${drafts.length} contract draft(s)\n`, 'green');
  
  // Show preview of first draft
  if (!options.quiet) {
    log('Preview of first draft:', 'cyan');
    log('=======================\n');
    log(drafts[0].mdContent);
    log('\n=======================\n');
  }
  
  return drafts;
}

async function dryRunMode(root) {
  const drafts = await recommendMode(root, { quiet: true });
  
  if (drafts.length === 0) {
    log('No contract drafts would be created.', 'yellow');
    return;
  }
  
  log('📋 Dry Run: Proposed Contracts', 'cyan');
  log('===============================\n');
  
  for (const draft of drafts) {
    log(`--- ${draft.module.path}/CONTRACT.md ---\n`, 'yellow');
    log(draft.mdContent);
    log('\n--- YAML ---\n');
    log(draft.yamlContent);
    log('\n' + '='.repeat(50) + '\n');
  }
  
  log(`Would create ${drafts.length} CONTRACT.md and ${drafts.length} CONTRACT.yaml file(s)`, 'cyan');
  log('\nRun with --apply to write these files to disk.', 'green');
}

async function applyMode(root, options = {}) {
  const drafts = await recommendMode(root, { quiet: true });
  
  if (drafts.length === 0) {
    log('No contracts to create.', 'yellow');
    return;
  }
  
  // If not forced, show what will be created and ask for confirmation
  if (!options.force) {
    log('📋 The following contracts will be created:', 'cyan');
    log('');
    
    for (const draft of drafts) {
      const statusMd = draft.exists.md ? '(overwrite)' : '(new)';
      const statusYaml = draft.exists.yaml ? '(overwrite)' : '(new)';
      log(`  ${draft.module.path}/CONTRACT.md ${statusMd}`);
      log(`  ${draft.module.path}/CONTRACT.yaml ${statusYaml}`);
    }
    
    log('\n⚠️  Note: This will create/modify files in your project.', 'yellow');
    
    if (!options.yes) {
      // In non-interactive environments, we can't ask
      log('\nUse --yes to confirm or --force to overwrite existing contracts.', 'cyan');
      return;
    }
  }
  
  // Create files
  const created = [];
  
  for (const draft of drafts) {
    const dir = path.dirname(draft.mdPath);
    
    // Ensure directory exists
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    // Write files
    fs.writeFileSync(draft.mdPath, draft.mdContent, 'utf8');
    fs.writeFileSync(draft.yamlPath, draft.yamlContent, 'utf8');
    
    created.push({
      md: draft.mdPath,
      yaml: draft.yamlPath
    });
    
    log(`✅ Created: ${path.relative(root, draft.mdPath)}`, 'green');
    log(`✅ Created: ${path.relative(root, draft.yamlPath)}`, 'green');
  }
  
  // Create or update registry
  await updateRegistry(root, drafts);
  
  log(`\n✨ Successfully created ${created.length} contract pair(s)\n`, 'cyan');
  log('Next steps:', 'yellow');
  log('  1. Review each CONTRACT.md and customize as needed');
  log('  2. Remove the "<!-- DRAFT -->" comment when ready');
  log('  3. Ask your AI assistant to help implement the features');
  
  return created;
}

async function updateRegistry(root, drafts) {
  const registryDir = path.join(root, '.contracts');
  const registryPath = path.join(registryDir, 'registry.yaml');
  
  let registry = {
    project: {
      name: path.basename(root),
      initialized: new Date().toISOString(),
      initialized_by: 'contracts-skill v2.0 (AI-assisted)'
    },
    contracts: []
  };
  
  // Load existing registry if present
  if (fs.existsSync(registryPath)) {
    try {
      const existing = fs.readFileSync(registryPath, 'utf8');
      // Simple YAML parsing for our structure
      const nameMatch = existing.match(/name:\s*["']([^"']+)["']/);
      if (nameMatch) registry.project.name = nameMatch[1];
      
      // Parse existing contracts
      const contractMatches = existing.matchAll(/-\s*path:\s*["']([^"']+)["']/g);
      for (const match of contractMatches) {
        registry.contracts.push({ path: match[1] });
      }
    } catch {
      // Ignore parsing errors
    }
  }
  
  // Add new contracts
  for (const draft of drafts) {
    const contractPath = draft.module.path.replace(/\\/g, '/');
    
    // Check if already in registry
    const exists = registry.contracts.some(c => c.path === contractPath);
    if (!exists) {
      registry.contracts.push({
        path: contractPath,
        name: draft.module.name,
        tier: draft.module.tier,
        type: draft.module.type,
        summary: draft.module.reasoning
      });
    }
  }
  
  // Create registry directory
  if (!fs.existsSync(registryDir)) {
    fs.mkdirSync(registryDir, { recursive: true });
  }
  
  // Generate registry YAML
  const contractsYaml = registry.contracts.map(c => {
    return `  - path: "${c.path}"
    name: "${c.name || path.basename(c.path)}"
    tier: ${c.tier || 'standard'}
    type: ${c.type || 'feature'}
    summary: "${c.summary || ''}"`;
  }).join('\n');
  
  const registryContent = `# .contracts/registry.yaml
# Central registry of all contracts in this project
# Generated by contracts-skill (AI-assisted)

project:
  name: "${registry.project.name}"
  initialized: "${registry.project.initialized}"
  initialized_by: "${registry.project.initialized_by}"

contracts:
${contractsYaml}
`;
  
  fs.writeFileSync(registryPath, registryContent, 'utf8');
  log(`✅ Updated: ${path.relative(root, registryPath)}`, 'green');
}

async function singleModuleMode(root, modulePath) {
  const fullPath = path.resolve(root, modulePath);
  
  if (!fs.existsSync(fullPath)) {
    log(`Error: Path does not exist: ${modulePath}`, 'red');
    process.exit(1);
  }
  
  const dirName = path.basename(fullPath);
  const relPath = path.relative(root, fullPath);
  
  // Analyze this specific module
  const { analyzePotentialModule } = require('./analyzer');
  const analysis = analyzeProject(root);
  
  // Find or create module info
  let moduleInfo = analysis.modules.find(m => m.path === relPath);
  
  if (!moduleInfo) {
    // Create basic info for this path
    moduleInfo = analyzePotentialModule(fullPath, relPath, analysis.project.type);
  }
  
  if (!moduleInfo) {
    moduleInfo = {
      name: dirName,
      path: relPath,
      type: 'feature',
      tier: 'standard',
      metrics: { fileCount: 0, lineCount: 0 },
      exports: [],
      hasEntryPoint: false,
      hasTests: false
    };
  }
  
  // Generate contract
  const draft = generateContractDraft(moduleInfo, analysis.project);
  const hash = sha256(draft.markdown);
  const yaml = makeYaml(moduleInfo.name, moduleInfo.type, relPath, hash, moduleInfo.exports);
  
  const mdPath = path.join(fullPath, 'CONTRACT.md');
  const yamlPath = path.join(fullPath, 'CONTRACT.yaml');
  
  // Check existing
  if (fs.existsSync(mdPath)) {
    log(`⚠️  CONTRACT.md already exists at ${relPath}`, 'yellow');
    log('Use --force to overwrite', 'gray');
    return;
  }
  
  // Write files
  fs.writeFileSync(mdPath, draft.markdown, 'utf8');
  fs.writeFileSync(yamlPath, yaml, 'utf8');
  
  log(`✅ Created contract for ${dirName}`, 'green');
  log(`   ${path.relative(root, mdPath)}`);
  log(`   ${path.relative(root, yamlPath)}`);
}

function showHelp() {
  log('AI-Assisted Contract Initialization Agent', 'cyan');
  log('==========================================\n');
  log('Usage: node index.js [options]\n');
  log('Options:');
  log('  --path <dir>     Project root directory (default: .)');
  log('  --analyze        Analyze project and show recommendations (default mode)');
  log('  --recommend      Generate contract drafts for recommended modules');
  log('  --dry-run        Show what would be created without writing files');
  log('  --apply          Write contract files to disk (requires --yes)');
  log('  --module <path>  Create contract for specific module path');
  log('  --force          Overwrite existing contracts');
  log('  --yes            Skip confirmation prompts');
  log('  --help           Show this help message');
  log('');
  log('Examples:');
  log('  node index.js --path . --analyze');
  log('  node index.js --path . --recommend');
  log('  node index.js --path . --dry-run');
  log('  node index.js --path . --apply --yes');
  log('  node index.js --module ./src/auth --yes');
}

async function main() {
  const args = process.argv.slice(2);
  
  // Parse arguments
  const options = {
    path: '.',
    analyze: args.includes('--analyze'),
    recommend: args.includes('--recommend'),
    dryRun: args.includes('--dry-run'),
    apply: args.includes('--apply'),
    module: null,
    force: args.includes('--force'),
    yes: args.includes('--yes'),
    help: args.includes('--help') || args.includes('-h')
  };
  
  // Get path value
  const pathIndex = args.indexOf('--path');
  if (pathIndex !== -1 && args[pathIndex + 1]) {
    options.path = args[pathIndex + 1];
  }
  
  // Get module value
  const moduleIndex = args.indexOf('--module');
  if (moduleIndex !== -1 && args[moduleIndex + 1]) {
    options.module = args[moduleIndex + 1];
  }
  
  // Show help
  if (options.help) {
    showHelp();
    return;
  }
  
  // Validate path
  const root = path.resolve(options.path);
  if (!fs.existsSync(root)) {
    log(`Error: Path does not exist: ${options.path}`, 'red');
    process.exit(1);
  }
  
  // Route to appropriate mode
  if (options.module) {
    await singleModuleMode(root, options.module);
  } else if (options.apply) {
    await applyMode(root, options);
  } else if (options.dryRun) {
    await dryRunMode(root);
  } else if (options.recommend) {
    await recommendMode(root);
  } else {
    // Default: analyze mode
    await analyzeMode(root);
  }
}

if (require.main === module) {
  main().catch(err => {
    log(`Error: ${err.message}`, 'red');
    process.exit(1);
  });
}

module.exports = {
  analyzeMode,
  recommendMode,
  dryRunMode,
  applyMode,
  singleModuleMode
};
