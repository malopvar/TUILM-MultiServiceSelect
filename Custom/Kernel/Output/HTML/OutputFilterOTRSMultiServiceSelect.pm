# --
# Kernel/Output/HTML/OutputFilterOTRSMultiServiceSelect.pm
# Copyright (C) 2003-2012 OTRS AG, http://otrs.com/
# --
# $Id: OutputFilterOTRSMultiServiceSelect.pm,v 1.4 2012/07/11 10:29:08 marb Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterOTRSMultiServiceSelect;

use strict;
use warnings;

use Kernel::System::SearchProfile;
use Kernel::System::Service;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.4 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw(ParamObject ConfigObject LogObject MainObject LayoutObject)) {
        die "Got no $Needed!" if !$Self->{$Needed};
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check used template
    return 1 if !$Param{TemplateFile};
    my $TemplateName = $Param{TemplateFile} || '';

    # list of frontend modules, to which the filter should be applied
    my $TemplateIsAffected
        = $Self->{ConfigObject}->Get('Frontend::Output::FilterElementPre')
        ->{'OTRSMultiServiceSelectTree'}->{Templates};

    # run the filter only on affected modules
    return 1 if !$TemplateIsAffected->{$TemplateName};

    # run the filter only if services are enabled
    return 1 if !$Self->{ConfigObject}->Get('Ticket::Service');

    # instance a new service object and get a list of available services
    $Self->{ServiceObject} = Kernel::System::Service->new( %{$Self} );
    my %ServiceList = $Self->{ServiceObject}->ServiceList(
        UserID => $Self->{UserID},
    );

    # instance a new search profile object and for the customer the current profile
    $Self->{SearchProfileObject} = Kernel::System::SearchProfile->new( %{$Self} );
    $Self->{Profile} = $Self->{ParamObject}->GetParam( Param => 'Profile' ) || '';

    # prepare the hash with delimiters for the search function
    for my $ServiceID ( keys %ServiceList ) {
        $ServiceList{$ServiceID} = $ServiceList{$ServiceID} . '::';
    }

    # detect whether the JSTree-View should be used (standard: No)
    my $UseJSTree = $Self->{ConfigObject}->Get('OTRSMultiServiceSelectTree::UseJSTree') || 'No';

    # expand the tree view (standard: First level)
    my $ExpandJSTree = $Self->{ConfigObject}->Get('OTRSMultiServiceSelectTree::ExpandJSTree')
        || 'No';
    my $ExpandFirstLevel = ( $ExpandJSTree eq '2' ) ? 'class="jstree-open"' : '';
    my $ExpandAll = ( $ExpandJSTree eq '1' ) ? 'jQuery("#JSTree").jstree("open_all");' : '';

    use Data::Dumper;
    open ERLOG, ">>/tmp/err.log";
    print ERLOG Dumper($ExpandJSTree);
    close ERLOG;

    # Load the right information for the different frontends
    if ( $TemplateName eq 'CustomerTicketSearch' ) {

        # Base for the SearchProfileData
        $Self->{SearchProfileTemplate} = 'CustomerTicketSearch';

        ${ $Param{Data} } .= <<'JS_TREE_BEGIN';
<!--dtl:js_on_document_complete-->
<script type="text/javascript">//<![CDATA[
    $.jstree._themes = "$Config{"Frontend::WebPath"}/js/thirdparty/jquery-jstree-1.0rc2/themes/";
    jQuery("#JSTree").jstree({
        "themes": {
            "theme": "default",
            "dots": true,
            "icons": true
        },
        "plugins" : [ "themes", "html_data", "checkbox", "sort", "ui" ]
    });
JS_TREE_BEGIN

        # append the javascript code to expand the whole tree
        ${ $Param{Data} } .= $ExpandAll;

        ${ $Param{Data} } .= <<'JS_TREE_END';
    jQuery('#CheckAllServices').unbind('click.CheckAll').bind('click.CheckAll', function () {
        jQuery(this).closest('ul').find('li > input:checkbox').prop('checked', jQuery(this).prop('checked'));
    });
//]]></script>
<!--dtl:js_on_document_complete-->
JS_TREE_END

    }
    else {

        # Base for the SearchProfileData
        $Self->{SearchProfileTemplate} = 'TicketSearch';

        # setup the javascript tree
        my $SearchJSCode .= <<"JS_SETUPTREE";
<div class="JSCode Hidden">
\$.jstree._themes = "\$Config{"Frontend::WebPath"}/js/thirdparty/jquery-jstree-1.0rc2/themes/";
jQuery("#JSTree").jstree({
    "themes": {
        "theme": "default",
        "dots": true,
        "icons": true
    },
    "plugins" : [ "themes", "html_data", "checkbox", "sort", "ui" ]
});
$ExpandAll
jQuery('#CheckAllServices').unbind('click.CheckAll').bind('click.CheckAll', function () {
    jQuery(this).closest('ul').find('li > input:checkbox').prop('checked', jQuery(this).prop('checked'));
});

</div>
JS_SETUPTREE

        if ( $UseJSTree ne 'No' ) {
            ${ $Param{Data} }
                =~ s{<label\sfor="ServiceIDs"\sid="LabelServiceIDs">}{<label for="ServiceIDs" id="LabelServiceIDs">$SearchJSCode}xmsg;
        }

    }

    # jQuery("#JSTree").jstree('open_all');
    # the html code for the javascript tree
    my $HTMLContent = '';

    # generate the tree of the current service list
    $Self->_ServiceTreeCreate(
        ServiceList => \%ServiceList,
        HTMLContent => \$HTMLContent,
    );

    # the search page is special, as it must allow multiple selection
    my $JSTreeHTML .= <<"END_HTML";

<!-- START INSERT B FROM OutputFilterOTRSMultiServiceSelect -->

<div id="JSTree">
    <ul>
        <li $ExpandFirstLevel><input type="checkbox" id="CheckAllServices" name="AllServices" value="0" /><label for="CheckAllServices">Alle</label>
            $HTMLContent
        </li>
    </ul>
</div>

<!-- END INSERT B FROM OutputFilterOTRSMultiServiceSelect -->

END_HTML

    if ( $UseJSTree ne 'No' ) {
        ${ $Param{Data} } =~ s{(\$Data\{"ServicesStrg"\})}{$JSTreeHTML}xmsg;
    }

    return 1;

}

