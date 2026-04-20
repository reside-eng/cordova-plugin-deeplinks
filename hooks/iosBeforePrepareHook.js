/*
Hook executed before the 'prepare' stage. Only for iOS project.
It will check if project name has changed. If so - it will change the name of the .entitlements file to remove that file duplicates.
If file name has no changed - hook will do nothing.
*/

var path = require('path');
var fs = require('fs');
var ConfigXmlHelper = require('./lib/configXmlHelper.js');

module.exports = function(ctx) {
  run(ctx);
};

/**
 * Run the hook logic.
 *
 * @param {Object} ctx - cordova context object
 */
function run(ctx) {
  var projectRoot = ctx.opts.projectRoot;
  var iosProjectFilePath = path.join(projectRoot, 'platforms', 'ios');

  // cordova-ios 8+ ships its own App/Entitlements-Debug.plist and
  // App/Entitlements-Release.plist — there is no {ProjectName}.entitlements
  // file to rename. Skip in that layout; associated-domains are written by
  // afterPrepareHook.js into the correct plists.
  if (isCordovaIos8OrNewer(iosProjectFilePath)) {
    return;
  }

  var configXmlHelper = new ConfigXmlHelper(ctx);
  var newProjectName = configXmlHelper.getProjectName();

  var oldProjectName = getOldProjectName(iosProjectFilePath);

  // if name has not changed - do nothing
  if (oldProjectName.length && oldProjectName === newProjectName) {
    return;
  }

  console.log('Project name has changed. Renaming .entitlements file.');

  // if it does - rename it
  var oldEntitlementsFilePath = path.join(iosProjectFilePath, oldProjectName, 'Resources', oldProjectName + '.entitlements');
  var newEntitlementsFilePath = path.join(iosProjectFilePath, oldProjectName, 'Resources', newProjectName + '.entitlements');

  try {
    fs.renameSync(oldEntitlementsFilePath, newEntitlementsFilePath);
  } catch (err) {
    console.warn('Failed to rename .entitlements file.');
    console.warn(err);
  }
}

// region Private API

/**
 * Detect cordova-ios 8+ project layout.
 *
 * @param {String} iosProjectFilePath absolute path to platforms/ios
 * @return {Boolean} true if project uses cordova-ios 8+ entitlements layout
 */
function isCordovaIos8OrNewer(iosProjectFilePath) {
  return fs.existsSync(path.join(iosProjectFilePath, 'App', 'Entitlements-Debug.plist'))
      || fs.existsSync(path.join(iosProjectFilePath, 'App', 'Entitlements-Release.plist'));
}

/**
 * Get old name of the project.
 * Name is detected by the name of the .xcodeproj file.
 *
 * @param {String} projectDir absolute path to ios project directory
 * @return {String} old project name
 */
function getOldProjectName(projectDir) {
  var files = [];
  try {
    files = fs.readdirSync(projectDir);
  } catch (err) {
    return '';
  }

  var projectFile = '';
  files.forEach(function(fileName) {
    if (path.extname(fileName) === '.xcodeproj') {
      projectFile = path.basename(fileName, '.xcodeproj');
    }
  });

  return projectFile;
}

// endregion
