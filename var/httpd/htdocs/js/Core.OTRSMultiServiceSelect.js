// --
// Core.OTRSMultiServiceSelect.js - provides functions for service substitutions
// Copyright (C) 2003-2012 OTRS AG, http://otrs.org/
// --
// $Id: Core.OTRSMultiServiceSelect.js,v 1.28 2012/06/30 17:08:40 ub Exp $
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.OTRSMultiServiceSelect = Core.OTRSMultiServiceSelect || {};

/**
 * @namespace
 * @exports TargetNS as Core.OTRSMultiServiceSelect
 * @description
 *      This namespace contains functions for all service substitutions.
 */
Core.OTRSMultiServiceSelect.ServiceRebuild = (function (TargetNS) {

    function BuildServicesArray() {

        var Services  = [],
            LevelJump = 0;

        $('#ServiceID option').each(function() {

            // get number of trailing spaces in service name to
            // distinguish the level (2 spaces = 1 level)
            var ServiceID       = $(this).attr('value'),
                ServiceDisabled = $(this).is(':disabled'),
                ServiceName     = $(this).text(),
                ServiceNameTrim = ServiceName.replace(/(^[\xA0]+)/g, ''),
                CurrentLevel    = (ServiceName.length - ServiceNameTrim.length) / 2,
                ChildOf = 0,
                ServiceIndex = 0,
                CurrentService;

            // skip entry if no ID (should only occur for the leading empty element, '-')
            // skip entry if Service is disabled (e. g. by ACL)
            if ( !ServiceID || ServiceDisabled ) {
                return true;
            }

            // determine wether this service is a child of a preceding service
            // therefore, take the last element we have added to our services
            // array and compare if to the current element
            if ( Services.length && CurrentLevel > 0 ) {

                // if the current level is too high in comparison to last stored level,
                // we detected a level jump and disable the multi select
                if ( CurrentLevel > parseInt(Services[Services.length - 1].Level + 1, 10) ) {
                    LevelJump = 1;
                    return true;
                }

                // if the current level is bigger than the last known level,
                // we're dealing with a child element of the last element
                if ( CurrentLevel > Services[Services.length - 1].Level ) {
                    ChildOf = Services[Services.length - 1].ID;
                }

                // if both levels equal eachother, we have a sibling and can
                // re-use the parent (= the ChildOf value) of the last element
                else if ( CurrentLevel === Services[Services.length - 1].Level ) {
                    ChildOf = Services[Services.length - 1].ChildOf;
                }

                // in other cases, we have an element of a lower level but not
                // of the first level, so we walk through all yet saved elements
                // (bottom up) and find the next element with a lower level
                else {
                    for ( ServiceIndex = Services.length; ServiceIndex >= 0; ServiceIndex-- ) {
                        if ( CurrentLevel > Services[ServiceIndex - 1].Level ) {
                            ChildOf = Services[ServiceIndex - 1].ID;
                            break;
                        }
                    }
                }
            }
            else if (!Services.length && CurrentLevel > 0) {

                // if no service has yet been stored and we detect a higher level than 0
                // for the first service to be stored we have the first service being
                // in-active. In this case, we disable the multi select
                LevelJump = 1;
                return true;
            }

            // collect data of current service and add it to services array
            CurrentService = {
                ID:       ServiceID,
                Name:     ServiceNameTrim,
                Level:    CurrentLevel,
                ChildOf:  ChildOf
            };
            Services.push(CurrentService);
        });

        // if a level has been jumped, we disable the multi select by
        // clearing the services array
        if (LevelJump) {
            Services = [];
        }

        return Services;
    }

    function BuildFreshMultiServiceSelect(Level, $InsertAfter, ChildOf, RequiredLevel, TranslatedErrorMessage, RequiredLastLevel) {

        var Services = BuildServicesArray(),
            OptionHTML = '',
            RequiredClass = '',
            ErrorToolTip = '';

        if ( typeof ChildOf === 'undefined' ) {
            ChildOf = 0;
        }

        if ( Services.length ) {

            // walk through services to find all services of the current requirements (child of/level)
            $.each(Services, function(Index, Data) {
                if ( ( Level === 0 && Data.Level === Level ) || ( Data.Level === Level && Data.ChildOf === ChildOf ) ) {
                    OptionHTML += '<option value="' + Data.ID +  '">' + Data.Name +  '</option>';
                }
            });

            if (OptionHTML) {
                OptionHTML = '<option>-</option>' + OptionHTML;

                // if required level is higher or the same as the current level
                // we add a required class for the validation module so that all levels up to the required level will be mandatory
                if (RequiredLastLevel || RequiredLevel >= Level) {
                    RequiredClass = 'Validate_Required';
                }

                // only if this error tooltip does not exist already
                if ( $('#ServiceIDMultiLevel_' + Level + 'Error').val() === undefined ) {

                    // define the tooltip error message
                    ErrorToolTip = '<div id="ServiceIDMultiLevel_' + Level + 'Error" class="TooltipErrorMessage ServiceIDMultiTooltipErrorMessage"><p>' + TranslatedErrorMessage + '</p></div>';
                }

                $('<select size="1" id="ServiceIDMultiLevel_' + Level + '" name="ServiceIDMultiLevel_' + Level + '" class="ServiceIDMulti ' + RequiredClass + '" style="margin-right:3px;" rel="Level_' + Level + '">' + OptionHTML + '</select>' + ErrorToolTip ).insertAfter($InsertAfter);
            }
        }
    }

    function BuildPreSelectedMultiServiceSelect(SelectedID, $InsertAfter, RequiredLevel, TranslatedErrorMessage, RequiredLastLevel) {

        var Services = BuildServicesArray(),
            OptionHTML = '',
            NeededLevel,
            NeededChildOf,
            ReplacementSelect,
            Parents,
            CurrentLevel,
            LevelToBeReplaced,
            RealLevel,
            RequiredClass = '',
            ErrorToolTip = '';

        if ( Services.length ) {

            // walk through services to find currently selected service
            $.each(Services, function(Index, Data) {
                if ( Data.ID === SelectedID ) {

                    // now that we have found the pre-selected service
                    // in the services array, we set some values to be
                    // able to find siblings and parents of the pre-selected
                    // service
                    NeededLevel   = Data.Level;
                    NeededChildOf = Data.ChildOf;
                }
            });

            // walk through services again to find siblings of selected service
            $.each(Services, function(Index, Data) {
                if ( Data.Level === NeededLevel && Data.ChildOf === NeededChildOf ) {
                    OptionHTML += '<option value="' + Data.ID +  '">' + Data.Name +  '</option>';
                }
            });

            if ( OptionHTML ) {

                OptionHTML = '<option>-</option>' + OptionHTML;

                // if required level is higher or the same as the current level
                // we add a required class for the validation module so that all levels up to the required level will be mandatory
                if (RequiredLastLevel || RequiredLevel >= NeededLevel) {
                    RequiredClass = 'Validate_Required';
                }

                // only if this error tooltip does not exist already
                if ( $('#ServiceIDMultiLevel_' + NeededLevel + 'Error').val() === undefined ) {

                    // define the tooltip error message
                    ErrorToolTip = '<div id="ServiceIDMultiLevel_' + NeededLevel + 'Error" class="TooltipErrorMessage ServiceIDMultiTooltipErrorMessage"><p>' + TranslatedErrorMessage + '</p></div>';
                }


//                ReplacementSelect = $('<select size<="1" id="ServiceIDMultiLevel_' + NeededLevel + '" name="ServiceIDMultiLevel_' + NeededLevel + '" class="ServiceIDMulti ' + RequiredClass + '" style="margin-right:3px;" rel="Level_' + NeededLevel + '">' + OptionHTML + '</select>' + ErrorToolTip);
                ReplacementSelect = $('<select size<="1" id="ServiceIDMultiLevel_' + NeededLevel + '" name="ServiceIDMultiLevel_' + NeededLevel + '" class="ServiceIDMulti ' + RequiredClass + '" style="margin-right:3px;" rel="Level_' + NeededLevel + '">' + OptionHTML + '</select>');

                // now build a fresh multiselect (last level of it will be replaced later)
                BuildFreshMultiServiceSelect(0, $('#ServiceID'), 0, RequiredLevel, TranslatedErrorMessage, RequiredLastLevel);

                // we now need to find all the parents to be able to pre-select them afterwards
                Parents = [];
                for ( CurrentLevel = NeededLevel - 1; CurrentLevel >= 0; CurrentLevel-- ) {

                    $.each(Services, function(Index, Data) {

                        if ( Data.Level === CurrentLevel && Data.ID === NeededChildOf ) {

                            // now that we have found a parent of a certain level, we push
                            // it to our parents array. This array will be reversed later and
                            // will give us a chain of parents by which we can walk through
                            // our fresh built service select
                            Parents.push(Data.ID);

                            // because we want to go up through the services tree, we now
                            // set the needed 'child of'-param to the value of the current found parent
                            NeededChildOf = Data.ChildOf;
                        }
                    });
                }

                // reverse the parents array for it must be walked from top to bottom for
                // building the selects we need
                Parents = Parents.reverse();

                // now walk through the found parents and select them in our fresh multiselect
                // by that, we fake-trigger all levels and complete our multiple select boxes
                $.each(Parents, function(Level, ID) {

                    $('.ServiceIDMulti[rel="Level_' + Level + '"]').val(ID);
                    BuildFreshMultiServiceSelect(Level + 1, $('.ServiceIDMulti[rel="Level_' + Level + '"]'), ID, RequiredLevel, TranslatedErrorMessage, RequiredLastLevel);
                });

                // now replace the level which has been pre-selected with our pre-build select
                LevelToBeReplaced = ReplacementSelect.attr('rel');
                $('.ServiceIDMulti[rel="' + LevelToBeReplaced + '"]').replaceWith(ReplacementSelect);

                // finally, select the right value in our selected select and build the following ones
                ReplacementSelect.val(SelectedID);
                RealLevel = parseInt(LevelToBeReplaced.replace(/Level_/, ''), 10);
                BuildFreshMultiServiceSelect(RealLevel + 1, ReplacementSelect, SelectedID, RequiredLevel, TranslatedErrorMessage, RequiredLastLevel);
            }
        }
    }

    /**
     * @function
     * @description
     *      This function initializes the service substitutions.
     *      If RequiredLevel is given, it will add the class Validate_Required to the service dropdown of the given level
     * @return nothing
     */
    TargetNS.Init = function (RequiredLevel, TranslatedErrorMessage, RequiredLastLevel) {
        if (RequiredLastLevel || RequiredLevel) {
            $('label[for="ServiceID"]').addClass('Mandatory');
            $('label[for="ServiceID"]').prepend('<span class="Marker">*</span>');
        }
        if ( $('#ServiceID').val() ) {

            // build preselected multiselect if ServiceID value is present
            BuildPreSelectedMultiServiceSelect($('#ServiceID').val(), $('#ServiceID'), RequiredLevel, TranslatedErrorMessage, RequiredLastLevel);
        }
        else {

            // else build fresh multiselect
            BuildFreshMultiServiceSelect(0, $('#ServiceID'), 0, RequiredLevel, TranslatedErrorMessage, RequiredLastLevel);
        }

        // hide old select if custom multi selects
        // are present. if not, something has gone wrong, we show a
        // notice in this case.
        if ( $('.ServiceIDMulti').length ) {
            $('#ServiceID').hide();
        }
        else {
            if ( $('#ServiceID option').length > 1 && !$('.ServiceIDMultiNotice').length ) {
                $('<span class="ServiceIDMultiNotice" style="color:#F28080;font-size:11px;" title="It seems that one or more level(s) have been disabled, so I switched back to the regular selection.">&nbsp;Sorry, there was a problem building the multi select (hover for more info).</span>').insertAfter('#ServiceID');
            }
        }

        // Handle AJAX form updates properly (currently only in the agent interface)
        if (Core.AJAX && Core.AJAX.FormUpdate) {

            // save original FormUpdate function
            Core.AJAX.OldFormUpdate = Core.AJAX.FormUpdate;

            // overwrite with a customized version
            Core.AJAX.FormUpdate = function ($EventElement, Subaction, ChangedElement, FieldsToUpdate, SuccessCallback) {
                var OldSuccessCallback = SuccessCallback;

                // If the fields to update include the ServiceID field, make sure that the
                //  multi service select is rebuilt afterwards.
                if ($.inArray('ServiceID', FieldsToUpdate) > -1) {
                    SuccessCallback = function () {

                        if ($.isFunction(OldSuccessCallback)) {
                            OldSuccessCallback();
                        }

                        // remove existing selects and their tooltip error messages
                        $('.ServiceIDMulti, .ServiceIDMultiTooltipErrorMessage').remove();

                        if ( $('#ServiceID').val() ) {

                            // build preselected multiselect again
                            BuildPreSelectedMultiServiceSelect($('#ServiceID').val(), $('#ServiceID'), RequiredLevel, TranslatedErrorMessage, RequiredLastLevel);
                        }
                        else {

                            // build fresh multiselect again
                            BuildFreshMultiServiceSelect(0, $('#ServiceID'), 0, RequiredLevel, TranslatedErrorMessage, RequiredLastLevel);
                        }

                        // hide old select if custom multi selects
                        // are present. if not, something has gone wrong, we show a
                        // notice in this case.
                        if ( $('.ServiceIDMulti').length ) {
                            $('#ServiceID').hide();
                        }
                        else {
                            if ( $('#ServiceID option').length > 1 && !$('.ServiceIDMultiNotice').length ) {
                                $('<span class="ServiceIDMultiNotice" style="color:#F28080;font-size:11px;" title="It seems that one or more level(s) have been disabled, so I switched back to the regular selection.">&nbsp;Sorry, there was a problem building the multi select (hover for more info).</span>').insertAfter('#ServiceID');
                            }
                        }
                    };
                }
                Core.AJAX.OldFormUpdate($EventElement, Subaction, ChangedElement, FieldsToUpdate, SuccessCallback);
            };
        }

        // bind change event to new selects to have them react properly on changes
        $('body').on('change', '.ServiceIDMulti', function() {

            var CurrentLevel = parseInt($(this).attr('rel').replace(/Level_/, ''), 10),
            NewServiceIDValue,
            FindNextUpperLevel;

            $('.ServiceIDMulti').each(function() {

                // if a box with a lower level has changed, be sure to remove the selects
                // with a higher level for they will be rebuild if necessary
                if ( parseInt($(this).attr('rel').replace(/Level_/, ''), 10) > CurrentLevel ) {

                    // remove the associated tooltip error message first
                    $( $(this).attr('id') + 'Error' ).remove();

                    // remove the select field
                    $(this).remove();
                }
            });

            // now build a new selectbox based on the current selected value
            BuildFreshMultiServiceSelect(CurrentLevel + 1, $(this), $(this).val(), RequiredLevel, TranslatedErrorMessage, RequiredLastLevel);

            // set the selected value to the hidden ServiceID select field
            if ($(this).val()) {

                NewServiceIDValue = $(this).val();

                // if the new selected value is empty, we take the selected value
                // from the next upper level (except for level 0, where we set
                // the ServiceID field to empty then)
                if ( $(this).val() === '-' ) {

                    FindNextUpperLevel = CurrentLevel - 1;

                    if ( FindNextUpperLevel < 0 ) {
                        NewServiceIDValue = '';
                    }
                    else {
                        NewServiceIDValue = $('.ServiceIDMulti[rel="Level_' + FindNextUpperLevel + '"]').val();
                    }
                }
                $('#ServiceID').val(NewServiceIDValue).change();
            }
        });

    };

    return TargetNS;
}(Core.OTRSMultiServiceSelect.ServiceRebuild || {}));
