/**
 * WebAdmin authentication interface. An implementation of this interface is
 * used to create IWebAdminUser instances.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface IWebAdminAuth;

/**
 * Initialize the authentication handler
 */
function init(WorldInfo worldinfo);

/**
 * Cleanup (prepare for being destroyed)
 */
function cleanup();

/**
 * Try to log in a user with the provided credentials
 *
 * @param username
 * @param password
 * @param errorMsg can be set to a friendly error message or reason why authentication failed
 * @return none when authentication failed, otherwise the created user instance
 */
function IWebAdminUser authenticate(string username, string password, out string errorMsg);

/**
 * Logout the given user. A user does not explicitly log out.
 *
 * @return true when the user was succesfully logged out.
 */
function bool logout(IWebAdminUser user);

/**
 * Like authenticate(...) except that the user is not explicitly logged in (or created).
 * This will be used to re-validate an already existing user. For example in the case a
 * time out was triggered and the user needs to re-enter his/her password.
 *
 * @param username
 * @param password
 * @param errorMsg can be set to a friendly error message or reason why authentication failed
 */
function bool validate(string username, string password, out string errorMsg);

/**
 * Validate the given user. This will be used to check if the IWebAdminUser is still valid,
 * for example to check if the user wasn't deleted in the mean while.
 *
 * @param user the user instance to validate
 * @param errorMsg can be set to a friendly error message or reason why authentication failed
 */
function bool validateUser(IWebAdminUser user, out string errorMsg);
