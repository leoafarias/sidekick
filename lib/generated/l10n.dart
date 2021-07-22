// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values

class S {
  S();
  
  static S current;
  
  static const AppLocalizationDelegate delegate =
    AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name); 
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      S.current = S();
      
      return S.current;
    });
  } 

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Dashboard`
  String get navButtonDashboard {
    return Intl.message(
      'Dashboard',
      name: 'navButtonDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Projects`
  String get navButtonProjects {
    return Intl.message(
      'Projects',
      name: 'navButtonProjects',
      desc: '',
      args: [],
    );
  }

  /// `Explore`
  String get navButtonExplore {
    return Intl.message(
      'Explore',
      name: 'navButtonExplore',
      desc: '',
      args: [],
    );
  }

  /// `Packages`
  String get navButtonPackages {
    return Intl.message(
      'Packages',
      name: 'navButtonPackages',
      desc: '',
      args: [],
    );
  }

  /// `Installed Versions`
  String get installedVersions {
    return Intl.message(
      'Installed Versions',
      name: 'installedVersions',
      desc: '',
      args: [],
    );
  }

  /// `Clean up`
  String get cleanUp {
    return Intl.message(
      'Clean up',
      name: 'cleanUp',
      desc: '',
      args: [],
    );
  }

  /// `Clean up unused versions.`
  String get cleanUpTooltip {
    return Intl.message(
      'Clean up unused versions.',
      name: 'cleanUpTooltip',
      desc: '',
      args: [],
    );
  }

  /// `{cachedVersions} versions`
  String numberOfCachedVersions(Object cachedVersions) {
    return Intl.message(
      '$cachedVersions versions',
      name: 'numberOfCachedVersions',
      desc: '',
      args: [cachedVersions],
    );
  }

  /// `Flutter SDK not installed.`
  String get flutterSdkNotInstalled {
    return Intl.message(
      'Flutter SDK not installed.',
      name: 'flutterSdkNotInstalled',
      desc: '',
      args: [],
    );
  }

  /// `You do not currently have any Flutter SDK versions installed. Versions or channels that have been installed will be displayed here.`
  String get noFlutterVersionInstalledMessage {
    return Intl.message(
      'You do not currently have any Flutter SDK versions installed. Versions or channels that have been installed will be displayed here.',
      name: 'noFlutterVersionInstalledMessage',
      desc: '',
      args: [],
    );
  }

  /// `Explore Flutter Releases`
  String get exploreFlutterReleases {
    return Intl.message(
      'Explore Flutter Releases',
      name: 'exploreFlutterReleases',
      desc: '',
      args: [],
    );
  }

  /// `Advanced`
  String get advanced {
    return Intl.message(
      'Advanced',
      name: 'advanced',
      desc: '',
      args: [],
    );
  }

  /// `Download Zip`
  String get downloadZip {
    return Intl.message(
      'Download Zip',
      name: 'downloadZip',
      desc: '',
      args: [],
    );
  }

  /// `Zip file with all release dependencies.`
  String get zipFileWithAllReleaseDependencies {
    return Intl.message(
      'Zip file with all release dependencies.',
      name: 'zipFileWithAllReleaseDependencies',
      desc: '',
      args: [],
    );
  }

  /// `Hash`
  String get hash {
    return Intl.message(
      'Hash',
      name: 'hash',
      desc: '',
      args: [],
    );
  }

  /// `Sha256`
  String get sha256 {
    return Intl.message(
      'Sha256',
      name: 'sha256',
      desc: '',
      args: [],
    );
  }

  /// `Local Cache Information`
  String get localCacheInformation {
    return Intl.message(
      'Local Cache Information',
      name: 'localCacheInformation',
      desc: '',
      args: [],
    );
  }

  /// `Created Date`
  String get createdDate {
    return Intl.message(
      'Created Date',
      name: 'createdDate',
      desc: '',
      args: [],
    );
  }

  /// `Cache Location`
  String get cacheLocation {
    return Intl.message(
      'Cache Location',
      name: 'cacheLocation',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to remove?`
  String get areYouSureYouWantToRemove {
    return Intl.message(
      'Are you sure you want to remove?',
      name: 'areYouSureYouWantToRemove',
      desc: '',
      args: [],
    );
  }

  /// `This will remove {itemname} cache from your system.`
  String thisWillRemoveItemnameCacheFromYourSystem(Object itemname) {
    return Intl.message(
      'This will remove $itemname cache from your system.',
      name: 'thisWillRemoveItemnameCacheFromYourSystem',
      desc: '',
      args: [itemname],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get confirm {
    return Intl.message(
      'Confirm',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `Master`
  String get master {
    return Intl.message(
      'Master',
      name: 'master',
      desc: '',
      args: [],
    );
  }

  /// `Channel`
  String get channel {
    return Intl.message(
      'Channel',
      name: 'channel',
      desc: '',
      args: [],
    );
  }

  /// `Release Notes`
  String get releaseNotes {
    return Intl.message(
      'Release Notes',
      name: 'releaseNotes',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get version {
    return Intl.message(
      'Version',
      name: 'version',
      desc: '',
      args: [],
    );
  }

  /// `Release Date`
  String get releaseDate {
    return Intl.message(
      'Release Date',
      name: 'releaseDate',
      desc: '',
      args: [],
    );
  }

  /// `SDK has not finished setup`
  String get sdkHasNotFinishedSetup {
    return Intl.message(
      'SDK has not finished setup',
      name: 'sdkHasNotFinishedSetup',
      desc: '',
      args: [],
    );
  }

  /// `Version is installed`
  String get versionIsInstalled {
    return Intl.message(
      'Version is installed',
      name: 'versionIsInstalled',
      desc: '',
      args: [],
    );
  }

  /// `Version not installed. Click to install.`
  String get versionNotInstalledClickToInstall {
    return Intl.message(
      'Version not installed. Click to install.',
      name: 'versionNotInstalledClickToInstall',
      desc: '',
      args: [],
    );
  }

  /// `No unused Flutter SDK versions installed`
  String get noUnusedFlutterSdkVersionsInstalled {
    return Intl.message(
      'No unused Flutter SDK versions installed',
      name: 'noUnusedFlutterSdkVersionsInstalled',
      desc: '',
      args: [],
    );
  }

  /// `Clean up unused versions`
  String get cleanUpUnusedVersions {
    return Intl.message(
      'Clean up unused versions',
      name: 'cleanUpUnusedVersions',
      desc: '',
      args: [],
    );
  }

  /// `These version are not pinned to a project `
  String get theseVersionAreNotPinnedToAProject {
    return Intl.message(
      'These version are not pinned to a project ',
      name: 'theseVersionAreNotPinnedToAProject',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to remove them to free up space?`
  String get doYouWantToRemoveThemToFreeUpSpace {
    return Intl.message(
      'Do you want to remove them to free up space?',
      name: 'doYouWantToRemoveThemToFreeUpSpace',
      desc: '',
      args: [],
    );
  }

  /// `Global configuration`
  String get globalConfiguration {
    return Intl.message(
      'Global configuration',
      name: 'globalConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get ok {
    return Intl.message(
      'OK',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `Flutter PATH is pointing to\n `
  String get flutterPathIsPointingTon {
    return Intl.message(
      'Flutter PATH is pointing to\n ',
      name: 'flutterPathIsPointingTon',
      desc: '',
      args: [],
    );
  }

  /// `Change the path to\n`
  String get changeThePathTo {
    return Intl.message(
      'Change the path to\n',
      name: 'changeThePathTo',
      desc: '',
      args: [],
    );
  }

  /// `if you want to Flutter SDK through FVM`
  String get ifYouWantToFlutterSdkThroughFvm {
    return Intl.message(
      'if you want to Flutter SDK through FVM',
      name: 'ifYouWantToFlutterSdkThroughFvm',
      desc: '',
      args: [],
    );
  }

  /// `How to update your path?`
  String get howToUpdateYourPath {
    return Intl.message(
      'How to update your path?',
      name: 'howToUpdateYourPath',
      desc: '',
      args: [],
    );
  }

  /// `Nothing selected`
  String get nothingSelected {
    return Intl.message(
      'Nothing selected',
      name: 'nothingSelected',
      desc: '',
      args: [],
    );
  }

  /// `Copied to clipboard`
  String get copiedToClipboard {
    return Intl.message(
      'Copied to clipboard',
      name: 'copiedToClipboard',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get refresh {
    return Intl.message(
      'Refresh',
      name: 'refresh',
      desc: '',
      args: [],
    );
  }

  /// `{count} Found`
  String countFound(Object count) {
    return Intl.message(
      '$count Found',
      name: 'countFound',
      desc: '',
      args: [count],
    );
  }

  /// `Could not launch {url}`
  String couldNotLaunchUrl(Object url) {
    return Intl.message(
      'Could not launch $url',
      name: 'couldNotLaunchUrl',
      desc: '',
      args: [url],
    );
  }

  /// `start`
  String get start {
    return Intl.message(
      'start',
      name: 'start',
      desc: '',
      args: [],
    );
  }

  /// `open`
  String get open {
    return Intl.message(
      'open',
      name: 'open',
      desc: '',
      args: [],
    );
  }

  /// `We recommend that you use this channel for all production app releases. Roughly once a quarter, a branch that has been stabilized on beta will become our next stable branch and we will create a stable release from that branch.`
  String get stableChannelDescription {
    return Intl.message(
      'We recommend that you use this channel for all production app releases. Roughly once a quarter, a branch that has been stabilized on beta will become our next stable branch and we will create a stable release from that branch.',
      name: 'stableChannelDescription',
      desc: '',
      args: [],
    );
  }

  /// `Branch created from master for a new beta release at the beginning of the month, usually the first Monday. This will include a branch for Dart, the Engine and the Framework.`
  String get betaChannelDescription {
    return Intl.message(
      'Branch created from master for a new beta release at the beginning of the month, usually the first Monday. This will include a branch for Dart, the Engine and the Framework.',
      name: 'betaChannelDescription',
      desc: '',
      args: [],
    );
  }

  /// `The latest fully-tested build. Usually functional, but see Bad Builds for a list of known "bad" dev builds.`
  String get devChannelDescription {
    return Intl.message(
      'The latest fully-tested build. Usually functional, but see Bad Builds for a list of known "bad" dev builds.',
      name: 'devChannelDescription',
      desc: '',
      args: [],
    );
  }

  /// `The current tip-of-tree, absolute latest cutting edge build. Usually functional, though sometimes we accidentally break things.`
  String get masterChannelDescription {
    return Intl.message(
      'The current tip-of-tree, absolute latest cutting edge build. Usually functional, though sometimes we accidentally break things.',
      name: 'masterChannelDescription',
      desc: '',
      args: [],
    );
  }

  /// `In use`
  String get inUse {
    return Intl.message(
      'In use',
      name: 'inUse',
      desc: '',
      args: [],
    );
  }

  /// `Unused`
  String get unused {
    return Intl.message(
      'Unused',
      name: 'unused',
      desc: '',
      args: [],
    );
  }

  /// `Set as global`
  String get setAsGlobal {
    return Intl.message(
      'Set as global',
      name: 'setAsGlobal',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get details {
    return Intl.message(
      'Details',
      name: 'details',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get remove {
    return Intl.message(
      'Remove',
      name: 'remove',
      desc: '',
      args: [],
    );
  }

  /// `Upgrade`
  String get upgrade {
    return Intl.message(
      'Upgrade',
      name: 'upgrade',
      desc: '',
      args: [],
    );
  }

  /// `Global`
  String get global {
    return Intl.message(
      'Global',
      name: 'global',
      desc: '',
      args: [],
    );
  }

  /// `Version {itemVersionName} has been installed.`
  String versionItemversionnameHasBeenInstalled(Object itemVersionName) {
    return Intl.message(
      'Version $itemVersionName has been installed.',
      name: 'versionItemversionnameHasBeenInstalled',
      desc: '',
      args: [itemVersionName],
    );
  }

  /// `Version {itemVersionName} has finished setup.`
  String versionItemversionnameHasFinishedSetup(Object itemVersionName) {
    return Intl.message(
      'Version $itemVersionName has finished setup.',
      name: 'versionItemversionnameHasFinishedSetup',
      desc: '',
      args: [itemVersionName],
    );
  }

  /// `Channel {itemVersionName} has been upgraded.`
  String channelItemversionnameHasBeenUpgraded(Object itemVersionName) {
    return Intl.message(
      'Channel $itemVersionName has been upgraded.',
      name: 'channelItemversionnameHasBeenUpgraded',
      desc: '',
      args: [itemVersionName],
    );
  }

  /// `Version {itemVersionName} has been removed.`
  String versionItemversionnameHasBeenRemoved(Object itemVersionName) {
    return Intl.message(
      'Version $itemVersionName has been removed.',
      name: 'versionItemversionnameHasBeenRemoved',
      desc: '',
      args: [itemVersionName],
    );
  }

  /// `Version {itemVersionName} has been set as global.`
  String versionItemversionnameHasBeenSetAsGlobal(Object itemVersionName) {
    return Intl.message(
      'Version $itemVersionName has been set as global.',
      name: 'versionItemversionnameHasBeenSetAsGlobal',
      desc: '',
      args: [itemVersionName],
    );
  }

  /// `Version {version} pinned to {projectName}`
  String versionVersionPinnedToProjectname(Object version, Object projectName) {
    return Intl.message(
      'Version $version pinned to $projectName',
      name: 'versionVersionPinnedToProjectname',
      desc: '',
      args: [version, projectName],
    );
  }

  /// `{packageProjectsCount} projects`
  String packageprojectscountProjects(Object packageProjectsCount) {
    return Intl.message(
      '$packageProjectsCount projects',
      name: 'packageprojectscountProjects',
      desc: '',
      args: [packageProjectsCount],
    );
  }

  /// `Changelog`
  String get changelog {
    return Intl.message(
      'Changelog',
      name: 'changelog',
      desc: '',
      args: [],
    );
  }

  /// `Website`
  String get website {
    return Intl.message(
      'Website',
      name: 'website',
      desc: '',
      args: [],
    );
  }

  /// `Likes`
  String get likes {
    return Intl.message(
      'Likes',
      name: 'likes',
      desc: '',
      args: [],
    );
  }

  /// `Pub Points`
  String get pubPoints {
    return Intl.message(
      'Pub Points',
      name: 'pubPoints',
      desc: '',
      args: [],
    );
  }

  /// `Popularity`
  String get popularity {
    return Intl.message(
      'Popularity',
      name: 'popularity',
      desc: '',
      args: [],
    );
  }

  /// `No Packages Found`
  String get noPackagesFound {
    return Intl.message(
      'No Packages Found',
      name: 'noPackagesFound',
      desc: '',
      args: [],
    );
  }

  /// `Most Used Packages`
  String get mostUsedPackages {
    return Intl.message(
      'Most Used Packages',
      name: 'mostUsedPackages',
      desc: '',
      args: [],
    );
  }

  /// `There was an issue loading your packages.`
  String get thereWasAnIssueLoadingYourPackages {
    return Intl.message(
      'There was an issue loading your packages.',
      name: 'thereWasAnIssueLoadingYourPackages',
      desc: '',
      args: [],
    );
  }

  /// `Open terminal playground`
  String get openTerminalPlayground {
    return Intl.message(
      'Open terminal playground',
      name: 'openTerminalPlayground',
      desc: '',
      args: [],
    );
  }

  /// `Select a Flutter SDK Version`
  String get selectAFlutterSdkVersion {
    return Intl.message(
      'Select a Flutter SDK Version',
      name: 'selectAFlutterSdkVersion',
      desc: '',
      args: [],
    );
  }

  /// `Choose`
  String get choose {
    return Intl.message(
      'Choose',
      name: 'choose',
      desc: '',
      args: [],
    );
  }

  /// `No Flutter Projects have been added yet.`
  String get noFlutterProjectsHaveBeenAddedYet {
    return Intl.message(
      'No Flutter Projects have been added yet.',
      name: 'noFlutterProjectsHaveBeenAddedYet',
      desc: '',
      args: [],
    );
  }

  /// `Not a Flutter project`
  String get notAFlutterProject {
    return Intl.message(
      'Not a Flutter project',
      name: 'notAFlutterProject',
      desc: '',
      args: [],
    );
  }

  /// `Projects Refreshed`
  String get projectsRefreshed {
    return Intl.message(
      'Projects Refreshed',
      name: 'projectsRefreshed',
      desc: '',
      args: [],
    );
  }

  /// `Projects`
  String get projects {
    return Intl.message(
      'Projects',
      name: 'projects',
      desc: '',
      args: [],
    );
  }

  /// `{projects} Projects`
  String projectsProjects(Object projects) {
    return Intl.message(
      '$projects Projects',
      name: 'projectsProjects',
      desc: '',
      args: [projects],
    );
  }

  /// `Only display projects that have versions pinned`
  String get onlyDisplayProjectsThatHaveVersionsPinned {
    return Intl.message(
      'Only display projects that have versions pinned',
      name: 'onlyDisplayProjectsThatHaveVersionsPinned',
      desc: '',
      args: [],
    );
  }

  /// `FVM Only`
  String get fvmOnly {
    return Intl.message(
      'FVM Only',
      name: 'fvmOnly',
      desc: '',
      args: [],
    );
  }

  /// `Add Project`
  String get addProject {
    return Intl.message(
      'Add Project',
      name: 'addProject',
      desc: '',
      args: [],
    );
  }

  /// `Releases`
  String get releases {
    return Intl.message(
      'Releases',
      name: 'releases',
      desc: '',
      args: [],
    );
  }

  /// `Versions`
  String get versions {
    return Intl.message(
      'Versions',
      name: 'versions',
      desc: '',
      args: [],
    );
  }

  /// `Playground`
  String get playground {
    return Intl.message(
      'Playground',
      name: 'playground',
      desc: '',
      args: [],
    );
  }

  /// `{releases} versions`
  String releasesVersions(Object releases) {
    return Intl.message(
      '$releases versions',
      name: 'releasesVersions',
      desc: '',
      args: [releases],
    );
  }

  /// `Not running`
  String get notRunning {
    return Intl.message(
      'Not running',
      name: 'notRunning',
      desc: '',
      args: [],
    );
  }

  /// `Search... `
  String get search {
    return Intl.message(
      'Search... ',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `No Results`
  String get noResults {
    return Intl.message(
      'No Results',
      name: 'noResults',
      desc: '',
      args: [],
    );
  }

  /// `Channels`
  String get channels {
    return Intl.message(
      'Channels',
      name: 'channels',
      desc: '',
      args: [],
    );
  }

  /// `Stable Releases`
  String get stableReleases {
    return Intl.message(
      'Stable Releases',
      name: 'stableReleases',
      desc: '',
      args: [],
    );
  }

  /// `Beta Releases`
  String get betaReleases {
    return Intl.message(
      'Beta Releases',
      name: 'betaReleases',
      desc: '',
      args: [],
    );
  }

  /// `Dev Releases`
  String get devReleases {
    return Intl.message(
      'Dev Releases',
      name: 'devReleases',
      desc: '',
      args: [],
    );
  }

  /// `Invalid chanel`
  String get invalidChanel {
    return Intl.message(
      'Invalid chanel',
      name: 'invalidChanel',
      desc: '',
      args: [],
    );
  }

  /// `Analytics & Crash Reporting`
  String get analyticsCrashReporting {
    return Intl.message(
      'Analytics & Crash Reporting',
      name: 'analyticsCrashReporting',
      desc: '',
      args: [],
    );
  }

  /// `Platforms`
  String get platforms {
    return Intl.message(
      'Platforms',
      name: 'platforms',
      desc: '',
      args: [],
    );
  }

  /// `Web`
  String get web {
    return Intl.message(
      'Web',
      name: 'web',
      desc: '',
      args: [],
    );
  }

  /// `Skip setup Flutter on install`
  String get skipSetupFlutterOnInstall {
    return Intl.message(
      'Skip setup Flutter on install',
      name: 'skipSetupFlutterOnInstall',
      desc: '',
      args: [],
    );
  }

  /// `This will only clone Flutter and not install`
  String get thisWillOnlyCloneFlutterAndNotInstall {
    return Intl.message(
      'This will only clone Flutter and not install',
      name: 'thisWillOnlyCloneFlutterAndNotInstall',
      desc: '',
      args: [],
    );
  }

  /// `dependencies after a new version is installed.`
  String get dependenciesAfterANewVersionIsInstalled {
    return Intl.message(
      'dependencies after a new version is installed.',
      name: 'dependenciesAfterANewVersionIsInstalled',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to reset settings?`
  String get areYouSureYouWantToResetSettings {
    return Intl.message(
      'Are you sure you want to reset settings?',
      name: 'areYouSureYouWantToResetSettings',
      desc: '',
      args: [],
    );
  }

  /// `This will only reset Sidekick specific preferences`
  String get thisWillOnlyResetSidekickSpecificPreferences {
    return Intl.message(
      'This will only reset Sidekick specific preferences',
      name: 'thisWillOnlyResetSidekickSpecificPreferences',
      desc: '',
      args: [],
    );
  }

  /// `App settings have been reset`
  String get appSettingsHaveBeenReset {
    return Intl.message(
      'App settings have been reset',
      name: 'appSettingsHaveBeenReset',
      desc: '',
      args: [],
    );
  }

  /// `General`
  String get general {
    return Intl.message(
      'General',
      name: 'general',
      desc: '',
      args: [],
    );
  }

  /// `Select a theme or switch according to system settings..`
  String get selectAThemeOrSwitchAccordingToSystemSettings {
    return Intl.message(
      'Select a theme or switch according to system settings..',
      name: 'selectAThemeOrSwitchAccordingToSystemSettings',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get theme {
    return Intl.message(
      'Theme',
      name: 'theme',
      desc: '',
      args: [],
    );
  }

  /// `System`
  String get system {
    return Intl.message(
      'System',
      name: 'system',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get light {
    return Intl.message(
      'Light',
      name: 'light',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get dark {
    return Intl.message(
      'Dark',
      name: 'dark',
      desc: '',
      args: [],
    );
  }

  /// `Reset to default settings`
  String get resetToDefaultSettings {
    return Intl.message(
      'Reset to default settings',
      name: 'resetToDefaultSettings',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      desc: '',
      args: [],
    );
  }

  /// `Settings have been saved`
  String get settingsHaveBeenSaved {
    return Intl.message(
      'Settings have been saved',
      name: 'settingsHaveBeenSaved',
      desc: '',
      args: [],
    );
  }

  /// `Could not save settings`
  String get couldNotSaveSettings {
    return Intl.message(
      'Could not save settings',
      name: 'couldNotSaveSettings',
      desc: '',
      args: [],
    );
  }

  /// `Update available.`
  String get updateAvailable {
    return Intl.message(
      'Update available.',
      name: 'updateAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Sidekick version {updateInfoLatest} is now available.`
  String sidekickVersionUpdateinfolatestIsNowAvailable(Object updateInfoLatest) {
    return Intl.message(
      'Sidekick version $updateInfoLatest is now available.',
      name: 'sidekickVersionUpdateinfolatestIsNowAvailable',
      desc: '',
      args: [updateInfoLatest],
    );
  }

  /// `Later`
  String get later {
    return Intl.message(
      'Later',
      name: 'later',
      desc: '',
      args: [],
    );
  }

  /// `Update Now`
  String get updateNow {
    return Intl.message(
      'Update Now',
      name: 'updateNow',
      desc: '',
      args: [],
    );
  }

  /// `Click here to download.`
  String get clickHereToDownload {
    return Intl.message(
      'Click here to download.',
      name: 'clickHereToDownload',
      desc: '',
      args: [],
    );
  }

  /// `A new version of Sidekick is available ({updateInfoLatest}).`
  String aNewVersionOfSidekickIsAvailableUpdateinfolatest(Object updateInfoLatest) {
    return Intl.message(
      'A new version of Sidekick is available ($updateInfoLatest).',
      name: 'aNewVersionOfSidekickIsAvailableUpdateinfolatest',
      desc: '',
      args: [updateInfoLatest],
    );
  }

  /// `Language`
  String get language {
    return Intl.message(
      'Language',
      name: 'language',
      desc: '',
      args: [],
    );
  }

  /// `When a flutter command crashes it attempts to send a crash report to Google in order to help Google contribute improvements to Flutter over time`
  String get analyticsCrashReportSubtitle {
    return Intl.message(
      'When a flutter command crashes it attempts to send a crash report to Google in order to help Google contribute improvements to Flutter over time',
      name: 'analyticsCrashReportSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `A Flutter sdk version neeeds to be set as global in order to access Flutter settings`
  String get flutterSDKGlobalDescription {
    return Intl.message(
      'A Flutter sdk version neeeds to be set as global in order to access Flutter settings',
      name: 'flutterSDKGlobalDescription',
      desc: '',
      args: [],
    );
  }

  /// `The current tip-of-tree, absolute latest cutting edge build. Usually functional, though sometimes we accidentally break things.`
  String get theCurrentTipoftreeAbsoluteLatestCuttingEdgeBuildUsuallyFunctional {
    return Intl.message(
      'The current tip-of-tree, absolute latest cutting edge build. Usually functional, though sometimes we accidentally break things.',
      name: 'theCurrentTipoftreeAbsoluteLatestCuttingEdgeBuildUsuallyFunctional',
      desc: '',
      args: [],
    );
  }

  /// `Add your Flutter project Projects information will be displayed here.`
  String get addYourFlutterProjectProjectsInformationWillBeDisplayedHere {
    return Intl.message(
      'Add your Flutter project Projects information will be displayed here.',
      name: 'addYourFlutterProjectProjectsInformationWillBeDisplayedHere',
      desc: '',
      args: [],
    );
  }

  /// `You need to add a Flutter project first. Package information will be displayed here.`
  String get youNeedToAddAFlutterProjectFirstPackageInformation {
    return Intl.message(
      'You need to add a Flutter project first. Package information will be displayed here.',
      name: 'youNeedToAddAFlutterProjectFirstPackageInformation',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'de'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    if (locale != null) {
      for (var supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale.languageCode) {
          return true;
        }
      }
    }
    return false;
  }
}