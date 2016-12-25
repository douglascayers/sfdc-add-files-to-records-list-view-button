/**
 * Designed for the Lightning Component by similar name.
 * Also able to be used as Visualforce page controller to
 * collect the selected records from a list view.
 *
 * Provides methods to query for recently viewed or all Chatter Files
 * that he user has access to in paginated manner.
 *
 * Provides method to associate selected files with list of entity ids
 * by creating ContentDocumentLinks between them.
 */
public with sharing class ChatterAddFilesToRecordsController {

    // Constructor and properties are used by Visualforce pages
    // that serve as list view buttons.
    // ---------------------------------------------------------------

    public List<ID> recordIds { get; private set; }

    public ChatterAddFilesToRecordsController( ApexPages.StandardSetController stdController ) {

        this.recordIds = new List<ID>();

        for ( SObject obj : stdController.getSelected() ) {
            recordIds.add( obj.id );
        }

        if ( recordIds.size() == 0 ) {
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Please select one or more records.' ) );
        }

    }

    // The static @AuraEnabled methods and inner classes are used
    // by the Lightning Component to get and save data.
    // ---------------------------------------------------------------

    /**
     * Infers the sobject describe information from the record ids.
     * This allows us to display the object name on the page for context.
     *
     * Designed to be invoked from a Lightning Component via $A.enqueueAction
     */
    @AuraEnabled
    public static SObjectDescribeWrapper getSObjectDescribe( List<ID> recordIds ) {

        System.debug( 'getting sobject describe: ' + recordIds );

        if ( recordIds.size() > 0 ) {
            return new SObjectDescribeWrapper( recordIds[0].getSObjectType() );
        }

        return null;
    }

    /**
     * Creates ContentDocumentLinks between each record id and file id.
     */
    @AuraEnabled
    public static void attachFilesToRecords( List<ID> recordIds, List<ID> fileIds ) {

        try {

            // before creating the content document links
            // some files may already be linked to some records
            // so we need to look for any existing shares so
            // we don't try to insert duplicate shares and get error

            // key is record + file id
            // value is the content document link
            Map<String, ContentDocumentLink> existingFileSharesMap = new Map<String, ContentDocumentLink>();

            for ( ContentDocumentLink cdl : [
                SELECT
                    id, linkedEntityId, contentDocumentId
                FROM
                    ContentDocumentLink
                WHERE
                    linkedEntityId IN :recordIds
                    AND
                    contentDocumentId IN :fileIds
            ]) {
                existingFileSharesMap.put( cdl.linkedEntityId + '_' + cdl.contentDocumentId, cdl );
            }

            List<ContentDocumentLink> fileLinks = new List<ContentDocumentLink>();

            for ( ID recordId : recordIds ) {
                for ( ID fileId : fileIds ) {
                    if ( !existingFileSharesMap.containsKey( recordId + '_' + fileId ) ) {

                        System.debug( 'Creating new file share with record: recordId=' + recordId + ', contentDocumentId=' + fileId );

                        fileLinks.add( new ContentDocumentLink(
                            linkedEntityId = recordId,
                            contentDocumentId = fileId,
                            shareType = 'V'
                        ));

                    } else {

                        System.debug( 'File already shared with record: recordId=' + recordId + ', contentDocumentId=' + fileId );

                    }
                }
            }

            if ( fileLinks.size() > 0 ) {
                insert fileLinks;
            }

        } catch ( Exception e ) {

            // to have message shown to the user instead of swallowed
            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );
            throw new AuraHandledException( e.getMessage() );

        }

    }

    /**
     * Designed to be invoked from a Lightning Component via $A.enqueueAction
     */
    @AuraEnabled
    public static PaginatedContentDocumentWrapper getRecentlyViewedFiles( Integer page, Integer pageSize ) {

        try {

            // There is a bug with lightning components that Integer arguments
            // cannot be used as-is but must be re-parsed with Integer.valueOf.
            // http://michaelwelburn.com/2016/12/06/lightning-components-integers-script-thrown-exceptions/
            // http://salesforce.stackexchange.com/questions/108355/limit-expression-must-be-of-type-integer-error-when-using-apex-variable-in-soq/108423#108423
            page = Integer.valueOf ( page );
            pageSize = Integer.valueOf( pageSize );

            System.debug( 'getting recently viewed files: page=' + page + ', pageSize=' + pageSize );

            Integer skipRecords = ( page - 1 ) * pageSize;
            Integer maxRecords = pageSize + 1; // grab one more so can tell if there's a next page to get

            Map<ID, RecentlyViewed> recentlyViewedMap = new Map<ID, RecentlyViewed>([
                SELECT
                    id
                FROM
                    RecentlyViewed
                WHERE
                    type = 'ContentDocument'
            ]);

            List<ContentDocument> files = new List<ContentDocument>([
                SELECT
                    id, title, fileExtension, fileType, owner.name, lastModifiedDate
                FROM
                    ContentDocument
                WHERE
                    id IN :recentlyViewedMap.keySet()
                ORDER BY
                    lastModifiedDate DESC
                LIMIT
                    :maxRecords
                OFFSET
                    :skipRecords
            ]);

            PaginatedContentDocumentWrapper wrapper = buildWrapper( files, page, pageSize, ( skipRecords > 0 ), ( files.size() > pageSize ) );

            System.debug( 'recently viewed files: ' + wrapper );

            return wrapper;

        } catch ( Exception e ) {

            // to have message shown to the user instead of swallowed
            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );
            throw new AuraHandledException( e.getMessage() );

        }

    }

    /**
     * Designed to be invoked from a Lightning Component via $A.enqueueAction
     */
    @AuraEnabled
    public static PaginatedContentDocumentWrapper searchAllFiles( String searchTerm, Integer page, Integer pageSize ) {

        try {

            // There is a bug with lightning components that Integer arguments
            // cannot be used as-is but must be re-parsed with Integer.valueOf.
            // http://michaelwelburn.com/2016/12/06/lightning-components-integers-script-thrown-exceptions/
            // http://salesforce.stackexchange.com/questions/108355/limit-expression-must-be-of-type-integer-error-when-using-apex-variable-in-soq/108423#108423
            page = Integer.valueOf ( page );
            pageSize = Integer.valueOf( pageSize );

            System.debug( 'searching for files: searchTerm=' + searchTerm + ', page=' + page + ', pageSize=' + pageSize );

            Integer skipRecords = ( page - 1 ) * pageSize;
            Integer maxRecords = pageSize + 1; // grab one more so can tell if there's a next page to get

            List<ContentDocument> files = new List<ContentDocument>();

            if ( String.isNotBlank( searchTerm ) ) {

                List<List<SObject>> searchResults = new List<List<SObject>>([
                    FIND :searchTerm IN NAME FIELDS
                    RETURNING
                        ContentDocument (
                            id, title, fileExtension, fileType, owner.name, lastModifiedDate
                            ORDER BY
                                lastModifiedDate DESC
                            LIMIT
                                :maxRecords
                            OFFSET
                                :skipRecords
                        )
                ]);

                files = (List<ContentDocument>) searchResults[0];

            } else {

                files = new List<ContentDocument>([
                    SELECT
                        id, title, fileExtension, fileType, owner.name, lastModifiedDate
                    FROM
                        ContentDocument
                    ORDER BY
                        lastModifiedDate DESC
                    LIMIT
                        :maxRecords
                    OFFSET
                        :skipRecords
                ]);

            }

            PaginatedContentDocumentWrapper wrapper = buildWrapper( files, page, pageSize, ( skipRecords > 0 ), ( files.size() > pageSize ) );

            System.debug( 'searched files: ' + wrapper );

            return wrapper;

        } catch ( Exception e ) {

            // to have message shown to the user instead of swallowed
            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );
            throw new AuraHandledException( e.getMessage() );

        }

    }

    private static PaginatedContentDocumentWrapper buildWrapper( List<ContentDocument> files, Integer page, Integer pageSize, Boolean hasPrevious, Boolean hasNext ) {

        PaginatedContentDocumentWrapper wrapper = new PaginatedContentDocumentWrapper();
        wrapper.page = page;
        wrapper.pageSize = pageSize;
        wrapper.hasPrevious = hasPrevious;
        wrapper.hasNext = hasNext;

        // if number of records found exceeds requested page size
        // then there is a next page to get, otherwise this is last page
        if ( hasNext ) {

            // remove the last record so only return actual page size requested
            List<ContentDocument> filesToReturn = new List<ContentDocument>( files );
            filesToReturn.remove( filesToReturn.size() - 1 );

            wrapper.files = wrap( filesToReturn );

        } else {

            wrapper.files = wrap( files );

        }

        return wrapper;
    }

    private static List<ContentDocumentWrapper> wrap( List<ContentDocument> files ) {

        List<ContentDocumentWrapper> wrappers = new List<ContentDocumentWrapper>();

        for ( ContentDocument file : files ) {
            wrappers.add( new ContentDocumentWrapper( file ) );
        }

        return wrappers;
    }

    // -----------------------------------------------------

    public class SObjectDescribeWrapper {

        @AuraEnabled
        public String name { get; set; }

        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String labelPlural { get; set; }

        @AuraEnabled
        public String keyPrefix { get; set; }

        public SObjectDescribeWrapper( SObjectType sobjectType ) {

            DescribeSObjectResult describe = sobjectType.getDescribe();

            this.name = describe.getName();
            this.label = describe.getLabel();
            this.labelPlural = describe.getLabelPlural();
            this.keyPrefix = describe.getKeyPrefix();

        }

    }

    public class PaginatedContentDocumentWrapper {

        @AuraEnabled
        public Integer page { get; set; }

        @AuraEnabled
        public Integer pageSize { get; set; }

        @AuraEnabled
        public Boolean hasPrevious { get; set; }

        @AuraEnabled
        public Boolean hasNext { get; set; }

        @AuraEnabled
        public List<ContentDocumentWrapper> files { get; set; }

    }

    public class ContentDocumentWrapper {

        @AuraEnabled
        public ContentDocument file { get; set; }

        @AuraEnabled
        public Boolean selected { get; set; }

        public ContentDocumentWrapper( ContentDocument file ) {
            this( file, false );
        }

        public ContentDocumentWrapper( ContentDocument file, Boolean selected ) {
            this.file = file;
            this.selected = selected;
        }

    }

}