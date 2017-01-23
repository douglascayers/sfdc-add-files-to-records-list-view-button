({
    /**
     * Creates ContentDocumentLinks between each record id
     * and each selected file id then redirects back to
     * the sobject list view page.
     */
    attachFilesToRecords : function( component ) {

        var helper = this;

        var fileIds = [];
        var filesWrapper = component.get( 'v.filesWrapper' );

        for ( var i = 0; i < filesWrapper.files.length; i++ ) {
            var wrapper = filesWrapper.files[i];
            if ( wrapper.selected ) {
                fileIds.push( wrapper.file.Id );
            }
        }

        var recordIds = component.get( 'v.recordIds' );

        var postToChatter = component.get( 'v.postToChatter' );

        return helper.callAction( component, 'c.attachFilesToRecords', {

            'recordIds' : recordIds,
            'fileIds' : fileIds,
            'postToChatter' : postToChatter

        }).then( $A.getCallback( function( data ) {

            if ( component.isValid() ) {

                var keyPrefix = component.get( 'v.sobjectDescribe.keyPrefix' );

                helper.navigateToURL( '/' + keyPrefix );

            }

        })).catch( $A.getCallback( function( errors, state ) {

            helper.logActionErrors( component, errors );

            if ( component.isValid() ) {

                helper.showErrorMessagesModal( component, errors );

            }

        }));

    },

    /**
     * Determine basic sobject describe info based on
     * the record ids attribute so we can provide contextual
     * information about the object name, plural label,
     * and linking back to its list view page.
     */
    getSObjectDescribe : function( component ) {

        var helper = this;

        var recordIds = component.get( 'v.recordIds' );

        return helper.callAction( component, 'c.getSObjectDescribe', {

            'recordIds' : recordIds

        }).then( $A.getCallback( function( data ) {

            if ( component.isValid() ) {

                component.set( 'v.sobjectDescribe', data );

            }

        })).catch( $A.getCallback( function( errors, state ) {

            helper.logActionErrors( component, errors );

            if ( component.isValid() ) {

                helper.showErrorMessagesModal( component, errors );

            }

        }));

    },

    /**
     * Gets paginated list of recently viewed files for the current user.
     * Optionally takes in an array of document ids to pre-select.
     * The optional feature is generally just used after a user has uploaded
     * a new file from the ChatterAddFilesToRecordsPage visualforce page
     * and we're refreshing the list, and since the user just uploaded the file
     * I'm going to bet they want it to be one of the files to attach to the records.
     */
    showRecentlyViewedFiles : function( component, page, pageSize, documentIdsToSelect ) {

        var helper = this;

        // toggle active state of buttons
        component.find( 'recentlyViewedBtn' ).set( 'v.variant', 'brand' );
        component.find( 'sharedWithMeBtn' ).set( 'v.variant', 'neutral' );

        // clear search term, no longer relevant
        component.set( 'v.searchTerm', '' );

        return helper.callAction( component, 'c.getRecentlyViewedFiles', {

            'page' : page,
            'pageSize' : pageSize

        }).then( $A.getCallback( function( data ) {

            if ( component.isValid() ) {

                var selectedFilesCount = 0;

                // should we auto-select any documents?
                // the documentIdsToSelect argument is usually
                // set then user has just uploaded a chatter file
                if ( documentIdsToSelect ) {
                    for ( var i = 0; i < data.files.length; i++ ) {
                        var wrapper = data.files[i];
                        wrapper.selected = documentIdsToSelect.includes( wrapper.file.Id );
                        if ( wrapper.selected ) {
                            selectedFilesCount++;
                        }
                    }
                }

                helper.applyIconNames( component, data );

                component.set( 'v.filesWrapper', data );
                component.set( 'v.selectedFilesCount', selectedFilesCount );

            }

        })).catch( $A.getCallback( function( errors, state ) {

            helper.logActionErrors( component, errors );

            if ( component.isValid() ) {

                helper.showErrorMessagesModal( component, errors );

            }

        }));

    },

    /**
     * Gets a paginated list of all files the user has access to.
     * Optionally accepts a search parameter to narrow files down by title.
     */
    showSharedWithMeFiles : function( component, page, pageSize, searchTerm ) {

        var helper = this;

        // toggle active state of buttons
        component.find( 'recentlyViewedBtn' ).set( 'v.variant', 'neutral' );
        component.find( 'sharedWithMeBtn' ).set( 'v.variant', 'brand' );

        return helper.callAction( component, 'c.searchAllFiles', {

            'page' : page,
            'pageSize' : pageSize,
            'searchTerm' : searchTerm

        }).then( $A.getCallback( function( data ) {

            if ( component.isValid() ) {

                helper.applyIconNames( component, data );

                component.set( 'v.filesWrapper', data );
                component.set( 'v.selectedFilesCount', 0 );

            }

        })).catch( $A.getCallback( function( errors, state ) {

            helper.logActionErrors( component, errors );

            if ( component.isValid() ) {

                helper.showErrorMessagesModal( component, errors );

            }

        }));

    },

    applyIconNames : function( component, filesWrapper ) {

        for ( var i = 0; i < filesWrapper.files.length; i++ ) {

            var iconName = 'doctype:attachment';
            var fileWrapper = filesWrapper.files[i];

            if ( /^POWER_POINT/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:ppt';
            }
            else if ( /^EXCEL/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:excel';
            }
            else if ( /^WORD/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:word';
            }
            else if ( /^(MP3|WAV|M4A)/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:audio';
            }
            else if ( /^MP4/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:mp4';
            }
            else if ( /^CSV/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:csv';
            }
            else if ( /^TEXT/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:txt';
            }
            else if ( /^PDF/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:pdf';
            }
            else if ( /^XML/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:xml';
            }
            else if ( /^ZIP/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:zip';
            }
            else if ( /^(PNG|GIF|JPG|JPEG|TIFF|BMP)/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:image';
            }
            else if ( /^PACK/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:pack';
            }
            else if ( /^(MOV|WMV|M4V)/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:movie';
            }
            else if ( /^LINK/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:link';
            }
            else if ( /^HTML/i.test( fileWrapper.file.FileType ) ) {
                iconName = 'doctype:html';
            }

            fileWrapper.iconName = iconName;

        }

    },

    // ---------------------------------------------------------------------

    showErrorMessagesModal : function( component, errors ) {

        var errorMessages = [];

        // determine if errors is array of strings, exception objects, etc. to extract message
        if ( errors ) {
            if ( errors.length ) {
                for ( var i = 0; i < errors.length; i++ ) {
                    if ( errors[i].message ) {
                        errorMessages.push( JSON.stringify( errors[i].message ) );
                    } else {
                        errorMessages.push( JSON.stringify( errors[i] ) );
                    }
                }
            } else {
                errorMessages.push( JSON.stringify( errors ) );
            }
        } else {
            errorMessages.push( 'Unknown error. If problem continues, please contact your System Administrator.' );
        }

        component.set( 'v.errorMessages', errorMessages );

        $A.util.removeClass( component.find( 'errorMessagesModal' ), 'slds-hide' );

    },

    hideErrorMessagesModal : function( component ) {

        component.set( 'v.errorMessages', null );

        $A.util.addClass( component.find( 'errorMessagesModal' ), 'slds-hide' );

    },

    showSpinner : function( component ) {

        $A.util.removeClass( component.find( 'spinner' ), 'slds-hide' );

    },

    hideSpinner : function( component ) {

        $A.util.addClass( component.find( 'spinner' ), 'slds-hide' );

    },

    navigateToRecord : function( recordId ) {

        console.log( 'navigating to record: ' + recordId );

        var event = $A.get( 'e.force:navigateToSObject' );

        if ( event ) {

            event.setParams({
                'recordId' : recordId
            }).fire();

        } else if ( ( typeof sforce !== 'undefined' ) && ( typeof sforce.one !== 'undefined' ) ) {

            sforce.one.navigateToSObject( recordId );

        } else {

            window.location.href = '/' + recordId;

        }

    },

    navigateToURL : function( url ) {

        console.log( 'navigating to url: ' + url );

        var event = $A.get( 'e.force:navigateToURL' );

        if ( event ) {

            event.setParams({
                'url' : url
            }).fire();

        } else if ( ( typeof sforce !== 'undefined' ) && ( typeof sforce.one !== 'undefined' ) ) {

            sforce.one.navigateToURL( url );

        } else {

            window.location.href = url;

        }

    },

    callAction : function( component, actionName, params ) {

        var helper = this;

        var p = new Promise( function( resolve, reject ) {

            helper.showSpinner( component );

            var action = component.get( actionName );

            if ( params ) {
                action.setParams( params );
            }

            action.setCallback( helper, function( response ) {

                helper.hideSpinner( component );

                if ( component.isValid() && response.getState() === 'SUCCESS' ) {

                    resolve( response.getReturnValue() );

                } else {

                    console.error( 'Error calling action "' + actionName + '" with state: ' + response.getState() );

                    reject( response.getError(), response.getState() );

                }
            });

            $A.enqueueAction( action );

        });

        return p;
    },

    logActionErrors : function( component, errors ) {
        if ( errors ) {
            if ( errors.length > 0 ) {
                for ( var i = 0; i < errors.length; i++ ) {
                    console.error( 'Error: ' + errors[i].message );
                }
            } else {
                console.error( 'Error: ' + errors );
            }
        } else {
            console.error( 'Unknown error' );
        }
    }
})