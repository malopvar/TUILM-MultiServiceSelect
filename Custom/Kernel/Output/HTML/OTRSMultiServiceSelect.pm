# --
# Kernel/Output/HTML/OTRSMultiServiceSelect.pm
# Copyright (C) 2003-2012 OTRS AG, http://otrs.com/
# --
# $Id: OTRSMultiServiceSelect.pm,v 1.5 2012/07/01 09:04:40 ub Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OTRSMultiServiceSelect;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.5 $) [1];

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
        ->{'OTRSMultiServiceSelect'}->{Templates};

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
    $Self->{LayoutObject}->AddJSOnDocumentComplete( Code => $JSCode );

    return 1;
}

1;
