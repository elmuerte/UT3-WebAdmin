/**
 * Defines the interface for gametype/mutator configuration handlers that can
 * not be handled soly by a Settings subclass. By implemented
 * IAdvWebAdminSettings the developer has more freedom of configuration items.
 * However, using it does create a dependency on the WebAdmin package (an
 * optional server side only package).
 *
 * IMPORTANT! The WebAdmin is an optional server-side only package. Do not
 * introduce a dependency on this package from a package that a client needs to
 * download in order to play your mod.
 *
 * Implementers must be a subclass of Settings (or one of it's subclasses).
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface IAdvWebAdminSettings;

/**
 * Called when the instance is created.
 */
function initSettings(WorldInfo worldinfo, DataStoreCache dscache);

/**
 * Called when the instance is queued to be cleanup. It should be used to unset
 * all actor references.
 */
function cleanup();

/**
 * Called when the settings should be saved. Return true when the settings were
 * saved. Use the webadmin reference to addMessage for feedback to the user about
 * incorrect values and what not.
 */
function bool saveSettings(WebRequest request, WebAdminMessages messages);

/**
 * Called to render the settings. This produce the HTML code for all settings
 * this implementation should expose. You can use the given SettingsRenderer to
 * perform standard rendering.
 */
function renderSettings(WebResponse response, SettingsRenderer renderer, optional string substName = "settings");
