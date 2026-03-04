/**
 * CJS preload script — patches Module._resolveFilename BEFORE
 * tsx processes any .ts imports. Run via: tsx --require ./scripts/register-mocks.cjs
 */

const Module = require('module');
const path = require('path');

const mocksDir = path.join(__dirname, 'mocks');
const originalResolve = Module._resolveFilename;

Module._resolveFilename = function (request, parent) {
  const rest = Array.prototype.slice.call(arguments, 2);

  // Mock firebase-admin
  if (request === 'firebase-admin') {
    return originalResolve.apply(
      this,
      [path.join(mocksDir, 'firebase-admin.ts'), parent].concat(rest)
    );
  }

  // Mock rateLimiter (matches '../utils/rateLimiter', etc.)
  if (request.includes('rateLimiter') && !request.includes('mocks')) {
    return originalResolve.apply(
      this,
      [path.join(mocksDir, 'rateLimiter.ts'), parent].concat(rest)
    );
  }

  // Mock recipeStorage
  if (request.includes('recipeStorage') && !request.includes('mocks')) {
    return originalResolve.apply(
      this,
      [path.join(mocksDir, 'recipeStorage.ts'), parent].concat(rest)
    );
  }

  // Mock imageMatch (imported by real recipeStorage source)
  if (request.includes('imageMatch') && !request.includes('mocks')) {
    return originalResolve.apply(
      this,
      [path.join(mocksDir, 'recipeStorage.ts'), parent].concat(rest)
    );
  }

  return originalResolve.apply(this, arguments);
};
