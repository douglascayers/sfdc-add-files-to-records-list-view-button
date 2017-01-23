/**
 * Developed by Doug Ayers
 * github.com/douglascayers
 */
@isTest
private class ChatterAddFilesToRecordsControllerTest {

    @isTest
    static void test_get_recently_viewed_files() {

        ContentVersion cv = new ContentVersion(
            versionData = Blob.valueOf( 'Hello World' ),
            title = 'test',
            pathOnClient = 'test.txt'
        );

        insert cv;

        ContentDocument cd = [ SELECT id FROM ContentDocument WHERE latestPublishedVersionId = :cv.id FOR VIEW ];

        Account acct = new Account(
            name = 'Test'
        );

        insert acct;

        Test.startTest();

        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController([ SELECT id, name FROM Account ]);
        stdSetController.setSelected( stdSetController.getRecords() );

        ChatterAddFilesToRecordsController controller = new ChatterAddFilesToRecordsController( stdSetController );

        List<ID> recordIds = controller.recordIds;

        ChatterAddFilesToRecordsController.SObjectDescribeWrapper describeWrapper = ChatterAddFilesToRecordsController.getSObjectDescribe( recordIds );

        ChatterAddFilesToRecordsController.PaginatedContentDocumentWrapper filesWrapper = ChatterAddFilesToRecordsController.getRecentlyViewedFiles( 1, 10 );

        Test.stopTest();

        System.assertEquals( 1, recordIds.size() );

        System.assertEquals( Account.sObjectType.getDescribe().getName(), describeWrapper.name );
        System.assertEquals( Account.sObjectType.getDescribe().getLabel(), describeWrapper.label );
        System.assertEquals( Account.sObjectType.getDescribe().getLabelPlural(), describeWrapper.labelPlural );
        System.assertEquals( Account.sObjectType.getDescribe().getKeyPrefix(), describeWrapper.keyPrefix );

        System.assertEquals( 1, filesWrapper.files.size() );
        System.assertEquals( cd.id, filesWrapper.files[0].file.id );
        System.assertEquals( false, filesWrapper.files[0].selected );

    }

    @isTest
    static void test_get_shared_with_me_files() {

        ContentVersion cv1 = new ContentVersion(
            versionData = Blob.valueOf( 'Hello World' ),
            title = 'test',
            pathOnClient = 'test.txt'
        );

        insert cv1;

        ContentVersion cv2 = new ContentVersion(
            versionData = Blob.valueOf( 'Goodnight Moon' ),
            title = 'quiz',
            pathOnClient = 'quiz.txt'
        );

        insert cv2;

        ContentDocument cd1 = [ SELECT id, title FROM ContentDocument WHERE latestPublishedVersionId = :cv1.id FOR VIEW ];
        ContentDocument cd2 = [ SELECT id, title FROM ContentDocument WHERE latestPublishedVersionId = :cv2.id FOR VIEW ];

        Account acct = new Account(
            name = 'Test'
        );

        insert acct;

        // Note, our controller's SOSL for searching files queries on ContentDocument object
        // but specifying ContentDocument IDs as fixed search results will yield zero SOSL results.
        // If we specify the latest ContentVersion ID as the fixed search results then our SOSL
        // search for ContentDocument object will return expected results. Wha??
        Test.setFixedSearchResults( new List<ID>{ cv1.id } );

        Test.startTest();

        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController([ SELECT id, name FROM Account ]);
        stdSetController.setSelected( stdSetController.getRecords() );

        ChatterAddFilesToRecordsController controller = new ChatterAddFilesToRecordsController( stdSetController );

        ChatterAddFilesToRecordsController.PaginatedContentDocumentWrapper filesWrapper = ChatterAddFilesToRecordsController.searchAllFiles( null, 1, 1 );
        filesWrapper = ChatterAddFilesToRecordsController.searchAllFiles( 'test', 1, 1 );

        Test.stopTest();

        System.assertEquals( 1, filesWrapper.files.size() );
        System.assertEquals( cd1.id, filesWrapper.files[0].file.id );
        System.assertEquals( false, filesWrapper.files[0].selected );

    }

