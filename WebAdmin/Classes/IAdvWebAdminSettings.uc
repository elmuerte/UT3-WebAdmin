/**
 * Defines the interface for gametype/mutator configuration handlers that can
 * not be handled soly by a Settings subclass. By implemented
 * IAdvWebAdminSettings the developer has more freedom of configuration items.
 * However, using it does create a dependency on the WebAdmin package (an
 * optional server side only package).
 *
 * Implementers must be a subclass of Settings (or one of it's subclasses).
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface IAdvWebAdminSettings;


