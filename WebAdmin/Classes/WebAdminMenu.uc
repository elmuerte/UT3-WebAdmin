/**
 * Menu manager for the webadmin
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdminMenu extends Object;

struct MenuItem
{
	/**
	 * The absolute path (from the webapp path). Examples:
	 * foo
	 * foo/bar/quux
	 * bar
	 * bar/quux
	 * bar/quux2
	 */
	var string path;
	/**
	 * Title of the menu item
	 */
	var string title;
	/**
	 * A short description
	 */
	var string description;
	/**
	 * The weight of this item. A low number means it will be higher in the list.
	 */
	var int weight;
	/**
	 * The handler responsible for handling this menu item.
	 */
	var IQueryHandler handler;
};

var array<MenuItem> menu;

var WebAdmin webadmin;

struct TreeItem
{
	/**
	 * Index to the item in the menu list;
	 */
	var int cur;
	/**
	 * Path element
	 */
	var string elm;
	var array<int> children;
};

var array<TreeItem> tree;

/**
 * Add an item to the menu, or if the path already exist, update an existing
 * item.
 */
function addMenuItem(MenuItem item)
{
	local int idx;
	idx = menu.find('path', item.path);
	if (idx > -1)
	{
		menu[idx].title = item.title;
		menu[idx].description = item.description;
		menu[idx].weight = item.weight;
		menu[idx].handler = item.handler;
	}
	else {
		menu.addItem(item);
	}
}

/**
 * Add a new menu item (or overwrite the previous for the given path).
 */
function addMenu(string path, string title, IQueryHandler handler,
	optional string description = "", optional int weight = 0)
{
	local MenuItem item;
	item.path = path;
	item.title = title;
	item.description = description;
	item.weight = weight;
	item.handler = handler;
	addMenuItem(item);
}

/**
 * Get the menu handler for a given path
 */
function IQueryHandler getHandlerFor(string path)
{
	local int idx;
	idx = menu.find('path', path);
	if (idx > -1)
	{
		return menu[idx].handler;
	}
	return none;
}

/**
 * return the menu instance of the given user. All paths to which the user has
 * no access will be filtered from the list.
 *
 * @return none when the user has absolutely no access, otherwise an instance is
 *			returned that only contains the paths the user has access to.
 */
function WebAdminMenu getUserMenu(IWebAdminUser forUser)
{
	local WebAdminMenu result;
	local MenuItem entry;

	if (!forUser.canPerform(webadmin.getAuthURL("/")))
	{
		return none;
	}

	result = new(webadmin) class; // create a new instance this class
	result.webadmin = webadmin;
	foreach menu(entry)
	{
		if (forUser.canPerform(webadmin.getAuthURL(entry.path)))
		{
			result.addSortedItem(entry);
		}
	}
	result.createTree();
	return result;
}


/**
 * Add a menu item to the list sorting on the full path.
 */
protected function addSortedItem(MenuItem item)
{
	local MenuItem entry;
	local int idx;
	foreach menu(entry, idx)
	{
		if (entry.path > item.path)
		{
			menu.InsertItem(idx, item);
			return;
		}
	}
	menu.AddItem(item);
}

/**
 * Parses the sorted list of menu items and creates the tree.
 */
protected function createTree()
{
	local MenuItem entry;
	local int idx;

	local int i, idx2, parent, child;
	local array<string> parts;
	local bool found;

	tree.Length = 1;
	tree[0].cur = -1;

	foreach menu(entry, idx)
	{
		ParseStringIntoArray(entry.path, parts, "/", true);
		parent = 0;
		i = 0;

		// find the parent item
		while (i < parts.length-1)
		{
			found = false;
			foreach tree[parent].children(child)
			{
				if (tree[child].elm == parts[i])
				{
					i++;
					parent = child;
					found = true;
					break;
				}
			}
			if (!found)
			{
				// create a dummy item
				tree.Add(1);
				tree[tree.length-1].cur = -1;
				tree[tree.length-1].elm = parts[i];
				tree[parent].children.AddItem(tree.length-1);
				parent = tree.length-1;
				i++;
			}
		}

		// add the time
		found = false;
		foreach tree[parent].children(child, idx2)
		{
			if (menu[tree[child].cur].weight > entry.weight)
			{
				tree[parent].children.Insert(idx2, 1);
				tree[parent].children[idx2] = tree.length;
				tree.Add(1);
				tree[tree.length-1].cur = idx;
				tree[tree.length-1].elm = parts[parts.length-1];
				found = true;
				break;
			}
		}
		if (!found)
		{
			idx2 = tree[parent].children.length;
			tree[parent].children.add(1);
			tree[parent].children[idx2] = tree.length;
			tree.Add(1);
			tree[tree.length-1].cur = idx;
			tree[tree.length-1].elm = parts[parts.length-1];
		}
	}
}

/**
 * Render the current menu tree to a navigation menu
 */
function string render()
{
	local string result;
	local WebResponse wr;
	wr = new class'WebResponse';
	result = renderChilds(tree[0].children, wr);
	wr.subst("navigation.items", result);
	return wr.LoadParsedUHTM(webadmin.path$"/navigation_menu.inc");
}

protected function string renderChilds(array<int> childs, WebResponse wr)
{
	local int child, menuid;
	local string result, subitems;
	foreach childs(child)
	{
		menuid = tree[child].cur;
		if (menuid > -1)
		{
			if (tree[child].children.length > 0)
			{
				subitems = renderChilds(tree[child].children, wr);
				wr.subst("navigation.items", subitems, true);
				subitems = wr.LoadParsedUHTM(webadmin.path$"/navigation_menu.inc");
			}
			else {
				subitems = "";
			}
			wr.subst("item.submenu", subitems, true);
			wr.subst("item.path", webadmin.path$menu[menuid].path);
			wr.subst("item.title", menu[menuid].title);
			wr.subst("item.description", menu[menuid].description);
			result $= wr.LoadParsedUHTM(webadmin.path$"/navigation_item.inc");
		}
		else if (tree[child].children.length > 0)
		{
			result $= renderChilds(tree[child].children, wr);
		}
	}
	return result;
}