    @isTest
    static void test_attach_files_to_records() {

        ContentVersion cv = new ContentVersion(
            versionData = Blob.valueOf( 'Hello World' ),
            title = 'test',
            pathOnClient = 'test.txt'
        );

        insert cv;

        ContentDocument cd = [ SELECT id FROM ContentDocument WHERE latestPublishedVersionId = :cv.id FOR VIEW ];

        Account acct = new Account(
            name = 'Test'
        );

        insert acct;

        Test.startTest();

        List<ID> recordIds = new List<ID>{ acct.id };
        List<ID> fileIds = new List<ID>{ cd.id };
        Boolean postToChatter = true;

        ChatterAddFilesToRecordsController.attachFilesToRecords( recordIds, fileIds, postToChatter );

        Test.stopTest();

        List<ContentDocumentLink> cdls = [ SELECT linkedEntityId, contentDocumentId FROM ContentDocumentLink WHERE linkedEntityId = :acct.id ];

        System.assertEquals( 1, cdls.size() );
        System.assertEquals( cd.id, cdls[0].contentDocumentId );
        System.assertEquals( acct.id, cdls[0].linkedEntityId );
        System.assertEquals( 1, [ SELECT count() FROM FeedItem WHERE parentId = :acct.id ] );

    }

    @isTest
    static void test_attach_already_shared_files() {

        ContentVersion cv = new ContentVersion(
            versionData = Blob.valueOf( 'Hello World' ),
            title = 'test',
            pathOnClient = 'test.txt'
        );

        insert cv;

        ContentDocument cd = [ SELECT id FROM ContentDocument WHERE latestPublishedVersionId = :cv.id FOR VIEW ];

        Account acct = new Account(
            name = 'Test'
        );

        insert acct;

        ContentDocumentLink cdl = new ContentDocumentLink(
            linkedEntityId = acct.id,
            contentDocumentId = cd.id,
            shareType = 'V'
        );

        insert cdl;

        Test.startTest();

        List<ID> recordIds = new List<ID>{ acct.id };
        List<ID> fileIds = new List<ID>{ cd.id };
        Boolean postToChatter = false;

        ChatterAddFilesToRecordsController.attachFilesToRecords( recordIds, fileIds, postToChatter );

        Test.stopTest();

        // only the one link should come back since controller won't try to insert duplicate shares
        List<ContentDocumentLink> cdls = [ SELECT linkedEntityId, contentDocumentId FROM ContentDocumentLink WHERE linkedEntityId = :acct.id ];

        System.assertEquals( 1, cdls.size() );
        System.assertEquals( cd.id, cdls[0].contentDocumentId );
        System.assertEquals( acct.id, cdls[0].linkedEntityId );
        System.assertEquals( 0, [ SELECT count() FROM FeedItem WHERE parentId = :acct.id ] );

    }

    @isTest
    static void test_no_record_ids() {

        ContentVersion cv = new ContentVersion(
            versionData = Blob.valueOf( 'Hello World' ),
            title = 'test',
            pathOnClient = 'test.txt'
        );

        insert cv;

        ContentDocument cd = [ SELECT id FROM ContentDocument WHERE latestPublishedVersionId = :cv.id FOR VIEW ];

        Test.startTest();

        ChatterAddFilesToRecordsController controller = new ChatterAddFilesToRecordsController( new ApexPages.StandardSetController([ SELECT id, name FROM Account ]) );

        ChatterAddFilesToRecordsController.SObjectDescribeWrapper describeWrapper = ChatterAddFilesToRecordsController.getSObjectDescribe( controller.recordIds );

        Test.stopTest();

        System.assertEquals( 0, controller.recordIds.size() );
        System.assert( ApexPages.hasMessages( ApexPages.Severity.ERROR ) ); // for not having record ids
        System.assertEquals( null, describeWrapper ); // without record ids, nothing to describe

    }

}