/**
 * This class provides the functionality to render a HTML page of a Settings
 * instance.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface IWebAdminSettings dependsOn(Settings);

/**
 * Called when the Settings instance is initialized for usage
 */
function waInit();

/**
 * Called when the "save settings" is issued from the webadmin. This should be
 * implemented to store the settings into thecorrect classes and issue their
 * StaticSaveConfig()
 */
function applySettings();
