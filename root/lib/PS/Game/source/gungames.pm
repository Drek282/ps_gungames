#
#	This file is part of PsychoStats.
#
#	Written by Jason Morriss
#	Copyright 2008 Jason Morriss
#
#	PsychoStats is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	PsychoStats is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with PsychoStats.  If not, see <http://www.gnu.org/licenses/>.
#
#	$Id: gungames.pm 000 2023-07-01 $
#	
package PS::Game::source::gungames;

use strict;
use warnings;
use base qw( PS::Game::source::cstrikes );

our $VERSION = '1.00.' . (('$Rev: 000 $' =~ /(\d+)/)[0] || '000');


sub _init { 
	my $self = shift;
	$self->SUPER::_init;

	$self->{exclude_normal_kills} = $self->{conf}->get('exclude_normal_kills','gungame');
	if ($self->{exclude_normal_kills}) {
		$::ERR->info('GUNGAME: Normal kills will not count towards skill');
	}

	return $self;
}

sub mod_event_kill {
	my ($self, $p1, $p2, $w, $m) = @_;

	# We want to track who the level was gained on. We're also keeping the
	# last weapon too.
	$p1->{gg_last_victim} = $p2;
	$p1->{gg_last_weapon} = $w;
	
	# return 1 so 'skill' is not calculated for each normal kill
	return 1;
}

sub event_plrtrigger {
	my ($self, $timestamp, $args) = @_;
	my ($plrstr, $trigger, $propstr) = @$args;

	$trigger = lc $trigger;
	if (substr($trigger,0,3) eq 'gg_') {
		# capture gungame related events
		my $p1 = $self->get_plr($plrstr) || return;
		$self->_do_connected($timestamp, $p1) unless $p1->{_connected};
		return if $self->isbanned($p1);
	
		$p1->{basic}{lasttime} = $timestamp;
		return unless $self->minconnected;
		my $m = $self->get_map;
	
		$self->plrbonus($trigger, 'enactor', $p1);
		if ($trigger eq 'gg_levelup') {
			# levelup is triggered on a normal kill to gain a level	
			$p1->{mod_maps}{ $m->{mapid} }{lvlsgained}++;
			$p1->{mod}{lvlsgained}++;
			$m->{mod}{lvlsgained}++;
			my $p2 = $p1->{gg_last_victim};
			if ($p2) {
				# If a victim was saved the gg_last_victim var
				# won't point to a valid record anymore.
				my $w = $p1->{gg_last_weapon};
				if ($w) {
					$p1->{mod_weapons}{ $w->{weaponid} }{lvlsgained}++;
					$p2->{mod_weapons}{ $w->{weaponid} }{lvlsgiven}++;
				}
				$p2->{mod_maps}{ $m->{mapid} }{lvlsgiven}++;
				$p2->{mod}{lvlsgiven}++;
				$p1->{mod_victims}{ $p2->{plrid} }{lvlsgained}++;
				$p2->{mod_victims}{ $p1->{plrid} }{lvlsgiven}++;
				# calculate skill
				$self->calcskill_kill_func($p1, $p2, $w);
			}

		} elsif ($trigger eq 'gg_leveldown') {
			# leveldown is triggered on a steal or suicide
			$p1->{mod_maps}{ $m->{mapid} }{lvlslost}++;
			$p1->{mod}{lvlslost}++;
			$m->{mod}{lvlslost}++;

		} elsif ($trigger eq 'gg_knife_level') {
			# levelup is triggered on a normal kill to gain a level	
			$p1->{mod_maps}{ $m->{mapid} }{knifelvlsgained}++;
			$p1->{mod}{knifelvlsgained}++;
			$m->{mod}{knifelvlsgained}++;
			my $p2 = $p1->{gg_last_victim};
			if ($p2) {
				# If a victim was saved the gg_last_victim var
				# won't point to a valid record anymore.
				my $w = $p1->{gg_last_weapon};
				if ($w) {
					$p1->{mod_weapons}{ $w->{weaponid} }{knifelvlsgained}++;
					$p2->{mod_weapons}{ $w->{weaponid} }{knifelvlsgiven}++;
				}
				$p2->{mod_maps}{ $m->{mapid} }{knifelvlsgiven}++;
				$p2->{mod}{knifelvlsgiven}++;
				$p1->{mod_victims}{ $p2->{plrid} }{knifelvlsgained}++;
				$p2->{mod_victims}{ $p1->{plrid} }{knifelvlsgiven}++;
				# calculate skill
				$self->calcskill_kill_func($p1, $p2, $w);
			}
	
		} elsif ($trigger eq 'gg_leader') {
			# bonus points are given by the standard event capture
			$p1->{mod_maps}{ $m->{mapid} }{leader}++;
			$p1->{mod}{leader}++;
			$m->{mod}{leader}++;
	
		} elsif ($trigger eq 'gg_triple_level') {
			# bonus points are given by the standard event capture
			$p1->{mod_maps}{ $m->{mapid} }{triplelevel}++;
			$p1->{mod}{tiplelevel}++;
			$m->{mod}{triplelevel}++;
	
		} elsif ($trigger eq 'gg_last_level') {
			# bonus points are given by the standard event capture
			$p1->{mod_maps}{ $m->{mapid} }{lastlevel}++;
			$p1->{mod}{lastlevel}++;
			$m->{mod}{lastlevel}++;
	
		} elsif ($trigger eq 'gg_knife_steal') {
			# bonus points are given by the standard event capture
			$p1->{mod_maps}{ $m->{mapid} }{knifesteal}++;
			$p1->{mod}{knifesteal}++;
			$m->{mod}{knifesteal}++;
	
		} elsif ($trigger eq 'gg_win') {
			# keep stats for wins
			# bonus points are given by the standard event capture
			$p1->{mod_maps}{ $m->{mapid} }{winsgained}++;
			$p1->{mod}{winsgained}++;
			$m->{mod}{winsgained}++;
			my $p2 = $p1->{gg_last_victim};
			if ($p2) {
				$p2->{mod}{winsgiven}++;
				$p2->{mod_maps}{ $m->{mapid} }{winsgiven}++;
				$p1->{mod_victims}{ $p2->{plrid} }{winsgained}++;
				$p2->{mod_victims}{ $p1->{plrid} }{winsgiven}++;
			}
		
		# ignore the following triggers for now
		} elsif ($trigger eq 'headshot') {
		} elsif ($trigger eq 'gg_lose') {
		} elsif ($trigger eq 'gg_team_win') {
		} elsif ($trigger eq 'gg_team_lose') {
			
		} else {
			if ($self->{report_unknown}) {
				$self->warn("Unknown GUNGAME player trigger '$trigger' from src $self->{_src} line $self->{_line}: $self->{_event}");
			}
		}
	
	# ignore the following triggers for now
	} elsif ($trigger eq 'clantag') {
	} elsif ($trigger eq 'headshot') {
	} elsif ($trigger eq 'domination') {
	} elsif ($trigger eq 'revenge') {

	} else {
		# capture all other events not related directly to gungame
		$self->SUPER::event_plrtrigger($timestamp, $args);
	}
}

sub has_mod_tables { 1 }
sub has_roles { 0 }

1;
