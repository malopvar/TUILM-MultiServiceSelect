# --
# Kernel/Output/HTML/OTRSMultiServiceSelectCustomer.pm
# Copyright (C) 2003-2012 OTRS AG, http://otrs.com/
# --
# $Id: OTRSMultiServiceSelectCustomer.pm,v 1.7 2012/07/02 10:35:52 ub Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OTRSMultiServiceSelectCustomer;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.7 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw(ConfigObject LogObject MainObject LayoutObject)) {
        die "Got no $Needed!" if !$Self->{$Needed};
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check used template
    return 1 if !$Param{TemplateFile};
    my $TemplateName = $Param{TemplateFile};

    # get valid templates
    my $TemplateIsValid = $Self->{ConfigObject}->Get('Frontend::Output::FilterElementPost')
        ->{'OTRSMultiServiceSelectCustomer'}->{Templates};

    # check valid config
    return 1 if !$TemplateIsValid;
    return 1 if ref $TemplateIsValid ne 'HASH';

    # apply only if template is valid in config
    return 1 if !$TemplateIsValid->{$TemplateName};

    # define the minimum required service level
    # (internally the first level starts with 0, but for the admin this is level 1)
    my $RequiredLevel = $Self->{ConfigObject}->Get('OTRSMultiServiceSelect::RequiredLevel') || '';

    my $RequiredLastLevel = $Self->{ConfigObject}->Get('OTRSMultiServiceSelect::RequiredLastLevel') || 0;

    # translate the tooltip error message for the service dropdowns
    my $TranslatedErrorMessage
        = $Self->{LayoutObject}->{LanguageObject}->Get('This field is required.');

    # define pattern
    my $JSCode
        = "Core.OTRSMultiServiceSelect.ServiceRebuild.Init($RequiredLevel, '$TranslatedErrorMessage', $RequiredLastLevel);\r\n";
    my $Match = '( <!--dtl:js_on_document_complete--> )';
    my $Success = ${ $Param{Data} } =~ s{$Match}{ $1 $JSCode }xms;

    return 1;
}

1;
