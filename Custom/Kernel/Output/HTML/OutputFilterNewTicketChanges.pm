# --
# Kernel/Output/HTML/OutputFilterDashboardChanges.pm
# Copyright (C) 2013 Znuny GmbH, http://znuny.com/
# --

package Kernel::Output::HTML::OutputFilterDashboardChanges;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = \%Param;
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed objects (needed to be done here because of OTRS 3.0 + Survey package ->
    # public.pl?Action=PublicSurvey -> Got no DBObject! at)
    for (qw(DBObject EncodeObject TimeObject ConfigObject LogObject MainObject LayoutObject)) {
        return if !$Self->{$_};
    }

    # check needed stuff
    if ( !defined $Param{Data} ) {
        $Self->{LogObject}->Log( Priority => 'error', Message => 'Need Data!' );
        $Self->{LayoutObject}->FatalDie();
    }

    # return if it's not ticket zoom
    return if $Param{TemplateFile} !~ /^(AgentTicketPhone)/;

	# remove ShowTreeSelection
    # add js for hide ShowTreeSelection
    my $JSCode
        = "\$('.ShowTreeSelection').hide();";
		
	# inject the necessary JS into the template
    $Self->{LayoutObject}->AddJSOnDocumentComplete( Code => $JSCode );

    return $Param{Data};
}

1;
