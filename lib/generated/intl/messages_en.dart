// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static m0(updateInfoLatest) => "A new version of Sidekick is available (${updateInfoLatest}).";

  static m1(itemVersionName) => "Channel ${itemVersionName} has been upgraded.";

  static m2(url) => "Could not launch ${url}";

  static m3(count) => "${count} Found";

  static m4(cachedVersions) => "${cachedVersions} versions";

  static m5(packageProjectsCount) => "${packageProjectsCount} projects";

  static m6(projects) => "${projects} Projects";

  static m7(releases) => "${releases} versions";

  static m8(updateInfoLatest) => "Sidekick version ${updateInfoLatest} is now available.";

  static m9(itemname) => "This will remove ${itemname} cache from your system.";

  static m10(itemVersionName) => "Version ${itemVersionName} has been installed.";

  static m11(itemVersionName) => "Version ${itemVersionName} has been removed.";

  static m12(itemVersionName) => "Version ${itemVersionName} has been set as global.";

  static m13(itemVersionName) => "Version ${itemVersionName} has finished setup.";

  static m14(version, projectName) => "Version ${version} pinned to ${projectName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "aNewVersionOfSidekickIsAvailableUpdateinfolatest" : m0,
    "addProject" : MessageLookupByLibrary.simpleMessage("Add Project"),
    "addYourFlutterProjectProjectsInformationWillBeDisplayedHere" : MessageLookupByLibrary.simpleMessage("Add your Flutter project Projects information will be displayed here."),
    "advanced" : MessageLookupByLibrary.simpleMessage("Advanced"),
    "analyticsCrashReportSubtitle" : MessageLookupByLibrary.simpleMessage("When a flutter command crashes it attempts to send a crash report to Google in order to help Google contribute improvements to Flutter over time"),
    "analyticsCrashReporting" : MessageLookupByLibrary.simpleMessage("Analytics & Crash Reporting"),
    "appSettingsHaveBeenReset" : MessageLookupByLibrary.simpleMessage("App settings have been reset"),
    "areYouSureYouWantToRemove" : MessageLookupByLibrary.simpleMessage("Are you sure you want to remove?"),
    "areYouSureYouWantToResetSettings" : MessageLookupByLibrary.simpleMessage("Are you sure you want to reset settings?"),
    "betaChannelDescription" : MessageLookupByLibrary.simpleMessage("Branch created from master for a new beta release at the beginning of the month, usually the first Monday. This will include a branch for Dart, the Engine and the Framework."),
    "betaReleases" : MessageLookupByLibrary.simpleMessage("Beta Releases"),
    "cacheLocation" : MessageLookupByLibrary.simpleMessage("Cache Location"),
    "cancel" : MessageLookupByLibrary.simpleMessage("Cancel"),
    "changeThePathTo" : MessageLookupByLibrary.simpleMessage("Change the path to\n"),
    "changelog" : MessageLookupByLibrary.simpleMessage("Changelog"),
    "channel" : MessageLookupByLibrary.simpleMessage("Channel"),
    "channelItemversionnameHasBeenUpgraded" : m1,
    "channels" : MessageLookupByLibrary.simpleMessage("Channels"),
    "choose" : MessageLookupByLibrary.simpleMessage("Choose"),
    "cleanUp" : MessageLookupByLibrary.simpleMessage("Clean up"),
    "cleanUpTooltip" : MessageLookupByLibrary.simpleMessage("Clean up unused versions."),
    "cleanUpUnusedVersions" : MessageLookupByLibrary.simpleMessage("Clean up unused versions"),
    "clickHereToDownload" : MessageLookupByLibrary.simpleMessage("Click here to download."),
    "confirm" : MessageLookupByLibrary.simpleMessage("Confirm"),
    "copiedToClipboard" : MessageLookupByLibrary.simpleMessage("Copied to clipboard"),
    "couldNotLaunchUrl" : m2,
    "couldNotSaveSettings" : MessageLookupByLibrary.simpleMessage("Could not save settings"),
    "countFound" : m3,
    "createdDate" : MessageLookupByLibrary.simpleMessage("Created Date"),
    "dark" : MessageLookupByLibrary.simpleMessage("Dark"),
    "dependenciesAfterANewVersionIsInstalled" : MessageLookupByLibrary.simpleMessage("dependencies after a new version is installed."),
    "details" : MessageLookupByLibrary.simpleMessage("Details"),
    "devChannelDescription" : MessageLookupByLibrary.simpleMessage("The latest fully-tested build. Usually functional, but see Bad Builds for a list of known \"bad\" dev builds."),
    "devReleases" : MessageLookupByLibrary.simpleMessage("Dev Releases"),
    "doYouWantToRemoveThemToFreeUpSpace" : MessageLookupByLibrary.simpleMessage("Do you want to remove them to free up space?"),
    "downloadZip" : MessageLookupByLibrary.simpleMessage("Download Zip"),
    "exploreFlutterReleases" : MessageLookupByLibrary.simpleMessage("Explore Flutter Releases"),
    "flutterPathIsPointingTon" : MessageLookupByLibrary.simpleMessage("Flutter PATH is pointing to\n "),
    "flutterSDKGlobalDescription" : MessageLookupByLibrary.simpleMessage("A Flutter sdk version neeeds to be set as global in order to access Flutter settings"),
    "flutterSdkNotInstalled" : MessageLookupByLibrary.simpleMessage("Flutter SDK not installed."),
    "fvmOnly" : MessageLookupByLibrary.simpleMessage("FVM Only"),
    "general" : MessageLookupByLibrary.simpleMessage("General"),
    "global" : MessageLookupByLibrary.simpleMessage("Global"),
    "globalConfiguration" : MessageLookupByLibrary.simpleMessage("Global configuration"),
    "hash" : MessageLookupByLibrary.simpleMessage("Hash"),
    "howToUpdateYourPath" : MessageLookupByLibrary.simpleMessage("How to update your path?"),
    "ifYouWantToFlutterSdkThroughFvm" : MessageLookupByLibrary.simpleMessage("if you want to Flutter SDK through FVM"),
    "inUse" : MessageLookupByLibrary.simpleMessage("In use"),
    "installedVersions" : MessageLookupByLibrary.simpleMessage("Installed Versions"),
    "invalidChanel" : MessageLookupByLibrary.simpleMessage("Invalid chanel"),
    "language" : MessageLookupByLibrary.simpleMessage("Language"),
    "later" : MessageLookupByLibrary.simpleMessage("Later"),
    "light" : MessageLookupByLibrary.simpleMessage("Light"),
    "likes" : MessageLookupByLibrary.simpleMessage("Likes"),
    "localCacheInformation" : MessageLookupByLibrary.simpleMessage("Local Cache Information"),
    "master" : MessageLookupByLibrary.simpleMessage("Master"),
    "masterChannelDescription" : MessageLookupByLibrary.simpleMessage("The current tip-of-tree, absolute latest cutting edge build. Usually functional, though sometimes we accidentally break things."),
    "mostUsedPackages" : MessageLookupByLibrary.simpleMessage("Most Used Packages"),
    "navButtonDashboard" : MessageLookupByLibrary.simpleMessage("Dashboard"),
    "navButtonExplore" : MessageLookupByLibrary.simpleMessage("Explore"),
    "navButtonPackages" : MessageLookupByLibrary.simpleMessage("Packages"),
    "navButtonProjects" : MessageLookupByLibrary.simpleMessage("Projects"),
    "noFlutterProjectsHaveBeenAddedYet" : MessageLookupByLibrary.simpleMessage("No Flutter Projects have been added yet."),
    "noFlutterVersionInstalledMessage" : MessageLookupByLibrary.simpleMessage("You do not currently have any Flutter SDK versions installed. Versions or channels that have been installed will be displayed here."),
    "noPackagesFound" : MessageLookupByLibrary.simpleMessage("No Packages Found"),
    "noResults" : MessageLookupByLibrary.simpleMessage("No Results"),
    "noUnusedFlutterSdkVersionsInstalled" : MessageLookupByLibrary.simpleMessage("No unused Flutter SDK versions installed"),
    "notAFlutterProject" : MessageLookupByLibrary.simpleMessage("Not a Flutter project"),
    "notRunning" : MessageLookupByLibrary.simpleMessage("Not running"),
    "nothingSelected" : MessageLookupByLibrary.simpleMessage("Nothing selected"),
    "numberOfCachedVersions" : m4,
    "ok" : MessageLookupByLibrary.simpleMessage("OK"),
    "onlyDisplayProjectsThatHaveVersionsPinned" : MessageLookupByLibrary.simpleMessage("Only display projects that have versions pinned"),
    "open" : MessageLookupByLibrary.simpleMessage("open"),
    "openTerminalPlayground" : MessageLookupByLibrary.simpleMessage("Open terminal playground"),
    "packageprojectscountProjects" : m5,
    "platforms" : MessageLookupByLibrary.simpleMessage("Platforms"),
    "playground" : MessageLookupByLibrary.simpleMessage("Playground"),
    "popularity" : MessageLookupByLibrary.simpleMessage("Popularity"),
    "projects" : MessageLookupByLibrary.simpleMessage("Projects"),
    "projectsProjects" : m6,
    "projectsRefreshed" : MessageLookupByLibrary.simpleMessage("Projects Refreshed"),
    "pubPoints" : MessageLookupByLibrary.simpleMessage("Pub Points"),
    "refresh" : MessageLookupByLibrary.simpleMessage("Refresh"),
    "releaseDate" : MessageLookupByLibrary.simpleMessage("Release Date"),
    "releaseNotes" : MessageLookupByLibrary.simpleMessage("Release Notes"),
    "releases" : MessageLookupByLibrary.simpleMessage("Releases"),
    "releasesVersions" : m7,
    "remove" : MessageLookupByLibrary.simpleMessage("Remove"),
    "reset" : MessageLookupByLibrary.simpleMessage("Reset"),
    "resetToDefaultSettings" : MessageLookupByLibrary.simpleMessage("Reset to default settings"),
    "sdkHasNotFinishedSetup" : MessageLookupByLibrary.simpleMessage("SDK has not finished setup"),
    "search" : MessageLookupByLibrary.simpleMessage("Search... "),
    "selectAFlutterSdkVersion" : MessageLookupByLibrary.simpleMessage("Select a Flutter SDK Version"),
    "selectAThemeOrSwitchAccordingToSystemSettings" : MessageLookupByLibrary.simpleMessage("Select a theme or switch according to system settings.."),
    "setAsGlobal" : MessageLookupByLibrary.simpleMessage("Set as global"),
    "settingsHaveBeenSaved" : MessageLookupByLibrary.simpleMessage("Settings have been saved"),
    "sha256" : MessageLookupByLibrary.simpleMessage("Sha256"),
    "sidekickVersionUpdateinfolatestIsNowAvailable" : m8,
    "skipSetupFlutterOnInstall" : MessageLookupByLibrary.simpleMessage("Skip setup Flutter on install"),
    "stableChannelDescription" : MessageLookupByLibrary.simpleMessage("We recommend that you use this channel for all production app releases. Roughly once a quarter, a branch that has been stabilized on beta will become our next stable branch and we will create a stable release from that branch."),
    "stableReleases" : MessageLookupByLibrary.simpleMessage("Stable Releases"),
    "start" : MessageLookupByLibrary.simpleMessage("start"),
    "system" : MessageLookupByLibrary.simpleMessage("System"),
    "theCurrentTipoftreeAbsoluteLatestCuttingEdgeBuildUsuallyFunctional" : MessageLookupByLibrary.simpleMessage("The current tip-of-tree, absolute latest cutting edge build. Usually functional, though sometimes we accidentally break things."),
    "theme" : MessageLookupByLibrary.simpleMessage("Theme"),
    "thereWasAnIssueLoadingYourPackages" : MessageLookupByLibrary.simpleMessage("There was an issue loading your packages."),
    "theseVersionAreNotPinnedToAProject" : MessageLookupByLibrary.simpleMessage("These version are not pinned to a project "),
    "thisWillOnlyCloneFlutterAndNotInstall" : MessageLookupByLibrary.simpleMessage("This will only clone Flutter and not install"),
    "thisWillOnlyResetSidekickSpecificPreferences" : MessageLookupByLibrary.simpleMessage("This will only reset Sidekick specific preferences"),
    "thisWillRemoveItemnameCacheFromYourSystem" : m9,
    "unused" : MessageLookupByLibrary.simpleMessage("Unused"),
    "updateAvailable" : MessageLookupByLibrary.simpleMessage("Update available."),
    "updateNow" : MessageLookupByLibrary.simpleMessage("Update Now"),
    "upgrade" : MessageLookupByLibrary.simpleMessage("Upgrade"),
    "version" : MessageLookupByLibrary.simpleMessage("Version"),
    "versionIsInstalled" : MessageLookupByLibrary.simpleMessage("Version is installed"),
    "versionItemversionnameHasBeenInstalled" : m10,
    "versionItemversionnameHasBeenRemoved" : m11,
    "versionItemversionnameHasBeenSetAsGlobal" : m12,
    "versionItemversionnameHasFinishedSetup" : m13,
    "versionNotInstalledClickToInstall" : MessageLookupByLibrary.simpleMessage("Version not installed. Click to install."),
    "versionVersionPinnedToProjectname" : m14,
    "versions" : MessageLookupByLibrary.simpleMessage("Versions"),
    "web" : MessageLookupByLibrary.simpleMessage("Web"),
    "website" : MessageLookupByLibrary.simpleMessage("Website"),
    "youNeedToAddAFlutterProjectFirstPackageInformation" : MessageLookupByLibrary.simpleMessage("You need to add a Flutter project first. Package information will be displayed here."),
    "zipFileWithAllReleaseDependencies" : MessageLookupByLibrary.simpleMessage("Zip file with all release dependencies.")
  };
}