sub _ServiceTreeCreate {
    my ( $Self, %Param ) = @_;

    # parameter validation
    return if !$Param{ServiceList};
    return if ref $Param{ServiceList} ne 'HASH';
    return if !%{ $Param{ServiceList} };
    return if !$Param{HTMLContent};
    return if ref $Param{HTMLContent} ne 'SCALAR';

    # get the data of the last search
    my %SearchProfileData = $Self->{SearchProfileObject}->SearchProfileGet(
        Base      => $Self->{SearchProfileTemplate},
        Name      => $Self->{Profile},
        UserLogin => $Self->{UserLogin},
    );

    # get all selected services from the last search
    my %ServiceIsSelected = map { $_ => 1 } @{ $SearchProfileData{ServiceIDs} };

    # process the services
    SERVICEID:
    for my $ServiceID (
        sort { $Param{ServiceList}->{$a} cmp $Param{ServiceList}->{$b} }
        keys %{ $Param{ServiceList} }
        )
    {

        # detect whether the current service was selected during the last search
        my $Checked = $ServiceIsSelected{$ServiceID} ? 'checked="checked"' : '';

        # next serviceid on undefined service ids
        next SERVICEID if !$Param{ServiceList}->{$ServiceID};

        # prepare the values
        my @ServiceParts = split '::', $Param{ServiceList}->{$ServiceID};

        # next serviceid on empty values
        next SERVICEID if !$ServiceParts[0];

        # subservice-entries (e.g. Service1::Service2::Service3...) wont be processed directly
        next if $ServiceParts[1];

        # search for possible subservices and process them if available
        my @PossibleSubServices
            = grep ( /^\Q$ServiceParts[0]\E::.+/, sort values %{ $Param{ServiceList} } );
        if (@PossibleSubServices) {

            # write the current level
            ${ $Param{HTMLContent} }
                .= '<ul><li><input id="ServiceID'
                . $ServiceID
                . '" type="checkbox" name="ServiceIDs" value="'
                . $ServiceID . '" '
                . $Checked . '/><label for="ServiceID' . $ServiceID . '">'
                . $ServiceParts[0] . '</label>';

            # process the sub-services
            my %SubServices;
            SUBSERVICEID:
            for my $SubServiceID ( sort keys %{ $Param{ServiceList} } ) {

                # next subserviceid on empty value
                next SUBSERVICEID if !$SubServiceID;

                # next subserviceid on empty id
                next SUBSERVICEID if !$Param{ServiceList}->{$SubServiceID};

                # split the sublevels
                my @SubServiceParts = split '::', $Param{ServiceList}->{$SubServiceID};

                # next subserviceid on empty subservice-parts
                next SUBSERVICEID if !@SubServiceParts;

                # next subserviceid if '$SubServiceParts[0]' and '$ServiceParts[0]' are different
                next SUBSERVICEID if $SubServiceParts[0] ne $ServiceParts[0];

                # delete the first entry (next level) and create the new hash
                shift @SubServiceParts;
                $SubServices{$SubServiceID} = join '::', @SubServiceParts;
                $SubServices{$SubServiceID} .= '::';
            }

            # write the next sub-level
            $Self->_ServiceTreeCreate(
                ServiceList => \%SubServices,
                HTMLContent => $Param{HTMLContent},
            );

        }
        else {

            # write the current level
            ${ $Param{HTMLContent} }
                .= '<ul><li><input id="ServiceID'
                . $ServiceID
                . '" type="checkbox" name="ServiceIDs" value="'
                . $ServiceID . '" '
                . $Checked . '/><label for="ServiceID' . $ServiceID . '">'
                . $ServiceParts[0] . '</label>';
        }

        # close the ul tag
        ${ $Param{HTMLContent} } .= '</li></ul>';
    }
}

1;
