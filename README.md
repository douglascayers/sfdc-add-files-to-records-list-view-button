Add Files to Records List View Button
=====================================

Overview
--------

The core of this package is a Lightning Component that lets users pick or upload Chatter Files to share to records selected from a List View. The power comes from this component being able to be launched from List View button thereby putting users in control of how to find one or more records to add one or more files to in a single operation.

This project is inspired by Christine Miller who [asked on Success Community](https://success.salesforce.com/_ui/core/chatter/groups/GroupProfilePage?g=0F93A0000004glD&fId=0D53A00002xJQTD) if such a feature or app existed.


Installation
------------

* [Deploy from Github](https://githubsfdeploy.herokuapp.com)


Getting Started
---------------

1. Deploy code using link above.
2. Assign **Chatter Add Files to Records Mass Action** permission set to your desired users.
3. For standard objects Account, Contact, Lead, Opportunity, or Case then add the provided **Attach Files** custom button to their [Search Layouts](https://help.salesforce.com/articleView?id=000182076&language=en_US&type=1). For any other object, see below FAQ how to add support for other standard and custom objects.
4. Navigate to a List View, select one or more records, then click the **Attach Files** button.
5. On the page that loads, choose one or more Chatter Files (or upload a new file) then click the **Attach Files** button in top-right corner.


FAQ
===

How do I add support for other standard or custom objects?
----------------------------------------------------------

Some Visualforce pages are included out-of-the-box so that List View buttons could be created for Accounts, Contacts, Leads, Opportunities, and Cases. It is also very easy to add support for other objects too by copying one of the existing pages.

1. Copy an existing Visualforce page, like [ChatterAddFilesToAccountsPage](https://github.com/DouglasCAyers/sfdc-add-files-to-records-list-view-button/blob/master/src/pages/ChatterAddFilesToAccountsPage.page), and name your new file something like ChatterAddFilesTo**YourObjects**Page.

2. In your new file, replace on line 1 **standardController="Account"** with **standardController="your_object_name"** then save the file. All the other code in the file should remain as-is.

3. Create a custom [List View button](https://developer.salesforce.com/docs/atlas.en-us.fundamentals.meta/fundamentals/adg_composite_app_create_custom_list_button_try_it_out.htm) that references your new page then add the button to the object's [Search Layout](https://help.salesforce.com/articleView?id=000182076&language=en_US&type=1).

4. Update the **Chatter Add Files to Records Mass Action** permission set to grant access to your new Visualforce page.
