# --
# Kernel/Language/de_OTRSMultiServiceSelect.pm - translation file
# Copyright (C) 2003-2012 OTRS AG, http://otrs.com/
# --
# $Id: de_OTRSMultiServiceSelect.pm,v 1.2 2012/07/11 10:29:08 marb Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_OTRSMultiServiceSelect;

use strict;

sub Data {
    my $Self = shift;

    # SysConfig
    $Self->{Translation}->{'Defines if and up to which level a service must be selected.'} = 'Defiert ob und bis zu welchem Level ein Service ausgewählt werden muss.';
    $Self->{Translation}->{'Module to show multi-select-fields in the agent interface.'} = 'Modul zum Anzeigen von Multi-Select-Feldern im Agent-Interface.';
    $Self->{Translation}->{'Module to show multi-select-fields in the customer interface.'} = 'Modul zum Anzeigen von Multi-Select-Feldern im Customer-Interface.';
    $Self->{Translation}->{'Define list of custom JS files for the agent interface.'} = 'Definiert eine Liste von Javascript Dateien für das Agent-Interface.';
    $Self->{Translation}->{'Define list of custom JS files for the customer interface.'} = 'Definiert eine Liste von Javascript Dateien für das Customer-Interface.';
    $Self->{Translation}->{'This Option defines whether a javascript tree is used for the service selection.'} = 'Die Konfiguration legt fest, ob eine Javascript-Baumansicht für die Serviceauswahl genutzt wird.';
    $Self->{Translation}->{'This Option defines whether the javascript tree is expended.'} = 'Die Konfiguration legt fest, ob die Javascript-Baumansicht ausgeklappt wird.';
    $Self->{Translation}->{'Module to show a service tree view in the ticket search.'} = 'Modul zum Anzeigen eines Servicebaums in der Ticketsuche.';
    $Self->{Translation}->{'First level'} = 'Erste Ebene';
}

1;
