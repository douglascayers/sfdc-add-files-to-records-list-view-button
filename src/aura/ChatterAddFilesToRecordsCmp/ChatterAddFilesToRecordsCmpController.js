({
	doInit : function( component, event, helper ) {

        var page = 1;
        var pageSize = component.get( 'v.pageSize' );

        helper.getSObjectDescribe( component );

        helper.showRecentlyViewedFiles( component, page, pageSize );

	},

    showRecentlyViewedFiles : function( component, event, helper ) {

        // reset page/pageSize to defaults

        var page = 1;
        var pageSize = component.get( 'v.pageSize' );

        helper.showRecentlyViewedFiles( component, page, pageSize );

    },

    showSharedWithMeFiles : function( component, event, helper ) {

        // reset page/pageSize to defaults

        var page = 1;
        var pageSize = component.get( 'v.pageSize' );
        var searchTerm = component.get( 'v.searchTerm' );

        helper.showSharedWithMeFiles( component, page, pageSize, searchTerm );

    },

    handlePreviousPageClick : function( component, event, helper ) {

        // are we showing recently viewed or all files?
        var showingRecentlyViewed = ( component.find( 'recentlyViewedBtn' ).get( 'v.variant' ) === 'brand' );

        var page = component.get( 'v.filesWrapper.page' ) - 1;
        var pageSize = component.get( 'v.filesWrapper.pageSize' );
        var searchTerm = component.get( 'v.searchTerm' );

        if ( showingRecentlyViewed ) {
            helper.showRecentlyViewedFiles( component, page, pageSize );
        } else {
            helper.showSharedWithMeFiles( component, page, pageSize, searchTerm );
        }

    },

    handleNextPageClick : function( component, event, helper ) {

        // are we showing recently viewed or all files?
        var showingRecentlyViewed = ( component.find( 'recentlyViewedBtn' ).get( 'v.variant' ) === 'brand' );

        var page = component.get( 'v.filesWrapper.page' ) + 1;
        var pageSize = component.get( 'v.filesWrapper.pageSize' );
        var searchTerm = component.get( 'v.searchTerm' );

        if ( showingRecentlyViewed ) {
            helper.showRecentlyViewedFiles( component, page, pageSize );
        } else {
            helper.showSharedWithMeFiles( component, page, pageSize, searchTerm );
        }

    },

    handleSearchTermKeyDown : function( component, event, helper ) {

        var ENTER_KEY = 13;

        if ( event.getParam( 'keyCode' ) === ENTER_KEY ) {

            var page = 1;
            var pageSize = component.get( 'v.pageSize' );
            var searchTerm = component.get( 'v.searchTerm' );

            helper.showSharedWithMeFiles( component, page, pageSize, searchTerm );

        }

    },

    handleChatterFileUploadedEvent : function( component, event, helper ) {

        var page = 1;
        var pageSize = component.get( 'v.pageSize' );
        var documentId = event.getParam( 'contentDocumentId' );

        helper.showRecentlyViewedFiles( component, page, pageSize, documentId );

    },

    handleShowAttachFilesModalClick : function( component, event, helper ) {

        $A.util.removeClass( component.find( 'attachFilesModal' ), 'slds-hide' );

    },

    handleCloseAttachFilesModalClick : function( component, event, helper ) {

        $A.util.addClass( component.find( 'attachFilesModal' ), 'slds-hide' );

    },

    handleAttachFilesClick : function( component, event, helper ) {

        helper.attachFilesToRecords( component );

    },

    handleCancelClick : function( component, event, helper ) {

        var keyPrefix = component.get( 'v.sobjectDescribe.keyPrefix' );

        helper.navigateToURL( '/' + keyPrefix );

    },

    handleCloseErrorMessagesModalClick : function( component, event, helper ) {

        helper.hideErrorMessagesModal( component );

    },

    incrementSelectedFilesCount : function( component, event, helper ) {

        var count = component.get( 'v.selectedFilesCount' );

        count++;

        component.set( 'v.selectedFilesCount', count );

    },

    decrementSelectedFilesCount : function( component, event, helper ) {

        var count = component.get( 'v.selectedFilesCount' );

        count--;

        component.set( 'v.selectedFilesCount', count );

    }

})